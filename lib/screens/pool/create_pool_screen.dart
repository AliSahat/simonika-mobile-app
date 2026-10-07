import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';

class CreatePoolScreen extends StatefulWidget {
  const CreatePoolScreen({super.key, this.client});
  final Dio? client;

  @override
  State<CreatePoolScreen> createState() => _CreatePoolScreenState();
}

class _CreatePoolScreenState extends State<CreatePoolScreen> {
  final _formKey = GlobalKey<FormState>();

  final serialController = TextEditingController();
  final namaWadahController = TextEditingController();
  final kedalamanController = TextEditingController();
  final jarakSensorDasarController = TextEditingController();
  final batasIsiMulaiController = TextEditingController();
  final batasIsiBerhentiController = TextEditingController();
  final batasBuangBerhentiController = TextEditingController();
  final batasBuangMulaiController = TextEditingController();

  bool isLoading = false;
  bool modeAuto = true;

  @override
  void dispose() {
    for (final controller in [
      serialController,
      namaWadahController,
      kedalamanController,
      jarakSensorDasarController,
      batasIsiMulaiController,
      batasIsiBerhentiController,
      batasBuangBerhentiController,
      batasBuangMulaiController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _value(TextEditingController controller) =>
      int.parse(controller.text.trim());

  String? _validateThresholds() {
    final depth = int.tryParse(kedalamanController.text.trim());
    final sensorBottom = int.tryParse(jarakSensorDasarController.text.trim());
    final fillStart = int.tryParse(batasIsiMulaiController.text.trim());
    final drainStop = int.tryParse(batasBuangBerhentiController.text.trim());
    final fillStop = int.tryParse(batasIsiBerhentiController.text.trim());
    final drainStart = int.tryParse(batasBuangMulaiController.text.trim());

    if ([depth, sensorBottom, fillStart, drainStop, fillStop, drainStart]
        .contains(null)) {
      return null;
    }
    if (sensorBottom! < depth!) {
      return 'Jarak sensor ke dasar tidak boleh lebih kecil dari kedalaman wadah.';
    }
    if ([fillStart!, drainStop!, fillStop!, drainStart!]
        .any((value) => value < 0 || value > depth)) {
      return 'Semua ambang harus berada antara 0 cm dan kedalaman wadah.';
    }
    if (!(fillStart < drainStop &&
        drainStop < fillStop &&
        fillStop < drainStart)) {
      return 'Urutan harus: isi mulai < buang berhenti < isi berhenti < buang mulai.';
    }
    return null;
  }

  Future<void> createPool() async {
    if (isLoading || !_formKey.currentState!.validate()) return;

    final thresholdError = _validateThresholds();
    if (thresholdError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(thresholdError), backgroundColor: Colors.red[600]),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw StateError('Sesi berakhir');

      final dio = widget.client ?? Dio();
      final response = await dio.post(
        '$baseUrl/api/pool',
        data: {
          'serial': serialController.text.trim(),
          'namaWadah': namaWadahController.text.trim(),
          'kedalaman': _value(kedalamanController),
          'jarakSensorDasar': _value(jarakSensorDasarController),
          'batasIsiMulai': _value(batasIsiMulaiController),
          'batasIsiBerhenti': _value(batasIsiBerhentiController),
          'batasBuangMulai': _value(batasBuangMulaiController),
          'batasBuangBerhenti': _value(batasBuangBerhentiController),
          'modeAuto': modeAuto,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] != true) {
        throw StateError('Penyimpanan gagal');
      }

      final poolId = response.data['data']?['_id'];
      if (poolId is String && poolId.isNotEmpty) {
        try {
          await dio.post(
            '$baseUrl/api/mqtt/publish',
            data: {'poolId': poolId},
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } catch (_) {
          // Data wadah tetap tersimpan. Sinkronisasi dapat diulang dari edit wadah.
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Wadah berhasil ditambahkan dan dikonfigurasi.'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Gagal menambahkan wadah. Silakan coba lagi.'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0878DE),
      brightness: dark ? Brightness.dark : Brightness.light,
    );

    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colors),
      child: Scaffold(
        backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
        appBar: AppBar(
          title: const Text('Tambah wadah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
          foregroundColor: colors.onSurface,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _section(
                    colors,
                    title: 'Identitas & kalibrasi',
                    description:
                        'Kedalaman adalah tinggi air maksimum. Jarak sensor ke dasar dipakai untuk menghitung tinggi air dari pembacaan HY-SRF05.',
                    children: [
                      _field(colors, namaWadahController, 'Nama wadah',
                          'Contoh: Tangki utama', Icons.label_outline_rounded),
                      const SizedBox(height: 16),
                      _field(colors, serialController, 'Serial perangkat',
                          'Contoh: 00e5b570', Icons.qr_code_rounded),
                      const SizedBox(height: 16),
                      _field(colors, kedalamanController, 'Kedalaman wadah',
                          'Contoh: 100', Icons.straighten_rounded,
                          numeric: true, positive: true),
                      const SizedBox(height: 16),
                      _field(
                        colors,
                        jarakSensorDasarController,
                        'Jarak sensor ke dasar',
                        'Contoh: 103',
                        Icons.vertical_align_bottom_rounded,
                        numeric: true,
                        positive: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _section(
                    colors,
                    title: 'Kendali otomatis',
                    description:
                        'Contoh 100 cm: mulai isi 30, berhenti isi 90, mulai buang 95, berhenti buang 75.',
                    children: [
                      _field(colors, batasIsiMulaiController, 'Isi mulai',
                          'Contoh: 30', Icons.water_drop_outlined,
                          numeric: true),
                      const SizedBox(height: 16),
                      _field(colors, batasIsiBerhentiController, 'Isi berhenti',
                          'Contoh: 90', Icons.stop_circle_outlined,
                          numeric: true),
                      const SizedBox(height: 16),
                      _field(colors, batasBuangMulaiController, 'Buang mulai',
                          'Contoh: 95', Icons.arrow_downward_rounded,
                          numeric: true),
                      const SizedBox(height: 16),
                      _field(colors, batasBuangBerhentiController,
                          'Buang berhenti', 'Contoh: 75', Icons.pause_circle_outline,
                          numeric: true),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mode otomatis'),
                        subtitle: const Text(
                            'ESP8266 menjaga proses isi/buang sampai ambang berhenti tercapai.'),
                        value: modeAuto,
                        onChanged:
                            isLoading ? null : (value) => setState(() => modeAuto = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton.icon(
            onPressed: isLoading ? null : createPool,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(isLoading ? 'Menyimpan…' : 'Simpan wadah'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(ColorScheme colors,
      {required String title,
      required String description,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(description,
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    ColorScheme colors,
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    bool numeric = false,
    bool positive = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !isLoading,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixText: numeric ? 'cm' : null,
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '$label wajib diisi';
        if (numeric) {
          final number = int.tryParse(value.trim());
          if (number == null) return 'Masukkan angka bulat dalam cm';
          if (number < 0 || (positive && number == 0)) {
            return positive
                ? 'Nilai harus lebih dari 0 cm'
                : 'Nilai tidak boleh negatif';
          }
        }
        return null;
      },
    );
  }
}
