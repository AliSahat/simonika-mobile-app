import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';
import '../../models/pool_configuration.dart';
import '../../widgets/notification_button.dart';

class PoolScreen extends StatefulWidget {
  const PoolScreen({super.key, this.client});

  final Dio? client;

  @override
  State<PoolScreen> createState() => _PoolScreenState();
}

class _PoolScreenState extends State<PoolScreen> {
  List<dynamic> pools = [];
  bool isLoading = true;
  bool _isFetching = false;
  String? _error;
  String _query = '';
  late final Dio _dio;

  @override
  void initState() {
    super.initState();
    _dio = widget.client ??
        Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));
    fetchPools();
  }

  Future<void> fetchPools() async {
    if (!mounted || _isFetching) return;
    setState(() {
      _isFetching = true;
      isLoading = pools.isEmpty;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        if (mounted)
          setState(() {
            _error = 'Silakan masuk kembali untuk melihat wadah Anda.';
          });
        return;
      }
      final response = await _dio.get(
        '$baseUrl/api/pool',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted)
        setState(() {
          final rawList = response.data['data'] as List? ?? [];
          pools = rawList
              .map((item) => item is Map
                  ? ContainerConfig.normalizePoolMap(
                      Map<String, dynamic>.from(item))
                  : item)
              .toList();
        });
    } catch (e) {
      debugPrint('Error fetch pool: $e');
      if (mounted)
        setState(() {
          _error =
              'Wadah belum dapat dimuat. Periksa koneksi Anda dan coba lagi.';
        });
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
          _isFetching = false;
        });
    }
  }

  Future<void> _createPool() async {
    final result = await Navigator.pushNamed(context, '/create-pool');
    if (result == true && mounted) await fetchPools();
  }

  void goToDetail(String poolId) {
    Navigator.pushNamed(context, '/detail-pool', arguments: poolId);
  }

  Future<void> deletePool(String poolId, String poolName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Konfirmasi Hapus",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text("Apakah Anda yakin ingin menghapus wadah '$poolName'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Batal",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      await _dio.delete(
        "$baseUrl/api/pool/$poolId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text("Wadah berhasil dihapus")),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        fetchPools();
      }
    } catch (e) {
      debugPrint("Error delete pool: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text("Gagal menghapus wadah")),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> retryPublish(String poolId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await _dio.post('$baseUrl/api/mqtt/publish',
          data: {'poolId': poolId},
          options: Options(headers: {'Authorization': 'Bearer $token'}));

      if (response.data is Map && response.data['success'] != true) {
        throw StateError('Publish ditolak');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Konfigurasi berhasil dikirim ke broker. Penerapan oleh perangkat belum terkonfirmasi.')));
    } catch (error) {
      debugPrint('[MQTT DEBUG] Error retry publish: $error');
      if (error is DioException) {
        debugPrint('[MQTT DEBUG] URL: ${error.requestOptions.uri}');
        debugPrint('[MQTT DEBUG] HTTP Status: ${error.response?.statusCode}');
        debugPrint('[MQTT DEBUG] Response Body: ${error.response?.data}');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Konfigurasi sudah tersimpan, tetapi belum berhasil dikirim. Anda dapat mencoba lagi.'),
        action: SnackBarAction(
            label: 'Kirim ulang', onPressed: () => retryPublish(poolId)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB), brightness: Brightness.dark);
    final filtered = pools
        .where((pool) => '${pool['namaWadah'] ?? ''} ${pool['serial'] ?? ''}'
            .toLowerCase()
            .contains(_query.toLowerCase()))
        .toList();
    final active = pools.where((pool) => pool['isActive'] == true).length;
    final inactive = pools.length - active;
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
                  child: LayoutBuilder(builder: (context, viewport) {
                    final compact = viewport.maxHeight < 640 ||
                        MediaQuery.textScalerOf(context).scale(14) > 22;
                    return Column(children: [
                      Padding(
                        padding:
                            EdgeInsets.fromLTRB(20, compact ? 8 : 12, 20, 0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!compact) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'SIMONIKA',
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 10,
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Semantics(
                                            header: true,
                                            child: const Text(
                                              'Wadah air Anda',
                                              style: TextStyle(
                                                color: Color(0xFFF8FAFC),
                                                fontSize: 20,
                                                letterSpacing: -0.4,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
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
                                                  'Pantau dan kelola wadah air Anda.',
                                                  style: TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 12,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const NotificationButton(),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1D4ED8)
                                            .withOpacity(0.28),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.38),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 24, sigmaY: 24),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    const Color(0xFF1E40AF)
                                                        .withOpacity(0.72),
                                                    const Color(0xFF0E7490)
                                                        .withOpacity(0.62),
                                                    const Color(0xFF1E293B)
                                                        .withOpacity(0.78),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: -40,
                                            right: -20,
                                            child: IgnorePointer(
                                              child: Container(
                                                width: 140,
                                                height: 140,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      const Color(0xFF38BDF8)
                                                          .withOpacity(0.35),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -50,
                                            left: -20,
                                            child: IgnorePointer(
                                              child: Container(
                                                width: 150,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      const Color(0xFF10B981)
                                                          .withOpacity(0.24),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 18, vertical: 16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              border: Border.all(
                                                color: const Color(0xFF60A5FA)
                                                    .withOpacity(0.32),
                                                width: 1.0,
                                              ),
                                            ),
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
                                                        color: active > 0
                                                            ? const Color(
                                                                0xFF34D399)
                                                            : const Color(
                                                                0xFF94A3B8),
                                                        boxShadow: active > 0
                                                            ? [
                                                                BoxShadow(
                                                                  color: const Color(
                                                                          0xFF34D399)
                                                                      .withOpacity(
                                                                          0.6),
                                                                  blurRadius: 8,
                                                                ),
                                                              ]
                                                            : null,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Expanded(
                                                      child: Text(
                                                        'Ringkasan wadah',
                                                        style: TextStyle(
                                                          color:
                                                              Color(0xFFF8FAFC),
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      isLoading ||
                                                              _error != null
                                                          ? 'Memuat…'
                                                          : '${pools.length} terdaftar',
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFFE2E8F0),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFeatures: [
                                                          FontFeature
                                                              .tabularFigures(),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Divider(
                                                  color: Colors.white
                                                      .withOpacity(0.14),
                                                  height: 20,
                                                ),
                                                LayoutBuilder(builder:
                                                    (context, constraints) {
                                                  final entries = [
                                                    (
                                                      'Total wadah',
                                                      pools.length,
                                                      const Color(0xFFBAE6FD),
                                                      const Color(0xFF0284C7)
                                                          .withOpacity(0.35),
                                                      'Total'
                                                    ),
                                                    (
                                                      'Aktif',
                                                      active,
                                                      const Color(0xFF6EE7B7),
                                                      const Color(0xFF059669)
                                                          .withOpacity(0.35),
                                                      pools.isEmpty
                                                          ? '0%'
                                                          : '${((active / pools.length) * 100).round()}%'
                                                    ),
                                                    (
                                                      'Nonaktif',
                                                      inactive,
                                                      inactive > 0
                                                          ? const Color(
                                                              0xFFFDE68A)
                                                          : const Color(
                                                              0xFFCBD5E1),
                                                      inactive > 0
                                                          ? const Color(
                                                                  0xFFD97706)
                                                              .withOpacity(0.35)
                                                          : Colors.white
                                                              .withOpacity(
                                                                  0.12),
                                                      pools.isEmpty
                                                          ? '0%'
                                                          : '${((inactive / pools.length) * 100).round()}%'
                                                    ),
                                                  ];
                                                  final stacked =
                                                      MediaQuery.textScalerOf(
                                                                  context)
                                                              .scale(14) >
                                                          22;
                                                  Widget buildKpiItem(
                                                      (
                                                        String,
                                                        int,
                                                        Color,
                                                        Color,
                                                        String
                                                      ) entry) {
                                                    return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          entry.$1,
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFFDBEAFE),
                                                            fontSize: 11,
                                                            height: 1.3,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                isLoading ||
                                                                        _error !=
                                                                            null
                                                                    ? '—'
                                                                    : '${entry.$2}',
                                                                style:
                                                                    const TextStyle(
                                                                  color: Color(
                                                                      0xFFF8FAFC),
                                                                  fontSize: 24,
                                                                  height: 1.05,
                                                                  letterSpacing:
                                                                      -0.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontFeatures: [
                                                                    FontFeature
                                                                        .tabularFigures(),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 7,
                                                                vertical: 2,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: entry.$4,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            999),
                                                                border:
                                                                    Border.all(
                                                                  color: entry
                                                                      .$3
                                                                      .withOpacity(
                                                                          0.28),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                entry.$5,
                                                                style:
                                                                    TextStyle(
                                                                  color:
                                                                      entry.$3,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontFeatures: const [
                                                                    FontFeature
                                                                        .tabularFigures(),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    );
                                                  }

                                                  if (stacked) {
                                                    return Wrap(
                                                      spacing: 24,
                                                      runSpacing: 14,
                                                      children: entries
                                                          .map(buildKpiItem)
                                                          .toList(),
                                                    );
                                                  }
                                                  return Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                          child: buildKpiItem(
                                                              entries[0])),
                                                      Container(
                                                        width: 1,
                                                        height: 44,
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 12),
                                                        color: Colors.white
                                                            .withOpacity(0.14),
                                                      ),
                                                      Expanded(
                                                          child: buildKpiItem(
                                                              entries[1])),
                                                      Container(
                                                        width: 1,
                                                        height: 44,
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 12),
                                                        color: Colors.white
                                                            .withOpacity(0.14),
                                                      ),
                                                      Expanded(
                                                          child: buildKpiItem(
                                                              entries[2])),
                                                    ],
                                                  );
                                                }),
                                                const SizedBox(height: 14),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                  child: SizedBox(
                                                    height: 6,
                                                    child: Row(
                                                      children: [
                                                        if (active > 0)
                                                          Expanded(
                                                            flex: active,
                                                            child: Container(
                                                              decoration:
                                                                  const BoxDecoration(
                                                                gradient:
                                                                    LinearGradient(
                                                                  colors: [
                                                                    Color(
                                                                        0xFF38BDF8),
                                                                    Color(
                                                                        0xFF34D399),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        if (inactive > 0)
                                                          Expanded(
                                                            flex: inactive,
                                                            child: Container(
                                                              color: const Color(
                                                                      0xFFFBBF24)
                                                                  .withOpacity(
                                                                      0.85),
                                                            ),
                                                          ),
                                                        if (pools.isEmpty)
                                                          Expanded(
                                                            child: Container(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.16),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ] else ...[
                                const Text(
                                  'Wadah air Anda',
                                  style: TextStyle(
                                    color: Color(0xFFF8FAFC),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isLoading || _error != null
                                      ? 'Ringkasan wadah: —'
                                      : '${pools.length} wadah • $active aktif • $inactive nonaktif',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                    height: 1.4,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              LayoutBuilder(builder: (context, constraints) {
                                final title = Semantics(
                                  header: true,
                                  child: const Text(
                                    'Daftar wadah',
                                    style: TextStyle(
                                      color: Color(0xFFF8FAFC),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                                final heading = Row(children: [
                                  Expanded(child: title),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: _isFetching
                                        ? 'Memperbarui wadah'
                                        : 'Perbarui daftar wadah',
                                    onPressed: _isFetching ? null : fetchPools,
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                      backgroundColor:
                                          Colors.white.withOpacity(0.06),
                                      foregroundColor: const Color(0xFFF8FAFC),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    icon: _isFetching
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF3B82F6),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.refresh_rounded,
                                            size: 20,
                                            color: Color(0xFFF8FAFC),
                                          ),
                                  ),
                                ]);
                                final button = Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB)
                                            .withOpacity(0.38),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: FilledButton.icon(
                                    onPressed: _createPool,
                                    icon: const Icon(Icons.add_rounded,
                                        size: 18, color: Color(0xFFF8FAFC)),
                                    label: const Text(
                                      'Tambah wadah',
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: const Color(0xFFF8FAFC),
                                      minimumSize: const Size(48, 48),
                                      shape: const StadiumBorder(),
                                    ),
                                  ),
                                );
                                if (compact) {
                                  return Row(children: [
                                    Expanded(child: heading),
                                    const SizedBox(width: 8),
                                    IconButton.filled(
                                      tooltip: 'Tambah wadah',
                                      onPressed: _createPool,
                                      icon: const Icon(Icons.add_rounded,
                                          color: Color(0xFFF8FAFC)),
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF2563EB),
                                        foregroundColor:
                                            const Color(0xFFF8FAFC),
                                        minimumSize: const Size(48, 48),
                                      ),
                                    ),
                                  ]);
                                }
                                if (constraints.maxWidth < 320 ||
                                    MediaQuery.textScalerOf(context).scale(14) >
                                        22) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      heading,
                                      const SizedBox(height: 8),
                                      button,
                                    ],
                                  );
                                }
                                return Row(children: [
                                  Expanded(child: heading),
                                  const SizedBox(width: 12),
                                  button,
                                ]);
                              }),
                            ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: TextField(
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                          style: const TextStyle(color: Color(0xFFF8FAFC)),
                          decoration: InputDecoration(
                            labelText: 'Cari wadah',
                            labelStyle:
                                const TextStyle(color: Color(0xFF94A3B8)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            hintText: 'Nama wadah atau serial',
                            hintStyle:
                                const TextStyle(color: Color(0xFF64748B)),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor:
                                const Color(0xFF121826).withOpacity(0.70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.09),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.09),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          key: const PageStorageKey('pool-list'),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            if (isLoading)
                              SliverToBoxAdapter(
                                child: _stateCard(
                                  colors,
                                  icon: Icons.water_drop_outlined,
                                  title: 'Memuat wadah…',
                                  description: 'Menyiapkan data wadah Anda.',
                                  loading: true,
                                ),
                              )
                            else if (_error != null)
                              SliverToBoxAdapter(
                                child: _stateCard(
                                  colors,
                                  icon: Icons.cloud_off_outlined,
                                  title: 'Belum dapat menampilkan wadah',
                                  description: _error!,
                                  action: FilledButton.tonalIcon(
                                    onPressed: fetchPools,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: const Color(0xFFF8FAFC),
                                      shape: const StadiumBorder(),
                                    ),
                                    icon: const Icon(Icons.refresh_rounded,
                                        color: Color(0xFFF8FAFC)),
                                    label: const Text(
                                      'Coba lagi',
                                      style:
                                          TextStyle(color: Color(0xFFF8FAFC)),
                                    ),
                                  ),
                                ),
                              )
                            else if (pools.isEmpty)
                              SliverToBoxAdapter(
                                child: _stateCard(
                                  colors,
                                  icon: Icons.water_drop_outlined,
                                  title: 'Mulai dengan wadah pertama',
                                  description:
                                      'Tambahkan wadah untuk memantau air dan mengatur kendalinya.',
                                ),
                              )
                            else if (filtered.isEmpty)
                              SliverToBoxAdapter(
                                child: _stateCard(
                                  colors,
                                  icon: Icons.search_off_rounded,
                                  title: 'Wadah tidak ditemukan',
                                  description:
                                      'Coba nama wadah atau serial yang berbeda.',
                                ),
                              )
                            else
                              SliverPadding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: _poolCard(filtered[index], colors),
                                    ),
                                    childCount: filtered.length,
                                  ),
                                ),
                              ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 96)),
                          ],
                        ),
                      ),
                    ]);
                  }),
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
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
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
                colors: [
                  const Color(0xFF181F30).withOpacity(0.76),
                  const Color(0xFF101624).withOpacity(0.66),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.09),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _stateCard(ColorScheme colors,
      {required IconData icon,
      required String title,
      required String description,
      bool loading = false,
      Widget? action}) {
    return _glassBentoCard(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        if (loading)
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.09)),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 32),
          ),
        const SizedBox(height: 20),
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
            fontSize: 15,
            height: 1.5,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 20), action],
      ]),
    );
  }

  Widget _poolCard(dynamic rawPool, ColorScheme colors) {
    final pool = rawPool is Map
        ? ContainerConfig.normalizePoolMap(Map<String, dynamic>.from(rawPool))
        : rawPool;
    final active = pool['isActive'] == true;
    final modeAuto = pool['modeAuto'] is bool ? pool['modeAuto'] as bool : null;
    final id = '${pool['_id'] ?? ''}';
    final name = '${pool['namaWadah'] ?? 'Wadah air'}';
    final depth = pool['kedalaman'];
    final fillStart = pool['batasIsiMulai'];
    final drainStart = pool['batasBuangMulai'];
    final configurationComplete = [
      'kedalaman',
      'jarakSensorDasar',
      'batasIsiMulai',
      'batasIsiBerhenti',
      'batasBuangMulai',
      'batasBuangBerhenti',
      'modeAuto',
    ].every((key) => pool[key] != null);

    return _glassBentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF2563EB).withOpacity(0.20)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? const Color(0xFF3B82F6).withOpacity(0.35)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Icon(
              Icons.water_drop_outlined,
              color: active ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Serial • ${pool['serial'] ?? '—'}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.4,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opsi wadah $name',
            color: const Color(0xFF121826),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.09)),
            ),
            onSelected: (value) async {
              if (value == 'delete') {
                await deletePool(id, name);
              } else {
                final result = await Navigator.pushNamed(
                    context, '/update-pool',
                    arguments: id);
                if (mounted) {
                  await fetchPools();
                  if (result is Map && result['retryPublish'] == true) {
                    final currentPoolId = result['poolId'] as String;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text(
                          'Konfigurasi sudah tersimpan, tetapi belum berhasil dikirim. Anda dapat mencoba lagi.'),
                      action: SnackBarAction(
                          label: 'Kirim ulang',
                          onPressed: () => retryPublish(currentPoolId)),
                    ));
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined, color: Color(0xFFF8FAFC)),
                  title: Text(
                    'Edit wadah',
                    style: TextStyle(color: Color(0xFFF8FAFC)),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFF87171)),
                  title: Text(
                    'Hapus wadah',
                    style: TextStyle(color: Color(0xFFF87171)),
                  ),
                ),
              ),
            ],
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Color(0xFF94A3B8),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statusPill(
              colors,
              icon: active
                  ? Icons.check_circle_outline_rounded
                  : Icons.pause_circle_outline_rounded,
              label: active ? 'Aktif' : 'Nonaktif',
              highlighted: active,
              isLive: active,
            ),
            _statusPill(
              colors,
              icon: modeAuto == true
                  ? Icons.hdr_auto_outlined
                  : Icons.tune_rounded,
              label: modeAuto == null
                  ? 'Mode belum diatur'
                  : modeAuto
                      ? 'Otomatis'
                      : 'Manual',
              highlighted: modeAuto == true,
            ),
            if (depth != null)
              _statusPill(
                colors,
                icon: Icons.straighten_rounded,
                label: 'Kedalaman $depth cm',
                highlighted: false,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!configurationComplete)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF87171).withOpacity(0.25),
              ),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: Color(0xFFF87171)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Konfigurasi belum lengkap • buka Edit wadah',
                  style: TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ]),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              const Icon(Icons.waves_rounded,
                  size: 18, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rentang kerja otomatis: $fillStart–$drainStart cm',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ]),
          ),
        const SizedBox(height: 14),
        FilledButton.tonal(
          onPressed: () => goToDetail(id),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB).withOpacity(0.14),
            foregroundColor: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: const Color(0xFF3B82F6).withOpacity(0.28),
              ),
            ),
          ),
          child: const Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Icon(Icons.insights_outlined,
                  size: 18, color: Color(0xFF60A5FA)),
              Text(
                'Monitor wadah',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Color(0xFF60A5FA)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _statusPill(
    ColorScheme colors, {
    required IconData icon,
    required String label,
    required bool highlighted,
    bool isLive = false,
  }) {
    final bg = isLive
        ? const Color(0xFF10B981).withOpacity(0.14)
        : highlighted
            ? const Color(0xFF2563EB).withOpacity(0.18)
            : Colors.white.withOpacity(0.06);
    final fg = isLive
        ? const Color(0xFF34D399)
        : highlighted
            ? const Color(0xFF3B82F6)
            : const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isLive
              ? const Color(0xFF10B981).withOpacity(0.28)
              : highlighted
                  ? const Color(0xFF3B82F6).withOpacity(0.28)
                  : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ]),
    );
  }
}
