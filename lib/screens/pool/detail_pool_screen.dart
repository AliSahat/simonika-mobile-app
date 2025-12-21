// ignore_for_file: unused_import, deprecated_member_use

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class DetailPoolScreen extends StatefulWidget {
  const DetailPoolScreen({super.key});

  @override
  State<DetailPoolScreen> createState() => _DetailPoolScreenState();
}

class _DetailPoolScreenState extends State<DetailPoolScreen> {
  Map<String, dynamic>? poolData;
  Map<String, dynamic>? latestWaterData;
  bool isLoading = true;
  bool isLoadingWater = true;
  String? poolId;
  bool isFetched = false; // supaya fetch hanya sekali

  // Timer untuk polling realtime
  Timer? _pollingTimer;

  // kontrol keran otomatis: true = terbuka (ON), false = tertutup (OFF)
  bool valveToggleState = false;

  // kontrol pembuangan otomatis: true = terbuka (ON), false = tertutup (OFF)
  bool dischargeToggleState = false;
  // defaults jika poolData tidak menyediakan ambang
  static const int _defaultDischargeOpenThreshold = 80;
  static const int _defaultDischargeCloseThreshold = 20;

  // Tentukan status pembuangan berdasarkan level air dan ambang dari poolData (jika ada)
  String _getDischargeStatusFromLevel(int waterLevel) {
    final openThreshold = (poolData?['pembuanganBatasBuka'] is num)
        ? (poolData!['pembuanganBatasBuka'] as num).toInt()
        : _defaultDischargeOpenThreshold;
    final closeThreshold = (poolData?['pembuanganBatasTutup'] is num)
        ? (poolData!['pembuanganBatasTutup'] as num).toInt()
        : _defaultDischargeCloseThreshold;

    if (waterLevel > openThreshold) return "Aktif";
    if (waterLevel <= closeThreshold) return "Tertutup";
    return "Normal";
  }

  Color _getDischargeStatusColor(int waterLevel) {
    final status = _getDischargeStatusFromLevel(waterLevel);
    switch (status) {
      case "Aktif":
        return Colors.green;
      case "Tertutup":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isFetched) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is String && arguments.isNotEmpty) {
        poolId = arguments;
        fetchPoolDetail();
        // Panggil awal (tampilkan error pada panggilan awal jika ada)
        fetchLatestWaterLevel();
        // Mulai polling periodik setiap 5 detik, supress SnackBar untuk polling agar tidak spam
        _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          if (mounted) {
            fetchLatestWaterLevel(suppressSnackBar: true);
          }
        });
        isFetched = true;
      } else {
        // Handle case when no arguments are passed - use post frame callback
        setState(() {
          isLoading = false;
          isLoadingWater = false;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("ID wadah tidak ditemukan"),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pop(context);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchPoolDetail() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      var response = await Dio().get(
        "http://localhost:3000/api/pool/$poolId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data["success"] == true) {
        setState(() {
          poolData = response.data["data"];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetch detail: $e");
      setState(() => isLoading = false);
    }
  }

  // suppressSnackBar: jika true, jangan tampilkan SnackBar saat terjadi error (digunakan untuk polling)
  Future<void> fetchLatestWaterLevel({bool suppressSnackBar = false}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null) return;

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      var response = await dio.get(
        "http://localhost:3000/api/water/level",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data["success"] == true) {
        List<dynamic> waterLevels = response.data["data"];
        if (waterLevels.isNotEmpty) {
          // update latest data dan set valveToggleState secara otomatis:
          // - jika level air TERdeteksi "Rendah" => buka keran (true)
          // - jika level air Normal/Sedang/Tinggi => tutup keran (false)
          final item = waterLevels[0];
          final rawLevel = item['waterLevel'] ?? 0;
          final int wl = (rawLevel is int)
              ? rawLevel
              : (rawLevel is double)
              ? rawLevel.toInt()
              : int.tryParse(rawLevel.toString()) ?? 0;
          setState(() {
            latestWaterData = item;
            isLoadingWater = false;
            valveToggleState = _getWaterLevelStatus(wl) == "Rendah";
            // set discharge otomatis berdasarkan ambang (gunakan fungsi pembantu)
            dischargeToggleState = _getDischargeStatusFromLevel(wl) == "Aktif";
          });
        } else {
          setState(() => isLoadingWater = false);
        }
      }
    } on DioException catch (e) {
      print("DioException fetch water level: ${e.message}");
      if (!suppressSnackBar &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout)) {
        // Network connection error - use post frame callback
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.",
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          });
        }
      }
      setState(() => isLoadingWater = false);
    } catch (e) {
      print("Error fetch water level: $e");
      setState(() => isLoadingWater = false);
    }
  }

  Future<void> refreshData() async {
    setState(() {
      isLoadingWater = true;
    });
    // saat manual refresh, tampilkan error jika ada => suppressSnackBar = false
    await fetchLatestWaterLevel();
  }

  Color _getWaterLevelColor(int waterLevel) {
    if (waterLevel >= 70) return Colors.green;
    if (waterLevel >= 30) return Colors.orange;
    return Colors.red;
  }

  String _getWaterLevelStatus(int waterLevel) {
    if (waterLevel >= 70) return "Tinggi";
    if (waterLevel >= 30) return "Sedang";
    return "Rendah";
  }

  String _getValveStatus() {
    if (latestWaterData == null || poolData == null) return "Normal";

    final distance = (latestWaterData!['distance'] ?? 0).toDouble();
    final keranTutup = (poolData!['keranTutup'] ?? 0).toDouble();
    final keranNormal = (poolData!['keranNormal'] ?? 0).toDouble();
    final keranBuka = (poolData!['keranBuka'] ?? 0).toDouble();

    // Check with tolerance of ±2 cm
    if ((distance - keranTutup).abs() <= 2) return "Tertutup";
    if ((distance - keranBuka).abs() <= 2) return "Terbuka";
    return "Normal";
  }

  Color _getValveStatusColor() {
    final status = _getValveStatus();
    switch (status) {
      case "Tertutup":
        return Colors.red;
      case "Terbuka":
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  bool _isValveOpen() {
    return _getValveStatus() == "Terbuka";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Detail Wadah",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: poolData?['isActive'] == true
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: poolData?['isActive'] == true
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  poolData?['isActive'] == true ? "AKTIF" : "NONAKTIF",
                  style: TextStyle(
                    color: poolData?['isActive'] == true
                        ? Colors.green
                        : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            )
          : poolData == null
          ? const Center(child: Text("Gagal memuat data"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Pool Information Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.water_drop,
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
                                    poolData?['namaWadah'] ?? 'Nama Wadah',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    "Serial: ${poolData?['serial'] ?? 'N/A'}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                "Kedalaman",
                                "${poolData?['kedalaman'] ?? 0} cm",
                                Icons.straighten,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                "Keran Tutup",
                                "${poolData?['keranTutup'] ?? 0} cm",
                                Icons.lock,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                "Keran Normal",
                                "${poolData?['keranNormal'] ?? 0} cm",
                                Icons.water_drop,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                "Keran Buka",
                                "${poolData?['keranBuka'] ?? 0} cm",
                                Icons.lock_open,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Level Air Terkini with ON badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Level Air Terkini",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "ON",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (isLoadingWater)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (latestWaterData != null) ...[
                          // Circular Gauge
                          Center(
                            child: Container(
                              width: 180,
                              height: 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background circle
                                  SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: CircularProgressIndicator(
                                      value: 1.0,
                                      strokeWidth: 12,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  // Progress circle
                                  SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: CircularProgressIndicator(
                                      value:
                                          (latestWaterData?['waterLevel'] ??
                                              0) /
                                          100,
                                      strokeWidth: 12,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getWaterLevelColor(
                                          latestWaterData?['waterLevel'] ?? 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Center content
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${latestWaterData?['waterLevel'] ?? 0}%',

                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: _getWaterLevelColor(
                                            latestWaterData?['waterLevel'] ?? 0,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Level Air',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status badge
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getWaterLevelColor(
                                  latestWaterData?['waterLevel'] ?? 0,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getWaterLevelColor(
                                    latestWaterData?['waterLevel'] ?? 0,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.water_drop,
                                    size: 16,
                                    color: _getWaterLevelColor(
                                      latestWaterData?['waterLevel'] ?? 0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getWaterLevelStatus(
                                      latestWaterData?['waterLevel'] ?? 0,
                                    ),
                                    style: TextStyle(
                                      color: _getWaterLevelColor(
                                        latestWaterData?['waterLevel'] ?? 0,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Distance and Depth info
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${latestWaterData?['distance'] ?? 0} cm",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      Text(
                                        "Jarak Sensor",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${poolData?['kedalaman'] ?? 0} cm",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      Text(
                                        "Kedalaman Maks",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_off_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Data sensor tidak tersedia",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Keran Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: _getValveStatusColor(),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Status Keran",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Keran ${_getValveStatus()}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getValveStatusColor(),
                                ),
                              ),
                            ),
                            // Switch status keran (otomatis) - non-interaktif, mengikuti logika level air
                            Switch(
                              value: valveToggleState,
                              onChanged: null,
                              activeColor: Colors.blue,
                              activeTrackColor: Colors.blue.withOpacity(0.3),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.grey.withOpacity(0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusIndicator(
                                "Tertutup",
                                "${poolData?['keranTutup'] ?? 0} cm",
                                Colors.red,
                                _getValveStatus() == "Tertutup",
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusIndicator(
                                "Normal",
                                "${poolData?['keranNormal'] ?? 0} cm",
                                Colors.blue,
                                _getValveStatus() == "Normal",
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusIndicator(
                                "Terbuka",
                                "${poolData?['keranBuka'] ?? 0} cm",
                                Colors.green,
                                _getValveStatus() == "Terbuka",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Pembuangan Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_damage,
                              color: latestWaterData != null
                                  ? _getDischargeStatusColor(
                                      (latestWaterData?['waterLevel'] ?? 0)
                                              is num
                                          ? (latestWaterData?['waterLevel']
                                                    as num)
                                                .toInt()
                                          : int.tryParse(
                                                  latestWaterData?['waterLevel']
                                                          ?.toString() ??
                                                      '0',
                                                ) ??
                                                0,
                                    )
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Status Pembuangan",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                // tampilkan status dinamis berdasarkan latestWaterData jika tersedia
                                latestWaterData != null
                                    ? "Pembuangan ${_getDischargeStatusFromLevel((latestWaterData?['waterLevel'] ?? 0) is num ? (latestWaterData?['waterLevel'] as num).toInt() : int.tryParse(latestWaterData?['waterLevel']?.toString() ?? '0') ?? 0)}"
                                    : "Pembuangan Tertutup",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: latestWaterData != null
                                      ? _getDischargeStatusColor(
                                          (latestWaterData?['waterLevel'] ?? 0)
                                                  is num
                                              ? (latestWaterData?['waterLevel']
                                                        as num)
                                                    .toInt()
                                              : int.tryParse(
                                                      latestWaterData?['waterLevel']
                                                              ?.toString() ??
                                                          '0',
                                                    ) ??
                                                    0,
                                        )
                                      : Colors.red,
                                ),
                              ),
                            ),
                            // Switch pembuangan otomatis (non-interaktif)
                            Switch(
                              value: dischargeToggleState,
                              onChanged: null,
                              activeColor: Colors.red.shade700,
                              activeTrackColor: Colors.red.withOpacity(0.2),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.grey.withOpacity(0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDischargeIndicator(
                                "Tertutup",
                                "< ${poolData?['pembuanganBatasTutup'] ?? _defaultDischargeCloseThreshold}%",
                                Colors.red,
                                // aktif jika status == Tertutup
                                latestWaterData != null
                                    ? _getDischargeStatusFromLevel(
                                            (latestWaterData?['waterLevel'] ??
                                                        0)
                                                    is num
                                                ? (latestWaterData?['waterLevel']
                                                          as num)
                                                      .toInt()
                                                : int.tryParse(
                                                        latestWaterData?['waterLevel']
                                                                ?.toString() ??
                                                            '0',
                                                      ) ??
                                                      0,
                                          ) ==
                                          "Tertutup"
                                    : false,
                                Icons.block,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDischargeIndicator(
                                "Normal",
                                "${(poolData?['pembuanganBatasTutup'] ?? _defaultDischargeCloseThreshold)}-${(poolData?['pembuanganBatasBuka'] ?? _defaultDischargeOpenThreshold)}%",
                                Colors.grey,
                                latestWaterData != null
                                    ? _getDischargeStatusFromLevel(
                                            (latestWaterData?['waterLevel'] ??
                                                        0)
                                                    is num
                                                ? (latestWaterData?['waterLevel']
                                                          as num)
                                                      .toInt()
                                                : int.tryParse(
                                                        latestWaterData?['waterLevel']
                                                                ?.toString() ??
                                                            '0',
                                                      ) ??
                                                      0,
                                          ) ==
                                          "Normal"
                                    : false,
                                Icons.opacity,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDischargeIndicator(
                                "Aktif",
                                "> ${poolData?['pembuanganBatasBuka'] ?? _defaultDischargeOpenThreshold}%",
                                Colors.green,
                                latestWaterData != null
                                    ? _getDischargeStatusFromLevel(
                                            (latestWaterData?['waterLevel'] ??
                                                        0)
                                                    is num
                                                ? (latestWaterData?['waterLevel']
                                                          as num)
                                                      .toInt()
                                                : int.tryParse(
                                                        latestWaterData?['waterLevel']
                                                                ?.toString() ??
                                                            '0',
                                                      ) ??
                                                      0,
                                          ) ==
                                          "Aktif"
                                    : false,
                                Icons.water_damage,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Last update info
                  if (latestWaterData != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Terakhir update: ${latestWaterData != null ? DateTime.parse(latestWaterData!['createdAt'] ?? DateTime.now().toIso8601String()).toLocal().toString().substring(0, 19) : 'N/A'}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "5 detik yang lalu",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDischargeIndicator(
    String label,
    String value,
    Color color,
    bool isActive,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isActive ? color : Colors.grey[400], size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? color : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              color: isActive ? color : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
    String label,
    String value,
    Color color,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            label == "Tertutup"
                ? Icons.lock
                : label == "Terbuka"
                ? Icons.lock_open
                : Icons.water_drop,
            color: isActive ? color : Colors.grey[400],
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? color : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              color: isActive ? color : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
