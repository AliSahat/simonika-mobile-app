import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/api.dart';

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
      final entries = (response.data['data'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF0878DE),
        brightness: dark ? Brightness.dark : Brightness.light);
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
        data: Theme.of(context).copyWith(colorScheme: colors),
        child: Scaffold(
          backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
          body: SafeArea(
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
                                            color: colors.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        child: Icon(Icons.history_rounded,
                                            color: colors.onPrimaryContainer,
                                            size: 24)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Semantics(
                                            header: true,
                                            child: Text('Riwayat air',
                                                style: TextStyle(
                                                    color: colors.onSurface,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.5)))),
                                    IconButton(
                                        tooltip: _fetching
                                            ? 'Memperbarui riwayat'
                                            : 'Perbarui riwayat',
                                        onPressed:
                                            _fetching ? null : _fetchHistory,
                                        icon: _fetching
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: colors.primary))
                                            : Icon(Icons.refresh_rounded,
                                                color: colors.primary)),
                                  ]),
                                  if (devices.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      key: ValueKey(_serial),
                                      initialValue: _serial,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                          labelText: 'Perangkat',
                                          prefixIcon: Icon(
                                              Icons.sensors_outlined,
                                              color: colors.primary),
                                          filled: true,
                                          fillColor:
                                              colors.surfaceContainerLowest,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 12),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide(
                                                  color:
                                                      colors.outlineVariant))),
                                      items: devices
                                          .map((device) => DropdownMenuItem(
                                              value: device,
                                              child: Text(device,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis)))
                                          .toList(),
                                      onChanged: (value) =>
                                          setState(() => _serial = value),
                                    ),
                                  ],
                                ])),
                        Expanded(
                            child: CustomScrollView(
                                key: const PageStorageKey('history-list'),
                                slivers: [
                              if (_loading)
                                SliverToBoxAdapter(
                                    child: _state(colors, 'Memuat riwayat…',
                                        'Menyiapkan pembacaan sensor Anda.',
                                        loading: true))
                              else if (_data.isEmpty)
                                SliverToBoxAdapter(
                                    child: _state(
                                        colors,
                                        _error == null
                                            ? 'Belum ada riwayat'
                                            : 'Riwayat belum tersedia',
                                        _error ??
                                            'Pembacaan akan muncul setelah sensor mengirim data.',
                                        retry: _error != null))
                              else ...[
                                SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    sliver: SliverToBoxAdapter(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                          if (_error != null) ...[
                                            Text(_error!,
                                                style: TextStyle(
                                                    color: colors.error,
                                                    fontSize: 13,
                                                    height: 1.5)),
                                            const SizedBox(height: 12)
                                          ],
                                          Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                          colors: [
                                                        Color(0xFF168EED),
                                                        Color(0xFF154675)
                                                      ]),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          24)),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                        'Ringkasan pembacaan',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                    const SizedBox(height: 16),
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
                                                                      '%')),
                                                          _summary(
                                                              'Rata-rata',
                                                              avg == null
                                                                  ? '—'
                                                                  : '${avg.toStringAsFixed(1)}%'),
                                                          _summary(
                                                              'Ditampilkan',
                                                              '${records.length} data'),
                                                        ]),
                                                  ])),
                                          const SizedBox(height: 20),
                                          Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                for (final count in [
                                                  10,
                                                  30,
                                                  50
                                                ])
                                                  ChoiceChip(
                                                      label: Text(
                                                          '$count terbaru'),
                                                      selected: _limit == count,
                                                      onSelected: (_) =>
                                                          setState(() =>
                                                              _limit = count))
                                              ]),
                                          const SizedBox(height: 16),
                                          _chart(records, colors),
                                          const SizedBox(height: 24),
                                          Semantics(
                                              header: true,
                                              child: Text('Catatan pengukuran',
                                                  style: TextStyle(
                                                      color: colors.onSurface,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700))),
                                          const SizedBox(height: 6),
                                          Text(
                                              'Terbaru lebih dahulu • waktu lokal',
                                              style: TextStyle(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                  fontSize: 12)),
                                          const SizedBox(height: 16),
                                        ]))),
                                SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    sliver: SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                            (context, index) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: _record(
                                                    records[index], colors)),
                                            childCount: records.length))),
                              ],
                              const SliverToBoxAdapter(
                                  child: SizedBox(height: 24)),
                            ])),
                      ])))),
        ));
  }

  Widget _summary(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Color(0xFFE4F2FF), fontSize: 12))
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
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Tren pembacaan',
              style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
                label: const Text('Level air'),
                selected: !_distance,
                onSelected: (_) => setState(() => _distance = false)),
            ChoiceChip(
                label: const Text('Jarak sensor'),
                selected: _distance,
                onSelected: (_) => setState(() => _distance = true))
          ]),
          const SizedBox(height: 16),
          if (spots.length < 2 || spots.last.x == spots.first.x)
            Text('Menunggu dua pembacaan dengan waktu berbeda.',
                style: TextStyle(
                    color: colors.onSurfaceVariant, fontSize: 14, height: 1.5))
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
                                  color: colors.outlineVariant,
                                  strokeWidth: 1,
                                  dashArray: [4, 4])),
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
                                              milliseconds:
                                                  (value * 1000).round()))
                                          .toLocal();
                                      return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                  fontSize: 10)));
                                    })),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                                spots: spots,
                                isCurved: false,
                                color: colors.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                    show: true,
                                    color:
                                        colors.primary.withValues(alpha: 0.10)))
                          ],
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 200)))),
          const SizedBox(height: 12),
          Wrap(spacing: 20, runSpacing: 8, children: [
            Text('Min ${spots.isEmpty ? '—' : lowest.toStringAsFixed(1)}$unit',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
            Text('Max ${spots.isEmpty ? '—' : highest.toStringAsFixed(1)}$unit',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12))
          ]),
          const SizedBox(height: 8),
          Text(
              _distance
                  ? 'Jarak diukur dari sensor ke permukaan air.'
                  : 'Level air ditampilkan dalam persen.',
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 12, height: 1.5)),
        ]));
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
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.7))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
              date == null
                  ? 'Waktu tidak tersedia'
                  : '${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}',
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          Wrap(spacing: 20, runSpacing: 12, children: [
            Text(_reading(item['waterLevel'], '%'),
                style: TextStyle(
                    color: colors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            Text('Jarak ${_reading(item['distance'], ' cm')}',
                style: TextStyle(color: colors.onSurface, fontSize: 14)),
            Text(status,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text(_device(item),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
        ]));
  }

  Widget _state(ColorScheme colors, String title, String description,
          {bool loading = false, bool retry = false}) =>
      Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            if (loading)
              CircularProgressIndicator(color: colors.primary)
            else
              Icon(retry ? Icons.cloud_off_outlined : Icons.history_rounded,
                  size: 40, color: colors.primary),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.onSurfaceVariant, fontSize: 14, height: 1.5)),
            if (retry) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                  onPressed: _fetchHistory, child: const Text('Coba lagi'))
            ],
          ]));
}
