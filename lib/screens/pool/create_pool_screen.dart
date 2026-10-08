import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';
import '../../models/pool_configuration.dart';
import 'widgets/pool_configuration_form.dart';

class CreatePoolScreen extends StatefulWidget {
  const CreatePoolScreen({super.key, this.client});
  final Dio? client;

  @override
  State<CreatePoolScreen> createState() => _CreatePoolScreenState();
}

class _CreatePoolScreenState extends State<CreatePoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final fields = PoolConfigurationControllers();
  bool modeAuto = true;
  bool isLoading = false;

  @override
  void dispose() {
    fields.dispose();
    super.dispose();
  }

  Future<void> createPool() async {
    if (isLoading || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);
    try {
      final token = (await SharedPreferences.getInstance()).getString('token');
      if (token == null) throw StateError('Sesi berakhir');
      final response = await (widget.client ?? Dio()).post(
        '$baseUrl/api/pool',
        data: fields.payload(modeAuto: modeAuto),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data is Map && response.data['success'] != true) {
        throw StateError('Penyimpanan ditolak');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Konfigurasi wadah tersimpan di backend.')));
      Navigator.pop(context, true);
    } catch (error) {
      debugPrint('Error create pool: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Konfigurasi belum dapat disimpan. Silakan coba lagi.')));
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
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _hero(),
                  const SizedBox(height: 20),
                  PoolConfigurationForm(
                    fields: fields,
                    enabled: !isLoading,
                    modeAuto: modeAuto,
                    onModeAutoChanged: (value) =>
                        setState(() => modeAuto = value),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: FilledButton.icon(
                onPressed: isLoading ? null : createPool,
                icon: isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(isLoading ? 'Menyimpan…' : 'Simpan konfigurasi'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFF168EED),
            Color(0xFF0865B5),
            Color(0xFF154675)
          ]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.water_drop_outlined, color: Colors.white, size: 28),
              SizedBox(height: 12),
              Text('Konfigurasi wadah baru',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Isi ukuran dan ambang sesuai pemasangan perangkat.',
                  style: TextStyle(color: Color(0xFFE4F2FF), height: 1.5)),
            ]),
      );
}
