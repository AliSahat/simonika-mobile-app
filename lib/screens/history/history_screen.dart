import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/api.dart';
import '../../models/pool_configuration.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.client});
  final Dio? client;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  bool _fetching = false;
  String? _error;
  String? _serial;
  bool _distance = false;
  int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  double? _number(dynamic value) {
    final result = value is num ? value.toDouble() : double.tryParse('$value');
    return result?.isFinite == true ? result : null;
  }

  DateTime? _time(Map<String, dynamic> item) =>
      DateTime.tryParse('${item['createdAt']}');
  String _device(Map<String, dynamic> item) =>
      '${item['serial'] ?? 'Perangkat tanpa serial'}';
  String _reading(dynamic value, String unit) => _number(value) == null
      ? '—'
      : '${_number(value)!.toStringAsFixed(_number(value)! % 1 == 0 ? 0 : 1)}$unit';

  Future<void> _fetchHistory() async {
    if (_fetching) return;
    setState(() {
      _fetching = true;
      _loading = _data.isEmpty;
      _error = null;
    });
    try {
      final token = (await SharedPreferences.getInstance()).getString('token');
      if (token == null) throw StateError('Sesi berakhir');
      final response = await (widget.client ??
              Dio(BaseOptions(
                  connectTimeout: const Duration(seconds: 15),
                  receiveTimeout: const Duration(seconds: 15))))
          .get('$baseUrl/api/water/level',
              options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (response.data['success'] != true)
        throw StateError('Data tidak tersedia');
      final entries = TelemetryLog.extractTelemetryList(response.data);
      entries.sort((a, b) => (_time(b)?.millisecondsSinceEpoch ?? 0)
          .compareTo(_time(a)?.millisecondsSinceEpoch ?? 0));
      if (mounted)
        setState(() {
          _data = entries;
          final devices = entries.map(_device).toSet();
          if (!devices.contains(_serial)) _serial = devices.firstOrNull;
        });
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Riwayat belum dapat diperbarui. Periksa koneksi dan coba lagi.');
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
          _fetching = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB), brightness: Brightness.dark);
    final devices = _data.map(_device).toSet().toList();
    final records =
        _data.where((item) => _device(item) == _serial).take(_limit).toList();
    final values = records
        .map((item) => _number(item['waterLevel']))
        .whereType<double>()
        .toList();
    final avg =
        values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        colorScheme: colors,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF060911),
        extendBody: true,
        body: Stack(
          children: [
            IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -30,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF59E0B).withOpacity(0.32),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 220,
                    left: -70,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2563EB).withOpacity(0.28),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: 60,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withOpacity(0.22),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    right: -30,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                      child: Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF06B6D4).withOpacity(0.26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF2563EB).withOpacity(0.20),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.30),
                                ),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                color: Color(0xFF3B82F6),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: const Text(
                                      'Riwayat air',
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF10B981),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF10B981)
                                                  .withOpacity(0.6),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Analitik & log pembacaan sensor',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: _fetching
                                    ? 'Memperbarui riwayat'
                                    : 'Perbarui riwayat',
                                onPressed: _fetching ? null : _fetchHistory,
                                icon: _fetching
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh_rounded,
                                        size: 19,
                                        color: Color(0xFFF8FAFC),
                                      ),
                              ),
                            ),
                          ]),
                          if (devices.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              key: ValueKey(_serial),
                              value: _serial,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF121826),
                              style: const TextStyle(color: Color(0xFFF8FAFC)),
                              decoration: InputDecoration(
                                labelText: 'Perangkat',
                                labelStyle:
                                    const TextStyle(color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(
                                  Icons.sensors_outlined,
                                  color: Color(0xFF3B82F6),
                                ),
                                filled: true,
                                fillColor:
                                    const Color(0xFF121826).withOpacity(0.70),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.09),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.09),
                                  ),
                                ),
                              ),
                              items: devices
                                  .map((device) => DropdownMenuItem(
                                      value: device,
                                      child: Text(
                                        device,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Color(0xFFF8FAFC)),
                                      )))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _serial = value),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        key: const PageStorageKey('history-list'),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          if (_loading)
                            SliverToBoxAdapter(
                              child: _state(
                                colors,
                                'Memuat riwayat…',
                                'Menyiapkan pembacaan sensor Anda.',
                                loading: true,
                              ),
                            )
                          else if (_data.isEmpty)
                            SliverToBoxAdapter(
                              child: _state(
                                colors,
                                _error == null
                                    ? 'Belum ada riwayat'
                                    : 'Riwayat belum tersedia',
                                _error ??
                                    'Pembacaan akan muncul setelah sensor mengirim data.',
                                retry: _error != null,
                              ),
                            )
                          else ...[
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_error != null) ...[
                                      Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: Color(0xFFF87171),
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    _glassBentoCard(
                                      isHero: true,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      const Color(0xFF10B981),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFF10B981)
                                                          .withOpacity(0.6),
                                                      blurRadius: 8,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Expanded(
                                                child: Text(
                                                  'Ringkasan pembacaan',
                                                  style: TextStyle(
                                                    color: Color(0xFFF8FAFC),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(
                                            color:
                                                Colors.white.withOpacity(0.06),
                                            height: 24,
                                          ),
                                          Wrap(
                                            spacing: 28,
                                            runSpacing: 16,
                                            children: [
                                              _summary(
                                                'Terbaru',
                                                records.isEmpty
                                                    ? '—'
                                                    : _reading(
                                                        records.first[
                                                            'waterLevel'],
                                                        '%',
                                                      ),
                                              ),
                                              _summary(
                                                'Rata-rata',
                                                avg == null
                                                    ? '—'
                                                    : '${avg.toStringAsFixed(1)}%',
                                              ),
                                              _summary(
                                                'Ditampilkan',
                                                '${records.length} data',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final count in [10, 30, 50])
                                          ChoiceChip(
                                            label: Text(
                                              '$count terbaru',
                                              style: TextStyle(
                                                color: _limit == count
                                                    ? const Color(0xFFF8FAFC)
                                                    : const Color(0xFF94A3B8),
                                                fontSize: 12,
                                                fontWeight: _limit == count
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                            ),
                                            selected: _limit == count,
                                            selectedColor:
                                                const Color(0xFF2563EB),
                                            backgroundColor:
                                                Colors.white.withOpacity(0.05),
                                            side: BorderSide(
                                              color: _limit == count
                                                  ? const Color(0xFF3B82F6)
                                                  : Colors.white
                                                      .withOpacity(0.09),
                                            ),
                                            shape: const StadiumBorder(),
                                            onSelected: (_) => setState(
                                                () => _limit = count),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _chart(records, colors),
                                    const SizedBox(height: 24),
                                    Semantics(
                                      header: true,
                                      child: const Text(
                                        'Catatan pengukuran',
                                        style: TextStyle(
                                          color: Color(0xFFF8FAFC),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Terbaru lebih dahulu • waktu lokal',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _record(records[index], colors),
                                  ),
                                  childCount: records.length,
                                ),
                              ),
                            ),
                          ],
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 96)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassBentoCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    bool isHero = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          if (isHero)
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.24),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isHero
                    ? [
                        const Color(0xFF1E40AF).withOpacity(0.72),
                        const Color(0xFF0E7490).withOpacity(0.62),
                        const Color(0xFF1E293B).withOpacity(0.78),
                      ]
                    : [
                        const Color(0xFF181F30).withOpacity(0.76),
                        const Color(0xFF101624).withOpacity(0.66),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isHero
                    ? const Color(0xFF60A5FA).withOpacity(0.28)
                    : Colors.white.withOpacity(0.09),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _summary(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ]);

  Widget _chart(List<Map<String, dynamic>> records, ColorScheme colors) {
    final valid = records
        .where((item) =>
            _time(item) != null &&
            _number(item[_distance ? 'distance' : 'waterLevel']) != null)
        .toList()
        .reversed
        .toList();
    final spots = valid
        .map((item) => FlSpot(
            _time(item)!.difference(_time(valid.first)!).inMilliseconds / 1000,
            _number(item[_distance ? 'distance' : 'waterLevel'])!))
        .toList();
    final unit = _distance ? ' cm' : '%';
    final highest = spots.isEmpty
        ? 100.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final lowest = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = _distance
        ? (highest <= 0 ? 10.0 : highest * 1.15)
        : highest > 100
            ? highest + 5
            : 100.0;
    return _glassBentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text(
          'Tren pembacaan',
          style: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(
            label: Text(
              'Level air',
              style: TextStyle(
                color: !_distance
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight:
                    !_distance ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: !_distance,
            selectedColor: const Color(0xFF2563EB),
            backgroundColor: Colors.white.withOpacity(0.05),
            side: BorderSide(
              color: !_distance
                  ? const Color(0xFF3B82F6)
                  : Colors.white.withOpacity(0.09),
            ),
            shape: const StadiumBorder(),
            onSelected: (_) => setState(() => _distance = false),
          ),
          ChoiceChip(
            label: Text(
              'Jarak sensor',
              style: TextStyle(
                color: _distance
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight:
                    _distance ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: _distance,
            selectedColor: const Color(0xFF2563EB),
            backgroundColor: Colors.white.withOpacity(0.05),
            side: BorderSide(
              color: _distance
                  ? const Color(0xFF3B82F6)
                  : Colors.white.withOpacity(0.09),
            ),
            shape: const StadiumBorder(),
            onSelected: (_) => setState(() => _distance = true),
          ),
        ]),
        const SizedBox(height: 16),
        if (spots.length < 2 || spots.last.x == spots.first.x)
          const Text(
            'Menunggu dua pembacaan dengan waktu berbeda.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              height: 1.5,
            ),
          )
        else
          Semantics(
            label:
                'Grafik ${_distance ? 'jarak sensor' : 'level air'} dengan ${spots.length} titik.',
            child: SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: spots.last.x,
                  minY: lowest < 0 ? lowest - 5 : 0,
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: spots.last.x,
                        getTitlesWidget: (value, meta) {
                          final date = _time(valid.first)!
                              .add(Duration(
                                  milliseconds: (value * 1000).round()))
                              .toLocal();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: const Color(0xFF3B82F6),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF2563EB).withOpacity(0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(spacing: 20, runSpacing: 8, children: [
          Text(
            'Min ${spots.isEmpty ? '—' : lowest.toStringAsFixed(1)}$unit',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'Max ${spots.isEmpty ? '—' : highest.toStringAsFixed(1)}$unit',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          _distance
              ? 'Jarak diukur dari sensor ke permukaan air.'
              : 'Level air ditampilkan dalam persen.',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ]),
    );
  }

  Widget _record(Map<String, dynamic> item, ColorScheme colors) {
    final date = _time(item)?.toLocal();
    final level = _number(item['waterLevel']);
    final status = level == null
        ? 'Belum ada data'
        : level >= 70
            ? 'Tinggi'
            : level >= 30
                ? 'Sedang'
                : 'Rendah';
    final statusColor = level == null
        ? const Color(0xFF94A3B8)
        : level >= 70
            ? const Color(0xFF34D399)
            : level >= 30
                ? const Color(0xFF3B82F6)
                : const Color(0xFFF59E0B);
    return _glassBentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          date == null
              ? 'Waktu tidak tersedia'
              : '${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            height: 1.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 20, runSpacing: 12, children: [
          Text(
            _reading(item['waterLevel'], '%'),
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'Jarak ${_reading(item['distance'], ' cm')}',
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 14,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          _device(item),
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ]),
    );
  }

  Widget _state(ColorScheme colors, String title, String description,
          {bool loading = false, bool retry = false}) =>
      Padding(
        padding: const EdgeInsets.all(24),
        child: _glassBentoCard(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            if (loading)
              const CircularProgressIndicator(color: Color(0xFF3B82F6))
            else
              Icon(
                retry ? Icons.cloud_off_outlined : Icons.history_rounded,
                size: 40,
                color: const Color(0xFF3B82F6),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (retry) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _fetchHistory,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: const Color(0xFFF8FAFC),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Coba lagi',
                  style: TextStyle(color: Color(0xFFF8FAFC)),
                ),
              ),
            ],
          ]),
        ),
      );
}
