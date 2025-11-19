import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePoolScreen extends StatefulWidget {
  const UpdatePoolScreen({super.key});

  @override
  State<UpdatePoolScreen> createState() => _UpdatePoolScreenState();
}

class _UpdatePoolScreenState extends State<UpdatePoolScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController serialController = TextEditingController();
  final TextEditingController namaWadahController = TextEditingController();
  final TextEditingController kedalamanController = TextEditingController();
  final TextEditingController keranTutupController = TextEditingController();
  final TextEditingController keranNormalController = TextEditingController();
  final TextEditingController keranBukaController = TextEditingController();

  bool isLoading = false;
  bool isLoadingData = true;
  bool isActive = false;
  String? poolId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (poolId == null) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is String && arguments.isNotEmpty) {
        poolId = arguments;
        fetchPoolData();
      } else {
        setState(() => isLoadingData = false);
      }
    }
  }

  Future<void> fetchPoolData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final response = await Dio().get(
        "https://majarosoft.yogaone.me/api/pool/$poolId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final poolData = response.data['data'];

      serialController.text = poolData['serial'] ?? '';
      namaWadahController.text = poolData['namaWadah'] ?? '';
      kedalamanController.text = (poolData['kedalaman'] ?? 0).toString();
      keranTutupController.text = (poolData['keranTutup'] ?? 0).toString();
      keranNormalController.text = (poolData['keranNormal'] ?? 0).toString();
      keranBukaController.text = (poolData['keranBuka'] ?? 0).toString();
      isActive = poolData['isActive'] ?? false;

      setState(() => isLoadingData = false);
    } catch (e) {
      debugPrint("Error fetch pool data: $e");
      setState(() => isLoadingData = false);
    }
  }

  Future<void> updatePool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final response = await Dio().put(
        "https://majarosoft.yogaone.me/api/pool/$poolId",
        data: {
          "serial": serialController.text.trim(),
          "namaWadah": namaWadahController.text.trim(),
          "kedalaman": int.parse(kedalamanController.text.trim()),
          "keranTutup": int.parse(keranTutupController.text.trim()),
          "keranNormal": int.parse(keranNormalController.text.trim()),
          "keranBuka": int.parse(keranBukaController.text.trim()),
          "isActive": isActive,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data["success"] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Wadah berhasil diperbarui!"),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error update pool: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gagal memperbarui wadah"),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingData) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Edit Wadah",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Edit Wadah",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.edit, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "Edit Wadah",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Perbarui informasi wadah",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Section
            Container(
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
                  const Text(
                    "Informasi Umum",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: serialController,
                    label: "Serial Device",
                    icon: Icons.qr_code,
                    hint: "Masukkan serial device",
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: namaWadahController,
                    label: "Nama Wadah",
                    icon: Icons.label,
                    hint: "Masukkan nama wadah",
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: kedalamanController,
                    label: "Kedalaman (cm)",
                    icon: Icons.straighten,
                    hint: "Masukkan kedalaman",
                    isNumber: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Keran Settings Section
            Container(
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
                  const Text(
                    "Pengaturan Keran",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: keranTutupController,
                    label: "Keran Tutup (cm)",
                    icon: Icons.lock,
                    hint: "Masukkan nilai keran tutup",
                    isNumber: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: keranNormalController,
                    label: "Keran Normal (cm)",
                    icon: Icons.water,
                    hint: "Masukkan nilai keran normal",
                    isNumber: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: keranBukaController,
                    label: "Keran Buka (cm)",
                    icon: Icons.lock_open,
                    hint: "Masukkan nilai keran buka",
                    isNumber: true,
                  ),
                  const SizedBox(height: 16),
                  // Active Status Switch
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.power_settings_new,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Status Aktif",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Switch(
                        value: isActive,
                        onChanged: (value) => setState(() => isActive = value),
                        activeColor: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : updatePool,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.update, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Perbarui Wadah",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label wajib diisi";
        }
        return null;
      },
    );
  }
}
