import 'package:flutter/material.dart';
import '../../../models/pool_configuration.dart';

class PoolConfigurationForm extends StatelessWidget {
  const PoolConfigurationForm({
    super.key,
    required this.fields,
    required this.enabled,
    required this.modeAuto,
    required this.onModeAutoChanged,
  });

  final PoolConfigurationControllers fields;
  final bool enabled;
  final bool? modeAuto;
  final ValueChanged<bool> onModeAutoChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final validator = PoolConfigurationValidator(fields);
    return Column(children: [
      _section(colors, '01', 'Identitas', 'Nama wadah dan serial perangkat.', [
        _field(fields.namaWadah, 'Nama wadah', Icons.label_outline_rounded,
            validator: (value) => validator.requiredText(value, 'Nama wadah')),
        _gap,
        _field(fields.serial, 'Serial perangkat', Icons.qr_code_rounded,
            validator: (value) =>
                validator.requiredText(value, 'Serial perangkat')),
      ]),
      const SizedBox(height: 16),
      _section(
          colors,
          '02',
          'Ukuran dan sensor',
          'Semua ukuran dalam cm. Jarak sensor ke dasar boleh lebih besar dari kedalaman wadah bila sensor dipasang di atas bibir wadah.',
          [
            _field(
                fields.kedalaman, 'Kedalaman wadah', Icons.straighten_rounded,
                numeric: true, validator: validator.kedalaman),
            _gap,
            _field(fields.jarakSensorDasar, 'Jarak sensor ke dasar',
                Icons.vertical_align_bottom_rounded,
                numeric: true, validator: validator.jarakSensor),
          ]),
      const SizedBox(height: 16),
      _section(colors, '03', 'Pengisian',
          'Tentukan tinggi air untuk mulai dan berhenti mengisi.', [
        _field(fields.batasIsiMulai, 'Mulai isi', Icons.play_arrow_rounded,
            numeric: true, validator: validator.isiMulai),
        _gap,
        _field(fields.batasIsiBerhenti, 'Berhenti isi', Icons.stop_rounded,
            numeric: true, validator: validator.isiBerhenti),
      ]),
      const SizedBox(height: 16),
      _section(colors, '04', 'Pembuangan',
          'Tentukan tinggi air untuk mulai dan berhenti membuang.', [
        _field(fields.batasBuangMulai, 'Mulai buang', Icons.upload_rounded,
            numeric: true, validator: validator.buangMulai),
        _gap,
        _field(
            fields.batasBuangBerhenti, 'Berhenti buang', Icons.download_rounded,
            numeric: true, validator: validator.buangBerhenti),
      ]),
      const SizedBox(height: 16),
      _section(
          colors,
          '05',
          'Mode otomatis',
          'Perangkat menggunakan ambang konfigurasi saat mode otomatis aktif.',
          [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(modeAuto == null
                  ? 'Mode otomatis belum diatur'
                  : modeAuto!
                      ? 'Otomatis aktif'
                      : 'Otomatis nonaktif'),
              subtitle: Text(modeAuto == null
                  ? 'Pilih status sebelum menyimpan konfigurasi.'
                  : 'Status ini disimpan bersama konfigurasi wadah.'),
              value: modeAuto ?? false,
              onChanged: enabled ? onModeAutoChanged : null,
            ),
          ]),
    ]);
  }

  static const _gap = SizedBox(height: 18);

  Widget _field(TextEditingController controller, String label, IconData icon,
      {bool numeric = false, required FormFieldValidator<String> validator}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: numeric ? 'cm' : null,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        errorMaxLines: 3,
      ),
      validator: validator,
    );
  }

  Widget _section(ColorScheme colors, String number, String title,
      String description, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
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
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        Text(description,
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }
}
