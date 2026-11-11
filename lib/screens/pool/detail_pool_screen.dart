import 'dart:async';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';
import '../../models/pool_configuration.dart';
import 'widgets/animated_water_tank.dart';

class DetailPoolScreen extends StatefulWidget {
  const DetailPoolScreen({super.key, this.client});
  final Dio? client;

  @override
  State<DetailPoolScreen> createState() => _DetailPoolScreenState();
}

class _DetailPoolScreenState extends State<DetailPoolScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Map<String, dynamic>? poolData;
  Map<String, dynamic>? latestWaterData;
  bool isLoading = true;
  bool isLoadingWater = true;
  bool _fetchingWater = false;
  bool _appActive = true;
  int _waterRequestGeneration = 0;
  bool _started = false;
  final List<({DateTime time, double level})> _samples = [];
  String? _lastReadingKey;
  String? _poolId;
  String? _detailError;
  String? _waterError;
  Timer? _pollingTimer;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const _pageLabels = ['Monitoring', 'Tren', 'Spesifikasi'];
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Dio _dio = widget.client ??
      Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10)));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    } else if (poolData != null && _entranceController.isDismissed) {
      _entranceController.forward();
    }

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
    WidgetsBinding.instance.addObserver(this);
    _fetchDetail();
    _fetchWater();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _appActive && ModalRoute.of(context)?.isCurrent == true) {
        _fetchWater();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive && mounted && ModalRoute.of(context)?.isCurrent == true) {
      _fetchWater();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _waterRequestGeneration++;
    _entranceController.dispose();
    _pageController.dispose();
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
      if (mounted) {
        final normalizedPool = ContainerConfig.normalizePoolMap(
            Map<String, dynamic>.from(response.data['data']));
        setState(() {
          poolData = normalizedPool;
          if (latestWaterData == null &&
              normalizedPool['last_status'] is Map) {
            latestWaterData = TelemetryLog.normalizeTelemetryMap(
                Map<String, dynamic>.from(
                    normalizedPool['last_status'] as Map));
          }
        });
        if (MediaQuery.disableAnimationsOf(context)) {
          _entranceController.value = 1;
        } else {
          _entranceController.forward(from: 0);
        }
      }
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
    final requestedPoolId = _poolId!;
    final generation = ++_waterRequestGeneration;
    _fetchingWater = true;
    if (mounted) setState(() => isLoadingWater = true);
    try {
      final response = await _dio.get('$baseUrl/api/water/level',
          queryParameters: {'poolId': requestedPoolId, 'limit': 30},
          options: await _authOptions());
      if (response.data['success'] != true)
        throw StateError('Data tidak tersedia');
      final items = TelemetryLog.extractTelemetryList(response.data);
      if (mounted &&
          generation == _waterRequestGeneration &&
          requestedPoolId == _poolId)
        setState(() {
          latestWaterData = items.isEmpty
              ? (poolData?['last_status'] is Map
                  ? TelemetryLog.normalizeTelemetryMap(
                      Map<String, dynamic>.from(
                          poolData!['last_status'] as Map))
                  : null)
              : items.first;
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
      if (mounted &&
          generation == _waterRequestGeneration &&
          requestedPoolId == _poolId)
        setState(() =>
            _waterError = 'Pembaruan gagal. Periksa koneksi lalu coba lagi.');
    } finally {
      _fetchingWater = false;
      if (mounted && generation == _waterRequestGeneration) {
        setState(() => isLoadingWater = false);
      }
    }
  }

  double? _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value');
  bool get _sensorValid =>
      (latestWaterData?['sensorValid'] ?? latestWaterData?['sensor_valid']) !=
      false;
  double? get _level => _sensorValid
      ? _number(
          latestWaterData?['waterLevel'] ?? latestWaterData?['water_level'])
      : null;
  double? get _distance => _sensorValid
      ? _number(
          latestWaterData?['distance'] ?? latestWaterData?['sensor_distance'])
      : null;
  bool? get _inletValveOpen {
    final val =
        latestWaterData?['fillValveOpen'] ?? latestWaterData?['inlet_valve'];
    return val is bool ? val : null;
  }

  bool? get _outletValveOpen {
    final val =
        latestWaterData?['drainValveOpen'] ?? latestWaterData?['outlet_valve'];
    return val is bool ? val : null;
  }

  double? get _tankDepth {
    final depth = _number(poolData?['kedalaman'] ?? poolData?['max_depth']);
    return depth != null && depth.isFinite && depth > 0 ? depth : null;
  }

  String _value(dynamic value, String unit) =>
      value == null ? '—' : '$value $unit';
  String get _controlState {
    final raw =
        latestWaterData?['controlState'] ?? latestWaterData?['system_state'];
    return raw?.toString().trim().isNotEmpty == true
        ? raw.toString()
        : 'Belum diketahui';
  }

  String get _valveState {
    if (latestWaterData == null) return 'Belum diketahui';
    final fillValue = _inletValveOpen;
    final drainValue = _outletValveOpen;
    if (fillValue is! bool || drainValue is! bool) return 'Belum diketahui';
    final fill = fillValue;
    final drain = drainValue;
    if (fill && drain) return 'Mengisi & Membuang';
    if (fill) return 'Mengisi air (Inlet terbuka)';
    if (drain) return 'Membuang air (Outlet terbuka)';
    return 'Tertutup';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.dark,
    );
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        colorScheme: colors,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF060911),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          centerTitle: true,
          leadingWidth: 60,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFFF8FAFC),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E3A8A).withOpacity(0.55),
                            const Color(0xFF1E293B).withOpacity(0.85),
                            const Color(0xFF0F172A).withOpacity(0.90),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF60A5FA).withOpacity(0.28),
                        ),
                      ),
                      child: BackButton(
                        color: const Color(0xFFF8FAFC),
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                          iconSize: WidgetStateProperty.all(18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E3A8A).withOpacity(0.55),
                          const Color(0xFF0E7490).withOpacity(0.42),
                          const Color(0xFF0F172A).withOpacity(0.90),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF60A5FA).withOpacity(0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF38BDF8),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF38BDF8).withOpacity(0.65),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'Detail wadah',
                          style: TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1E3A8A).withOpacity(0.55),
                              const Color(0xFF1E293B).withOpacity(0.85),
                              const Color(0xFF0F172A).withOpacity(0.90),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF60A5FA).withOpacity(0.28),
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: 'Perbarui monitoring',
                          onPressed: isLoadingWater
                              ? null
                              : () {
                                  if (poolData == null) _fetchDetail();
                                  _fetchWater();
                                },
                          icon: AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            child: isLoadingWater
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFF60A5FA),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh_rounded,
                                    key: ValueKey('refresh'),
                                    size: 19,
                                    color: Color(0xFF60A5FA),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -40,
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
                      top: 200,
                      left: -60,
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
                      bottom: 80,
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
            ),
            SafeArea(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 280),
                child: isLoading
                    ? _loadingState(colors)
                    : poolData == null
                        ? _errorState(colors)
                        : Center(
                            key: const ValueKey('content'),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: FadeTransition(
                                opacity: _entranceController.drive(
                                    CurveTween(curve: Curves.easeOutCubic)),
                                child: _contentSlides(colors),
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPage(int index) {
    if (!_pageController.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    }
  }

  Widget _contentSlides(ColorScheme colors) => LayoutBuilder(
        builder: (context, constraints) {
          final compactHeader = constraints.maxHeight < 540 ||
              MediaQuery.textScalerOf(context).scale(14) > 21;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _heroHeader(colors, compact: compactHeader),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.09)),
                ),
                child: Row(children: [
                  for (var index = 0; index < _pageLabels.length; index++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                        child: Semantics(
                          selected: _currentPage == index,
                          child: TextButton(
                            onPressed: () => _selectPage(index),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              foregroundColor: _currentPage == index
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF94A3B8),
                              backgroundColor: _currentPage == index
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              _pageLabels[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _currentPage == index
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageLabels.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => SingleChildScrollView(
                  key: PageStorageKey('pool-slide-$index'),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: switch (index) {
                    0 => _levelCard(colors),
                    1 => _trendCard(colors),
                    _ => _settingsCard(colors),
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                label: 'Halaman ${_currentPage + 1} dari ${_pageLabels.length}',
                child: ExcludeSemantics(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < _pageLabels.length; index++)
                          AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                      ]),
                ),
              ),
            ),
          ]);
        },
      );

  Widget _loadingState(ColorScheme colors) => Center(
        key: const ValueKey('loading-state'),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.09)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Menyiapkan data wadah…',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      );

  Widget _errorState(ColorScheme colors) => Center(
        key: const ValueKey('error-state'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _card(
              colors,
              Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 32,
                    color: Color(0xFFF87171),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data belum bisa ditampilkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _detailError ?? 'Detail wadah tidak tersedia.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (_poolId != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _fetchDetail,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: const Color(0xFFF8FAFC),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFFF8FAFC)),
                    label: const Text(
                      'Coba lagi',
                      style: TextStyle(color: Color(0xFFF8FAFC)),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ),
      );

  Widget _heroHeader(ColorScheme colors, {bool compact = false}) {
    final active = poolData!['isActive'] == true;
    if (compact) {
      return _card(
        colors,
        isHero: true,
        Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              boxShadow: [
                BoxShadow(
                  color: (active
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      .withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${poolData!['namaWadah'] ?? 'Wadah air'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
      );
    }
    return Semantics(
      container: true,
      label:
          '${poolData!['namaWadah'] ?? 'Wadah air'}, ${active ? 'aktif' : 'nonaktif'}',
      child: _card(
        colors,
        isHero: true,
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.20),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFF3B82F6).withOpacity(0.35)),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${poolData!['namaWadah'] ?? 'Wadah air'}',
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        boxShadow: [
                          BoxShadow(
                            color: (active
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B))
                                .withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Serial • ${poolData!['serial'] ?? '—'}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _lightBadge(
                    active ? 'Wadah aktif' : 'Wadah nonaktif',
                    active
                        ? Icons.check_circle_rounded
                        : Icons.pause_circle_rounded,
                    isLive: active,
                  ),
                  _lightBadge('Sinkron tiap 5 detik', Icons.sync_rounded),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _levelCard(ColorScheme colors) {
    final timestamp =
        DateTime.tryParse('${latestWaterData?['createdAt']}')?.toLocal();
    final depth = _tankDepth;
    final height =
        _level == null || depth == null ? null : _level! / 100 * depth;
    final levelLabel = _level == null
        ? '—'
        : height != null
            ? '${height.toStringAsFixed(height % 1 == 0 ? 0 : 1)} cm'
            : '${_level!.toStringAsFixed(_level! % 1 == 0 ? 0 : 1)}%';
    final subtitle = _waterError != null
        ? 'Data terakhir • pembaruan gagal'
        : _level == null
            ? 'Menunggu pembacaan sensor'
            : 'Pembacaan sensor terbaru';

    final tank = Column(children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedWaterTank(
          level: _level,
          depth: depth,
          colors: colors,
          inletActive: _inletValveOpen == true,
          outletActive: _outletValveOpen == true,
          thresholds: _tankThresholds,
        ),
      ),
      AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 360),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Text(
          levelLabel,
          key: ValueKey(levelLabel),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 38,
            height: 1,
            letterSpacing: -1.0,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
      const SizedBox(height: 8),
      if (depth != null) ...[
        Text(
          '${_level == null ? '—' : '${_level!.toStringAsFixed(1)}%'} • '
          'Kedalaman ${depth.toStringAsFixed(depth % 1 == 0 ? 0 : 1)} cm',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
      ],
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _waterError == null
              ? const Color(0xFF34D399)
              : const Color(0xFFF87171),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]);

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _metric('Jarak sensor ke air', _value(_distance, 'cm'), colors,
            icon: Icons.straighten_rounded),
        const SizedBox(height: 12),
        _flowSummary(colors),
        if (timestamp != null) ...[
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.schedule_rounded,
                size: 16, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Diperbarui ${timestamp.toString().split('.').first}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  height: 1.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ]),
        ],
        if (_waterError != null) ...[
          const SizedBox(height: 12),
          Text(
            _waterError!,
            style: const TextStyle(
              color: Color(0xFFF87171),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ],
    );

    return _card(
      colors,
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _sectionHeader(
          'Level air',
          'Pantau kondisi wadah secara langsung',
          Icons.waves_rounded,
          colors,
          trailing: isLoadingWater
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF3B82F6)),
                )
              : null,
        ),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
          if (constraints.maxWidth >= 280 && !largeText) {
            return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 5, child: tank),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: _automationPanel(colors)),
                ]);
          }
          return Column(children: [
            tank,
            const SizedBox(height: 16),
            _automationPanel(colors),
          ]);
        }),
        const SizedBox(height: 24),
        details,
      ]),
    );
  }

  Widget _flowSummary(ColorScheme colors) {
    final fillValue = _inletValveOpen;
    final drainValue = _outletValveOpen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Aliran air',
          style: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _stateChip(
            fillValue is! bool
                ? 'Inlet belum terbaca'
                : fillValue
                    ? 'Inlet terbuka'
                    : 'Inlet tertutup',
            Icons.south_rounded,
            fillValue == true,
            colors,
          ),
          _stateChip(
            drainValue is! bool
                ? 'Outlet belum terbaca'
                : drainValue
                    ? 'Outlet terbuka'
                    : 'Outlet tertutup',
            Icons.north_east_rounded,
            drainValue == true,
            colors,
          ),
        ]),
      ]),
    );
  }

  Widget _automationPanel(ColorScheme colors) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_mode_rounded,
                  color: Color(0xFF60A5FA),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Status otomatis',
                  style: TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _statusReading('Mode kendali', _controlState, colors),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.white.withOpacity(0.06)),
          ),
          _statusReading('Status valve', _valveState, colors),
        ]),
      );

  Widget _settingsCard(ColorScheme colors) => _card(
        colors,
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sectionHeader(
            'Spesifikasi wadah',
            'Batas kerja yang sedang digunakan',
            Icons.tune_rounded,
            colors,
          ),
          const SizedBox(height: 20),
          _settingsGroup(
            'Dimensi',
            Icons.aspect_ratio_rounded,
            [
              ('Kedalaman', _value(poolData!['kedalaman'], 'cm')),
              ('Sensor ke dasar', _value(poolData!['jarakSensorDasar'], 'cm')),
            ],
            colors,
          ),
          const SizedBox(height: 12),
          _settingsGroup(
            'Pengisian',
            Icons.water_drop_rounded,
            [
              ('Mulai isi', _value(poolData!['batasIsiMulai'], 'cm')),
              ('Berhenti isi', _value(poolData!['batasIsiBerhenti'], 'cm')),
            ],
            colors,
          ),
          const SizedBox(height: 12),
          _settingsGroup(
            'Pembuangan',
            Icons.water_damage_rounded,
            [
              ('Mulai buang', _value(poolData!['batasBuangMulai'], 'cm')),
              ('Berhenti buang', _value(poolData!['batasBuangBerhenti'], 'cm')),
            ],
            colors,
          ),
        ]),
      );

  Map<String, double> get _tankThresholds {
    final depth = _tankDepth;
    if (depth == null) return {};
    return {
      for (final entry in [
        ('Isi mulai', 'batasIsiMulai'),
        ('Isi berhenti', 'batasIsiBerhenti'),
        ('Buang mulai', 'batasBuangMulai'),
        ('Buang berhenti', 'batasBuangBerhenti')
      ])
        if (_number(poolData?[entry.$2])?.isFinite == true)
          entry.$1:
              (_number(poolData?[entry.$2])! / depth * 100).clamp(0.0, 100.0),
    };
  }

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
          _sectionHeader(
            'Tren level air',
            'Riwayat sesi ini • maksimal 30 titik',
            Icons.show_chart_rounded,
            colors,
          ),
          const SizedBox(height: 20),
          if (_samples.length < 2)
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08))),
                child: const Column(children: [
                  Icon(Icons.timeline_rounded,
                      color: Color(0xFF3B82F6), size: 28),
                  SizedBox(height: 12),
                  Text(
                      'Grafik akan muncul setelah dua pembacaan sensor diterima.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          height: 1.5)),
                ]))
          else
            Semantics(
                label:
                    'Tren ${_samples.length} pembacaan. Minimum $min persen, maksimum $max persen.',
                child: Container(
                    height: 196,
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
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
                              color: Colors.white.withOpacity(0.05),
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
                          color: const Color(0xFF3B82F6),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
                              radius: 3,
                              color: const Color(0xFF3B82F6),
                              strokeWidth: 2,
                              strokeColor: const Color(0xFF060911),
                            ),
                          ),
                          belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF2563EB).withOpacity(0.25),
                                  Colors.transparent,
                                ],
                              )),
                        )
                      ],
                    )))),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
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
            const Text(
                'Penanda tangki menunjukkan ambang pengisian dan pembuangan yang tersimpan.',
                style: TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 12, height: 1.5)),
          ],
        ]));
  }

  Widget _sectionHeader(
          String title, String subtitle, IconData icon, ColorScheme colors,
          {Widget? trailing}) =>
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.30)),
          ),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.25)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.4)),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ]);

  Widget _lightBadge(String label, IconData icon, {bool isLive = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isLive
              ? const Color(0xFF10B981).withOpacity(0.14)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isLive
                ? const Color(0xFF10B981).withOpacity(0.28)
                : Colors.white.withOpacity(0.09),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            icon,
            size: 14,
            color: isLive ? const Color(0xFF34D399) : const Color(0xFFF8FAFC),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isLive ? const Color(0xFF34D399) : const Color(0xFFF8FAFC),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
      );

  Widget _stateChip(
          String label, IconData icon, bool active, ColorScheme colors) =>
      AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF10B981).withOpacity(0.14)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? const Color(0xFF10B981).withOpacity(0.28)
                : Colors.white.withOpacity(0.09),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            icon,
            size: 15,
            color: active ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color:
                    active ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
      );

  Widget _statusReading(String label, String value, ColorScheme colors) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );

  Widget _settingsGroup(String title, IconData icon,
          List<(String, String)> values, ColorScheme colors) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final tiles = values
                .map((item) => _settingValue(item.$1, item.$2, colors))
                .toList();
            if (constraints.maxWidth < 420 ||
                MediaQuery.textScalerOf(context).scale(14) > 21) {
              return Column(children: [
                tiles.first,
                const SizedBox(height: 12),
                tiles.last,
              ]);
            }
            return Row(children: [
              Expanded(child: tiles.first),
              const SizedBox(width: 12),
              Expanded(child: tiles.last),
            ]);
          }),
        ]),
      );

  Widget _settingValue(String label, String value, ColorScheme colors) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ]),
      );

  Widget _card(ColorScheme colors, Widget child, {bool isHero = false}) =>
      Container(
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
              padding: const EdgeInsets.all(18),
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

  Widget _badge(String label, IconData icon, ColorScheme colors) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.28),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: const Color(0xFF34D399)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ]),
      );

  Widget _metric(String label, String value, ColorScheme colors,
          {IconData? icon}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final title = Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.5,
            ),
          );
          final reading = Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          );
          if (constraints.maxWidth < 260 ||
              MediaQuery.textScalerOf(context).scale(14) > 22) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 6), reading],
            );
          }
          return Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 10),
            ],
            Expanded(child: title),
            const SizedBox(width: 12),
            Flexible(child: reading),
          ]);
        }),
      );
}
