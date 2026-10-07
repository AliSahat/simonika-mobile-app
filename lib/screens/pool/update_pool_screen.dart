import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';

class UpdatePoolScreen extends StatefulWidget {
  const UpdatePoolScreen({super.key, this.client});
  final Dio? client;

  @override
  State<UpdatePoolScreen> createState() => _UpdatePoolScreenState();
}

class _UpdatePoolScreenState extends State<UpdatePoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mqttFormKey = GlobalKey<FormState>();
  String? _loadError;
  bool _initialized = false;

  final TextEditingController serialController = TextEditingController();
  final TextEditingController namaWadahController = TextEditingController();
  final TextEditingController kedalamanController = TextEditingController();
  final TextEditingController keranTutupController = TextEditingController();
  final TextEditingController keranNormalController = TextEditingController();
  final TextEditingController keranBukaController = TextEditingController();
  final TextEditingController pembuanganBatasBukaController = TextEditingController();

  bool isLoading = false;
  bool isLoadingData = true;
  bool isActive = false;
  String? poolId;

  // MQTT Config Controllers
  final TextEditingController _jarakDasarController = TextEditingController();
  final TextEditingController _batasBawahController = TextEditingController();
  final TextEditingController _batasAtasController = TextEditingController();
  bool _modeAuto = true;
  bool isMqttLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is String && arguments.isNotEmpty) {
        poolId = arguments;
        fetchPoolData();
      } else {
        setState(() {
          isLoadingData = false;
          _loadError = 'ID wadah tidak ditemukan.';
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      serialController,
      namaWadahController,
      kedalamanController,
      keranTutupController,
      keranNormalController,
      keranBukaController,
      pembuanganBatasBukaController,
      _jarakDasarController,
      _batasBawahController,
      _batasAtasController
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchPoolData() async {
    setState(() {
      isLoadingData = true;
      _loadError = null;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null) throw StateError('Sesi berakhir');
      final response = await (widget.client ?? Dio()).get(
        "$baseUrl/api/pool/$poolId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (!mounted) return;
      final poolData = response.data['data'];

      serialController.text = poolData['serial'] ?? '';
      namaWadahController.text = poolData['namaWadah'] ?? '';
      kedalamanController.text = (poolData['kedalaman'] ?? 0).toString();
      keranTutupController.text = (poolData['batasIsiBerhenti'] ?? poolData['keranTutup'] ?? 0).toString();
      keranNormalController.text = (poolData['batasBuangBerhenti'] ?? poolData['keranNormal'] ?? 0).toString();
      keranBukaController.text = (poolData['batasIsiMulai'] ?? poolData['keranBuka'] ?? 0).toString();
      pembuanganBatasBukaController.text = (poolData['batasBuangMulai'] ?? poolData['pembuanganBatasBuka'] ?? 0).toString();
      isActive = poolData['isActive'] ?? false;

      setState(() => isLoadingData = false);
    } catch (e) {
      debugPrint("Error fetch pool data: $e");
      if (mounted)
        setState(() {
          isLoadingData = false;
          _loadError = 'Data wadah belum dapat dimuat. Silakan coba lagi.';
        });
    }
  }

  Future<void> sendMqttConfig() async {
    if (isLoading || isMqttLoading || !_mqttFormKey.currentState!.validate())
      return;
    FocusScope.of(context).unfocus();
    setState(() => isMqttLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final payload = {"poolId": poolId};

      if (token == null) throw StateError('Sesi berakhir');
      final response = await (widget.client ?? Dio()).post(
        "$baseUrl/api/mqtt/publish",
        data: payload,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data["success"] != true)
        throw StateError('Permintaan gagal');
      if (response.data["success"] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Konfigurasi MQTT berhasil dikirim!"),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error mqtt publish: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gagal mengirim konfigurasi"),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isMqttLoading = false);
    }
  }

  Future<void> updatePool() async {
    if (isLoading || isMqttLoading || !_formKey.currentState!.validate())
      return;
    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null) throw StateError('Sesi berakhir');
      final response = await (widget.client ?? Dio()).put(
        "$baseUrl/api/pool/$poolId",
        data: {
          "serial": serialController.text.trim(),
          "namaWadah": namaWadahController.text.trim(),
          "kedalaman": int.parse(kedalamanController.text.trim()),
          "jarakSensorDasar": int.parse(kedalamanController.text.trim()),
          "batasIsiBerhenti": int.parse(keranTutupController.text.trim()),
          "batasBuangBerhenti": int.parse(keranNormalController.text.trim()),
          "batasIsiMulai": int.parse(keranBukaController.text.trim()),
          "batasBuangMulai": int.parse(pembuanganBatasBukaController.text.trim()),
          "modeAuto": _modeAuto,
          "isActive": isActive,
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.data["success"] != true)
        throw StateError('Permintaan gagal');
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
      if (!mounted) return;
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF0878DE),
        brightness: dark ? Brightness.dark : Brightness.light);
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colors),
      child: Scaffold(
        backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
        appBar: AppBar(
          title: const Text('Edit wadah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
          foregroundColor: colors.onSurface,
          surfaceTintColor: Colors.transparent,
        ),
        body: isLoadingData
            ? Center(child: CircularProgressIndicator(color: colors.primary))
            : _loadError != null
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.cloud_off_outlined,
                              size: 40, color: colors.primary),
                          const SizedBox(height: 16),
                          Text(_loadError!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 16)),
                          if (poolId != null) ...[
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                                onPressed: fetchPoolData,
                                child: const Text('Coba lagi'))
                          ],
                        ])))
                : Center(
                    child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
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
                                  const Text(
                                      'Pengaturan tepat,\nmonitoring lebih mudah.',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          height: 1.2,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5)),
                                  const SizedBox(height: 10),
                                  const Text(
                                      'Perbarui identitas, status, dan ambang kendali wadah Anda.',
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
                              description:
                                  'Gunakan serial yang tertera pada perangkat.',
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
                                  'Atur tinggi air dalam cm untuk mulai dan berhenti mengisi maupun membuang.',
                              children: [
                                _field(colors,
                                    controller: keranTutupController,
                                    label: 'Isi berhenti',
                                    hint: 'Masukkan jarak',
                                    icon: Icons.lock_outline_rounded,
                                    numeric: true),
                                const SizedBox(height: 18),
                                _field(colors,
                                    controller: keranNormalController,
                                    label: 'Buang berhenti',
                                    hint: 'Masukkan jarak',
                                    icon: Icons.water_drop_outlined,
                                    numeric: true),
                                const SizedBox(height: 18),
                                _field(colors,
                                    controller: keranBukaController,
                                    label: 'Isi mulai',
                                    hint: 'Contoh: 30',
                                    icon: Icons.lock_open_rounded,
                                    numeric: true),
                                const SizedBox(height: 18),
                                _field(colors,
                                    controller: pembuanganBatasBukaController,
                                    label: 'Buang mulai',
                                    hint: 'Contoh: 95',
                                    icon: Icons.arrow_downward_rounded,
                                    numeric: true,
                                    last: true),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info_outline_rounded,
                                            size: 20,
                                            color: colors.onPrimaryContainer),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(
                                                'Contoh wadah 100 cm: isi mulai 30, buang berhenti 75, isi berhenti 90, buang mulai 95.',
                                                style: TextStyle(
                                                    color: colors
                                                        .onPrimaryContainer,
                                                    fontSize: 12,
                                                    height: 1.5))),
                                      ]),
                                ),
                              ]),
                          const SizedBox(height: 16),
                          _section(colors,
                              number: '03',
                              title: 'Status wadah',
                              description: 'Tentukan status aktif wadah ini.',
                              children: [
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(isActive
                                      ? 'Wadah aktif'
                                      : 'Wadah nonaktif'),
                                  value: isActive,
                                  onChanged: isLoading || isMqttLoading
                                      ? null
                                      : (value) =>
                                          setState(() => isActive = value),
                                ),
                              ]),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                                color: colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(24),
                                border:
                                    Border.all(color: colors.outlineVariant)),
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              title: const Text('Konfigurasi perangkat IoT',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              subtitle: const Text(
                                  'Pengaturan perangkat • kirim terpisah',
                                  style: TextStyle(fontSize: 12)),
                              leading: Icon(
                                  Icons.settings_input_component_outlined,
                                  color: colors.primary),
                              tilePadding: const EdgeInsets.all(16),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              children: [
                                Form(
                                    key: _mqttFormKey,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                              'Konfigurasi dikirim ke perangkat melalui MQTT. Tombol simpan perubahan hanya memperbarui data wadah.',
                                              style: TextStyle(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                  fontSize: 13,
                                                  height: 1.5)),
                                          SwitchListTile.adaptive(
                                              contentPadding: EdgeInsets.zero,
                                              title:
                                                  const Text('Mode otomatis'),
                                              value: _modeAuto,
                                              onChanged: isLoading ||
                                                      isMqttLoading
                                                  ? null
                                                  : (value) => setState(
                                                      () => _modeAuto = value)),
                                          const SizedBox(height: 12),
                                          _field(colors,
                                              controller: _jarakDasarController,
                                              label: 'Jarak dasar',
                                              hint: 'Contoh: 120',
                                              icon: Icons
                                                  .vertical_align_bottom_rounded,
                                              numeric: true,
                                              positive: true),
                                          const SizedBox(height: 18),
                                          _field(colors,
                                              controller: _batasBawahController,
                                              label: 'Batas bawah',
                                              hint: 'Contoh: 30',
                                              icon: Icons.south_rounded,
                                              numeric: true),
                                          const SizedBox(height: 18),
                                          _field(colors,
                                              controller: _batasAtasController,
                                              label: 'Batas atas',
                                              hint: 'Contoh: 85',
                                              icon: Icons.north_rounded,
                                              numeric: true),
                                          const SizedBox(height: 20),
                                          OutlinedButton(
                                            onPressed:
                                                isLoading || isMqttLoading
                                                    ? null
                                                    : sendMqttConfig,
                                            style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 12)),
                                            child: Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                spacing: 8,
                                                children: [
                                                  if (isMqttLoading)
                                                    SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: colors
                                                                    .primary))
                                                  else
                                                    const Icon(
                                                        Icons.send_outlined,
                                                        size: 18),
                                                  Text(isMqttLoading
                                                      ? 'Mengirim konfigurasi…'
                                                      : 'Kirim konfigurasi'),
                                                ]),
                                          ),
                                        ]))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
        bottomNavigationBar: isLoadingData || _loadError != null
            ? null
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Align(
                    heightFactor: 1,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                isLoading || isMqttLoading ? null : updatePool,
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
                                      isLoading
                                          ? 'Menyimpan perubahan…'
                                          : 'Simpan perubahan',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
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
      enabled: !isLoading && !isMqttLoading,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => updatePool() : null,
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
