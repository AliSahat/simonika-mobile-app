import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailPoolScreen extends StatefulWidget {
  const DetailPoolScreen({super.key});

  @override
  State<DetailPoolScreen> createState() => _DetailPoolScreenState();
}

class _DetailPoolScreenState extends State<DetailPoolScreen> {
  Map<String, dynamic>? poolData;
  bool isLoading = true;
  String? poolId;
  bool isFetched = false; // supaya fetch hanya sekali

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isFetched) {
      poolId = ModalRoute.of(context)!.settings.arguments as String;
      fetchPoolDetail();
      isFetched = true;
    }
  }

  Future<void> fetchPoolDetail() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      var response = await Dio().get(
        "http://localhost:3000/api/pool/$poolId",
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Kolam")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : poolData == null
              ? const Center(child: Text("Gagal memuat data"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Nama Wadah: ${poolData!['namaWadah']}",
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Serial: ${poolData!['serial']}"),
                          Text("Kedalaman: ${poolData!['kedalaman']} cm"),
                          Text("Keran Tutup: ${poolData!['keranTutup']}%"),
                          Text("Keran Normal: ${poolData!['keranNormal']}%"),
                          Text("Keran Buka: ${poolData!['keranBuka']}%"),
                          Text("Status: ${poolData!['isActive'] ? "Aktif" : "Tidak Aktif"}"),
                          const SizedBox(height: 20),

                          // Button ke Monitoring
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // nanti arahkan ke layar monitoring
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Monitoring coming soon...")),
                                );
                              },
                              child: const Text("Monitoring Sensor"),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
