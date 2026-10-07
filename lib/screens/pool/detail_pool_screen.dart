import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';
import 'widgets/animated_water_tank.dart';

class DetailPoolScreen extends StatefulWidget {
  const DetailPoolScreen({super.key, this.client});
  final Dio? client;

  @override
  State<DetailPoolScreen> createState() => _DetailPoolScreenState();
}

class _DetailPoolScreenState extends State<DetailPoolScreen> {
  Map<String, dynamic>? poolData;
  Map<String, dynamic>? latestWaterData;
  bool isLoading = true;
  bool isLoadingWater = true;
  bool _fetchingWater = false;
  bool _started = false;
  final List<({DateTime time, double level})> _samples = [];
  String? _lastReadingKey;
  String? _poolId;
  String? _detailError;
  String? _waterError;
  Timer? _pollingTimer;
  late final Dio _dio = widget.client ??
      Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10)));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is! String || argument.isEmpty) {
      isLoading = false;
      isLoadingWater = false;
      _detailError = 'ID wadah tidak ditemukan.';
      return;
    }
    _poolId = argument;
    _fetchDetail();
    _fetchWater();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) _fetchWater();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<Options> _authOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw StateError('Sesi berakhir');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> _fetchDetail() async {
    if (_poolId == null) return;
    setState(() {
      isLoading = true;
      _detailError = null;
    });
    try {
      final response = await _dio.get('$baseUrl/api/pool/$_poolId',
          options: await _authOptions());
      if (response.data['success'] != true)
        throw StateError('Data tidak tersedia');
      if (mounted)
        setState(
            () => poolData = Map<String, dynamic>.from(response.data['data']));
    } catch (_) {
      if (mounted)
        setState(() => _detailError =
            'Detail wadah belum dapat dimuat. Periksa koneksi dan coba lagi.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchWater() async {
    if (_fetchingWater || _poolId == null) return;
    _fetchingWater = true;
    if (mounted) setState(() => isLoadingWater = true);
    try {
      final response = await _dio.get('$baseUrl/api/water/level',
          queryParameters: {'poolId': _poolId, 'limit': 30},
          options: await _authOptions());
      if (response.data['success'] != true)
        throw StateError('Data tidak tersedia');
      final items = response.data['data'] as List;
      if (mounted)
        setState(() {
          latestWaterData =
              items.isEmpty ? null : Map<String, dynamic>.from(items.first);
          _waterError = null;
          final level = _level;
          final time = DateTime.tryParse('${latestWaterData?['createdAt']}');
          final key = latestWaterData == null
              ? null
              : '${latestWaterData?['_id'] ?? ''}|${latestWaterData?['createdAt'] ?? ''}|${latestWaterData?['waterLevel']}';
          if (level != null &&
              level.isFinite &&
              time != null &&
              key != _lastReadingKey) {
            if (_samples.isEmpty || time.isAfter(_samples.last.time)) {
              _samples.add((time: time, level: level));
              if (_samples.length > 30) _samples.removeAt(0);
            }
            _lastReadingKey = key;
          }
        });
    } catch (_) {
      if (mounted)
        setState(() =>
            _waterError = 'Pembaruan gagal. Periksa koneksi lalu coba lagi.');
    } finally {
      _fetchingWater = false;
      if (mounted) setState(() => isLoadingWater = false);
    }
  }

  double? _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value');
  double? get _levelCm => _number(latestWaterData?['waterLevel']);
  double? get _level {
    final depth = _number(poolData?['kedalaman']);
    if (_levelCm == null || depth == null || depth <= 0) return null;
    return ((_levelCm! / depth) * 100).clamp(0, 100);
  }
  String _value(dynamic value, String unit) =>
      value == null ? '—' : '$value $unit';
  String get _levelStatus => _level == null
      ? 'Belum ada data'
      : _level! >= 70
          ? 'Tinggi'
          : _level! >= 30
              ? 'Sedang'
              : 'Rendah';
  String get _valveStatus {
    final value = latestWaterData?['fillValveOpen'];
    if (value is! bool) return 'Belum ada data';
    return value ? 'Terbuka' : 'Tertutup';
  }

  String get _dischargeStatus {
    final value = latestWaterData?['drainValveOpen'];
    if (value is! bool) return 'Belum ada data';
    return value ? 'Aktif' : 'Tertutup';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF0878DE),
        brightness: dark ? Brightness.dark : Brightness.light);
    final timestamp =
        DateTime.tryParse('${latestWaterData?['createdAt']}')?.toLocal();
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colors),
      child: Scaffold(
        backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
        appBar: AppBar(
          title: const Text('Monitoring wadah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
          foregroundColor: colors.onSurface,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
                tooltip: 'Perbarui monitoring',
                onPressed: isLoadingWater
                    ? null
                    : () {
                        if (poolData == null) _fetchDetail();
                        _fetchWater();
                      },
                icon: const Icon(Icons.refresh_rounded))
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : poolData == null
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.cloud_off_outlined,
                              size: 40, color: colors.primary),
                          const SizedBox(height: 16),
                          Text(_detailError ?? 'Detail wadah tidak tersedia.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 16)),
                          if (_poolId != null) ...[
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                                onPressed: _fetchDetail,
                                child: const Text('Coba lagi'))
                          ],
                        ])))
                : Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                          children: [
                            Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Icon(Icons.water_drop_outlined,
                                      color: colors.onPrimaryContainer)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        '${poolData!['namaWadah'] ?? 'Wadah air'}',
                                        style: TextStyle(
                                            color: colors.onSurface,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Serial: ${poolData!['serial'] ?? '—'}',
                                        style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 12)),
                                  ])),
                            ]),
                            const SizedBox(height: 12),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              _badge(
                                  poolData!['isActive'] == true
                                      ? 'Wadah aktif'
                                      : 'Wadah nonaktif',
                                  Icons.check_circle_outline_rounded,
                                  colors),
                              _badge('Pembaruan setiap 5 detik',
                                  Icons.sync_rounded, colors),
                            ]),
                            const SizedBox(height: 20),
                            _card(
                                colors,
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                            child: Text('Level air',
                                                style: TextStyle(
                                                    color: colors.onSurface,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w700))),
                                        if (isLoadingWater)
                                          SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: colors.primary)),
                                      ]),
                                      const SizedBox(height: 8),
                                      Text(
                                          _waterError != null
                                              ? 'Data terakhir • pembaruan gagal'
                                              : _level == null
                                                  ? 'Menunggu pembacaan sensor'
                                                  : 'Pembacaan sensor terbaru',
                                          style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 12)),
                                      const SizedBox(height: 20),
                                      AnimatedWaterTank(
                                        level: _level,
                                        colors: colors,
                                        inletActive: _waterError == null &&
                                            _valveStatus == 'Terbuka',
                                        outletActive: _waterError == null &&
                                            _dischargeStatus == 'Aktif',
                                        thresholds: _tankThresholds,
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 12,
                                          runSpacing: 8,
                                          children: [
                                            _flowLabel(
                                                'Masuk',
                                                _waterError == null &&
                                                    _valveStatus == 'Terbuka',
                                                colors),
                                            _flowLabel(
                                                'Keluar',
                                                _waterError == null &&
                                                    _dischargeStatus == 'Aktif',
                                                colors),
                                          ]),
                                      const SizedBox(height: 16),
                                      Text(
                                          _level == null
                                              ? '—'
                                              : '${_level!.toStringAsFixed(_level! % 1 == 0 ? 0 : 1)}%',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: colors.primary,
                                              fontSize: 44,
                                              height: 1.1,
                                              letterSpacing: -1.5,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 8),
                                      Center(
                                          child: _badge(_levelStatus,
                                              Icons.waves_outlined, colors)),
                                      const SizedBox(height: 20),
                                      _metric(
                                          'Tinggi air',
                                          _value(_levelCm?.toStringAsFixed(1), 'cm'),
                                          colors),
                                      const SizedBox(height: 10),
                                      _metric(
                                          'Jarak sensor ke air',
                                          _value(latestWaterData?['distance'], 'cm'),
                                          colors),
                                      if (_waterError != null) ...[
                                        const SizedBox(height: 12),
                                        Text(_waterError!,
                                            style: TextStyle(
                                                color: colors.error,
                                                fontSize: 13,
                                                height: 1.5))
                                      ],
                                      if (timestamp != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                            'Diperbarui ${timestamp.toString().split('.').first}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: colors.onSurfaceVariant,
                                                fontSize: 12,
                                                height: 1.5))
                                      ],
                                    ])),
                            const SizedBox(height: 16),
                            _trendCard(colors),
                            const SizedBox(height: 16),
                            _card(
                                colors,
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Status otomatis',
                                          style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Indikator mengikuti pembacaan sensor dan ambang wadah.',
                                          style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 13,
                                              height: 1.5)),
                                      const SizedBox(height: 16),
                                      _metric('Keran', _valveStatus, colors,
                                          icon: Icons.water_drop_outlined),
                                      const SizedBox(height: 12),
                                      _metric('Pembuangan', _dischargeStatus,
                                          colors,
                                          icon: Icons.water_damage_outlined),
                                      const SizedBox(height: 12),
                                      Text(
                                          'Pembuangan: tutup ≤ ${poolData!['pembuanganBatasTutup'] ?? 20}%, aktif > ${poolData!['pembuanganBatasBuka'] ?? 80}%.',
                                          style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 12,
                                              height: 1.5)),
                                    ])),
                            const SizedBox(height: 16),
                            _card(
                                colors,
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Pengaturan wadah',
                                          style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 16),
                                      for (final setting in [
                                        ('Kedalaman', 'kedalaman'),
                                        ('Keran tutup', 'keranTutup'),
                                        ('Keran normal', 'keranNormal'),
                                        ('Keran buka', 'keranBuka')
                                      ]) ...[
                                        _metric(
                                            setting.$1,
                                            _value(poolData![setting.$2], 'cm'),
                                            colors),
                                        const SizedBox(height: 10),
                                      ],
                                    ])),
                          ],
                        ))),
      ),
    );
  }

  Map<String, double> get _tankThresholds {
    final depth = _number(poolData?['kedalaman']);
    if (depth == null || depth <= 0) return {};
    return {
      for (final entry in [
        ('Tutup', 'keranTutup'),
        ('Normal', 'keranNormal'),
        ('Buka', 'keranBuka')
      ])
        if (_number(poolData?[entry.$2]) != null)
          entry.$1: ((depth - _number(poolData?[entry.$2])!) / depth * 100)
              .clamp(0.0, 100.0),
    };
  }

  Widget _flowLabel(String label, bool active, ColorScheme colors) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(active ? Icons.arrow_forward_rounded : Icons.pause_rounded,
            size: 16, color: active ? colors.primary : colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
            child: Text(
                '$label: ${active ? 'terindikasi aktif' : 'tidak aktif'}',
                style:
                    TextStyle(color: colors.onSurfaceVariant, fontSize: 11))),
      ]);

  Widget _trendCard(ColorScheme colors) {
    final min = _samples.isEmpty
        ? null
        : _samples.map((s) => s.level).reduce((a, b) => a < b ? a : b);
    final max = _samples.isEmpty
        ? null
        : _samples.map((s) => s.level).reduce((a, b) => a > b ? a : b);
    final difference =
        _samples.length < 2 ? null : _samples.last.level - _samples.first.level;
    return _card(
        colors,
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Tren level air',
              style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Pembacaan baru selama layar ini dibuka • maksimal 30 titik',
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 12, height: 1.5)),
          const SizedBox(height: 20),
          if (_samples.length < 2)
            Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(
                    'Menunggu dua pembacaan sensor dengan waktu yang berbeda untuk menampilkan tren.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.5)))
          else
            Semantics(
                label:
                    'Tren ${_samples.length} pembacaan. Minimum $min persen, maksimum $max persen.',
                child: SizedBox(
                    height: 170,
                    child: LineChart(LineChartData(
                      minY: 0,
                      maxY: _samples.any((s) => s.level > 100) ? max! + 5 : 100,
                      minX: 0,
                      maxX: _samples.last.time
                              .difference(_samples.first.time)
                              .inMilliseconds /
                          1000,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (_) => FlLine(
                              color: colors.outlineVariant,
                              strokeWidth: 1,
                              dashArray: [4, 4])),
                      titlesData: const FlTitlesData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _samples
                              .map((s) => FlSpot(
                                  s.time
                                          .difference(_samples.first.time)
                                          .inMilliseconds /
                                      1000,
                                  s.level))
                              .toList(),
                          isCurved: false,
                          color: colors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                              show: true,
                              color: colors.primary.withValues(alpha: 0.10)),
                        )
                      ],
                    )))),
          const SizedBox(height: 16),
          Wrap(spacing: 16, runSpacing: 8, children: [
            _badge('Min ${min?.toStringAsFixed(0) ?? '—'}%',
                Icons.south_rounded, colors),
            _badge('Max ${max?.toStringAsFixed(0) ?? '—'}%',
                Icons.north_rounded, colors),
            _badge(
                'Perubahan ${difference == null ? '—' : '${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(1)}'} poin',
                Icons.insights_outlined,
                colors),
          ]),
          if (_tankThresholds.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
                'Penanda tangki: merah = tutup, biru = normal, hijau = buka. Posisi dihitung dari jarak sensor dan kedalaman wadah.',
                style: TextStyle(
                    color: colors.onSurfaceVariant, fontSize: 12, height: 1.5)),
          ],
        ]));
  }

  Widget _card(ColorScheme colors, Widget child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.7))),
        child: child,
      );

  Widget _badge(String label, IconData icon, ColorScheme colors) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: colors.onPrimaryContainer),
          const SizedBox(width: 6),
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 12,
                      height: 1.4)))
        ]),
      );

  Widget _metric(String label, String value, ColorScheme colors,
          {IconData? icon}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14)),
        child: LayoutBuilder(builder: (context, constraints) {
          final title = Text(label,
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 13, height: 1.5));
          final reading = Text(value,
              style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700));
          if (constraints.maxWidth < 260 ||
              MediaQuery.textScalerOf(context).scale(14) > 22) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 6), reading]);
          }
          return Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: 10)
            ],
            Expanded(child: title),
            const SizedBox(width: 12),
            Flexible(child: reading)
          ]);
        }),
      );
}
