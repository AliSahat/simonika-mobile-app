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

  final TextEditingController serialController = TextEditingController();
  final TextEditingController namaWadahController = TextEditingController();
  final TextEditingController kedalamanController = TextEditingController();
  final TextEditingController keranTutupController = TextEditingController();
  final TextEditingController keranNormalController = TextEditingController();
  final TextEditingController keranBukaController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    for (final controller in [
      serialController,
      namaWadahController,
      kedalamanController,
      keranTutupController,
      keranNormalController,
      keranBukaController
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> createPool() async {
    if (isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null) throw StateError('Sesi berakhir');
      final response = await (widget.client ?? Dio()).post(
        "$baseUrl/api/pool",
        data: {
          "serial": serialController.text.trim(),
          "namaWadah": namaWadahController.text.trim(),
          "kedalaman": int.parse(kedalamanController.text.trim()),
          "keranTutup": int.parse(keranTutupController.text.trim()),
          "keranNormal": int.parse(keranNormalController.text.trim()),
          "keranBuka": int.parse(keranBukaController.text.trim()),
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data["success"] != true)
        throw StateError('Penyimpanan gagal');
      if (response.data["success"] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Wadah berhasil ditambahkan!"),
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
      debugPrint("Error create pool: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gagal menambahkan wadah. Silakan coba lagi."),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF0878DE),
        brightness: dark ? Brightness.dark : Brightness.light);
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF168EED),
                          Color(0xFF0865B5),
                          Color(0xFF154675)
                        ]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.water_drop_outlined,
                            color: Colors.white, size: 28),
                        const SizedBox(height: 12),
                        const Text('Satu wadah baru,\nlebih mudah dipantau.',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 10),
                        const Text(
                            'Hubungkan perangkat dan tentukan pengaturan wadah Anda.',
                            style: TextStyle(
                                color: Color(0xFFE4F2FF),
                                fontSize: 14,
                                height: 1.5)),
                      ]),
                ),
                const SizedBox(height: 20),
                _section(colors,
                    number: '01',
                    title: 'Identitas wadah',
                    description: 'Gunakan serial yang tertera pada perangkat.',
                    children: [
                      _field(colors,
                          controller: namaWadahController,
                          label: 'Nama wadah',
                          hint: 'Contoh: Tangki utama',
                          icon: Icons.label_outline_rounded),
                      const SizedBox(height: 18),
                      _field(colors,
                          controller: serialController,
                          label: 'Serial perangkat',
                          hint: 'Masukkan serial perangkat',
                          icon: Icons.qr_code_rounded),
                      const SizedBox(height: 18),
                      _field(colors,
                          controller: kedalamanController,
                          label: 'Kedalaman wadah',
                          hint: 'Contoh: 120',
                          icon: Icons.straighten_rounded,
                          numeric: true,
                          positive: true),
                    ]),
                const SizedBox(height: 16),
                _section(colors,
                    number: '02',
                    title: 'Pengaturan keran',
                    description:
                        'Masukkan jarak dari sensor ke permukaan air untuk setiap ambang.',
                    children: [
                      _field(colors,
                          controller: keranTutupController,
                          label: 'Ambang keran tutup',
                          hint: 'Masukkan jarak',
                          icon: Icons.lock_outline_rounded,
                          numeric: true),
                      const SizedBox(height: 18),
                      _field(colors,
                          controller: keranNormalController,
                          label: 'Ambang keran normal',
                          hint: 'Masukkan jarak',
                          icon: Icons.water_drop_outlined,
                          numeric: true),
                      const SizedBox(height: 18),
                      _field(colors,
                          controller: keranBukaController,
                          label: 'Ambang keran buka',
                          hint: 'Masukkan jarak',
                          icon: Icons.lock_open_rounded,
                          numeric: true,
                          last: true),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 20, color: colors.onPrimaryContainer),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(
                                      'Semua ukuran menggunakan sentimeter (cm). Sesuaikan nilai dengan pemasangan sensor Anda.',
                                      style: TextStyle(
                                          color: colors.onPrimaryContainer,
                                          fontSize: 12,
                                          height: 1.5))),
                            ]),
                      ),
                    ]),
              ],
            ),
          ),
        )),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Align(
              heightFactor: 1,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading ? null : createPool,
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          children: [
                            if (isLoading)
                              SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onSurfaceVariant))
                            else
                              const Icon(Icons.add_circle_outline_rounded,
                                  size: 20),
                            Text(
                                isLoading ? 'Menyimpan wadah…' : 'Simpan wadah',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                          ]),
                    ),
                  ))),
        ),
      ),
    );
  }

  Widget _section(ColorScheme colors,
      {required String number,
      required String title,
      required String description,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(number,
                  style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(
              child: Semantics(
                  header: true,
                  child: Text(title,
                      style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)))),
        ]),
        const SizedBox(height: 10),
        Text(description,
            style: TextStyle(
                color: colors.onSurfaceVariant, fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
        ...children,
      ]),
    );
  }

  Widget _field(ColorScheme colors,
      {required TextEditingController controller,
      required String label,
      required String hint,
      required IconData icon,
      bool numeric = false,
      bool positive = false,
      bool last = false}) {
    return TextFormField(
      controller: controller,
      enabled: !isLoading,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => createPool() : null,
      autocorrect: !numeric && controller == namaWadahController,
      style: TextStyle(color: colors.onSurface, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colors.primary, size: 22),
        suffixText: numeric ? 'cm' : null,
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.primary, width: 2)),
        errorMaxLines: 3,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '$label wajib diisi';
        if (numeric) {
          final number = int.tryParse(value.trim());
          if (number == null) return 'Masukkan angka bulat dalam cm';
          if (number < 0 || (positive && number == 0))
            return positive
                ? 'Kedalaman harus lebih dari 0 cm'
                : 'Jarak tidak boleh negatif';
        }
        return null;
      },
    );
  }
}
