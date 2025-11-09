import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isFetched) {
      poolId = ModalRoute.of(context)!.settings.arguments as String;
      fetchPoolDetail();
      fetchLatestWaterLevel();
      isFetched = true;
    }
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

  Future<void> fetchLatestWaterLevel() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

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
          setState(() {
            latestWaterData = waterLevels[0]; // Get the first (latest) data
            isLoadingWater = false;
          });
        } else {
          setState(() => isLoadingWater = false);
        }
      }
    } on DioException catch (e) {
      print("DioException fetch water level: ${e.message}");
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        // Network connection error
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
                  // Pool Information Card
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.water,
                                color: Color(0xFF3B82F6),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    poolData!['namaWadah'],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Serial: ${poolData!['serial']}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: poolData!['isActive']
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                poolData!['isActive'] ? "Aktif" : "Tidak Aktif",
                                style: TextStyle(
                                  color: poolData!['isActive']
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                "Kedalaman",
                                "${poolData!['kedalaman']} cm",
                                Icons.straighten,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoItem(
                                "Keran Tutup",
                                "${poolData!['keranTutup']} cm",
                                Icons.lock,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                "Keran Normal",
                                "${poolData!['keranNormal']} cm",
                                Icons.water_drop,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoItem(
                                "Keran Buka",
                                "${poolData!['keranBuka']} cm",
                                Icons.lock_open,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Water Level Card
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
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
                        const SizedBox(height: 16),
                        if (latestWaterData != null) ...[
                          // Pie Chart Section
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: PieChart(
                                    PieChartData(
                                      sections: [
                                        PieChartSectionData(
                                          value: latestWaterData!['waterLevel']
                                              .toDouble(),
                                          color: _getWaterLevelColor(
                                            latestWaterData!['waterLevel'],
                                          ),
                                          title:
                                              '${latestWaterData!['waterLevel']}%',
                                          titleStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          radius: 60,
                                        ),
                                        PieChartSectionData(
                                          value:
                                              (100 - latestWaterData!['waterLevel'])
                                                  .toDouble(),
                                          color: Colors.grey[300],
                                          title: '',
                                          radius: 50,
                                        ),
                                      ],
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                      startDegreeOffset: -90,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: _getWaterLevelColor(
                                                  latestWaterData!['waterLevel'],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Air: ${latestWaterData!['waterLevel']}%",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Kosong: ${100 - latestWaterData!['waterLevel']}%",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getWaterLevelColor(
                                              latestWaterData!['waterLevel'],
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: _getWaterLevelColor(
                                                latestWaterData!['waterLevel'],
                                              ).withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            _getWaterLevelStatus(
                                              latestWaterData!['waterLevel'],
                                            ),
                                            style: TextStyle(
                                              color: _getWaterLevelColor(
                                                latestWaterData!['waterLevel'],
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${latestWaterData!['distance']} cm",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      Text(
                                        "Jarak Sensor",
                                        style: TextStyle(
                                          fontSize: 14,
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
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        "${poolData!['kedalaman']} cm",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      Text(
                                        "Kedalaman Maksimal",
                                        style: TextStyle(
                                          fontSize: 14,
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
                                  const SizedBox(height: 4),
                                  Text(
                                    "Pastikan perangkat terhubung dan server aktif",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: refreshData,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text("Coba Lagi"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
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
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
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
}
