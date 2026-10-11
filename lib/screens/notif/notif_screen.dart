import 'package:flutter/material.dart';
import '../../models/water_alert.dart';
import '../../services/notification_service.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({super.key, this.service});
  final NotificationService? service;

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> {
  late final NotificationService _service =
      widget.service ?? NotificationService.instance;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
        seedColor: const Color(0xFF0878DE),
        brightness: Theme.of(context).brightness);
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colors),
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: const Text('Notifikasi'),
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          actions: [
            IconButton(
              tooltip: 'Pengaturan notifikasi',
              onPressed: () => _preferences(colors),
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListenableBuilder(
                listenable: _service,
                builder: (context, _) {
                  final items = _service.items
                      .where((item) => !_unreadOnly || !item.isRead)
                      .toList();
                  return RefreshIndicator(
                    onRefresh: _service.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        _summary(colors),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('Semua'),
                              selected: !_unreadOnly,
                              onSelected: (_) =>
                                  setState(() => _unreadOnly = false),
                            ),
                            ChoiceChip(
                              label: Text(
                                  'Belum dibaca (${_service.unreadCount})'),
                              selected: _unreadOnly,
                              onSelected: (_) =>
                                  setState(() => _unreadOnly = true),
                            ),
                            TextButton.icon(
                              onPressed: _service.unreadCount == 0
                                  ? null
                                  : _service.markAllRead,
                              icon:
                                  const Icon(Icons.done_all_rounded, size: 20),
                              label: const Text('Tandai semua dibaca'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_service.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.errorContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_service.error!,
                                    style: TextStyle(
                                        color: colors.onErrorContainer,
                                        height: 1.5)),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _service.loading
                                      ? null
                                      : _service.refresh,
                                  child: const Text('Coba lagi'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_service.loading) ...[
                          const LinearProgressIndicator(
                              semanticsLabel: 'Memeriksa kondisi wadah'),
                          const SizedBox(height: 16),
                        ],
                        if (items.isEmpty)
                          _empty(colors)
                        else
                          for (final item in items) ...[
                            _alertCard(item, colors),
                            const SizedBox(height: 12),
                          ],
                        const SizedBox(height: 16),
                        Text(
                          'Riwayat menyimpan hingga 100 notifikasi terakhir di perangkat ini. '
                          'Notifikasi adalah catatan saat kondisi terdeteksi, bukan status terkini wadah.',
                          style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(ColorScheme colors) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.notifications_active_outlined,
              color: colors.onPrimaryContainer, size: 32),
          const SizedBox(height: 16),
          Text('Tetap tahu kondisi air',
              style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
              'Peringatan diperiksa setiap 30 detik saat aplikasi terbuka. '
              'Tarik ke bawah untuk memeriksa sekarang.',
              style: TextStyle(color: colors.onPrimaryContainer, height: 1.5)),
          const SizedBox(height: 12),
          Text(
              _service.lastChecked == null
                  ? 'Belum ada pemeriksaan lengkap'
                  : 'Terakhir diperiksa ${_timestamp(_service.lastChecked!)}',
              style: TextStyle(color: colors.onPrimaryContainer, fontSize: 12)),
        ]),
      );

  Widget _empty(ColorScheme colors) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(children: [
          Icon(
              _unreadOnly
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_rounded,
              size: 56,
              color: colors.primary),
          const SizedBox(height: 16),
          Text(_unreadOnly ? 'Semua sudah dibaca' : 'Belum ada notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
              _unreadOnly
                  ? 'Pilih Semua untuk melihat riwayat peringatan.'
                  : 'Peringatan akan muncul ketika wadah aktif mencapai batas air '
                      'atau data sensor terlambat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.5)),
        ]),
      );

  Widget _alertCard(WaterAlert item, ColorScheme colors) {
    final icon = switch (item.kind) {
      WaterAlertKind.low => Icons.water_drop_outlined,
      WaterAlertKind.high => Icons.waves_rounded,
      WaterAlertKind.stale => Icons.sensors_off_rounded,
    };
    return Material(
      color: item.isRead
          ? colors.surfaceContainerLowest
          : colors.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: item.isRead
                ? colors.outlineVariant
                : colors.primary.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _service.markRead(item.id);
          Navigator.pushNamed(context, '/detail-pool', arguments: item.poolId);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: colors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(item.title,
                      style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700))),
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Semantics(
                    label: 'Belum dibaca',
                    child: Icon(Icons.circle, size: 10, color: colors.primary)),
              ],
            ]),
            const SizedBox(height: 12),
            Text(item.poolName,
                style: TextStyle(
                    color: colors.onSurface, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(item.message,
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: 16),
            Wrap(spacing: 16, runSpacing: 8, children: [
              Text(_timestamp(item.createdAt),
                  style:
                      TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
              Text('Lihat wadah →',
                  style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _preferences(ColorScheme colors) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            child: ListenableBuilder(
              listenable: _service,
              builder: (context, _) =>
                  Column(mainAxisSize: MainAxisSize.min, children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Pengaturan notifikasi',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                for (final entry in const [
                  (
                    WaterAlertKind.low,
                    'Level air rendah',
                    'Saat level mencapai batas mulai isi.'
                  ),
                  (
                    WaterAlertKind.high,
                    'Level air tinggi',
                    'Saat level mencapai batas mulai buang.'
                  ),
                  (
                    WaterAlertKind.stale,
                    'Data sensor terlambat',
                    'Tidak ada data baru selama 5 menit.'
                  ),
                ])
                  SwitchListTile.adaptive(
                    title: Text(entry.$2),
                    subtitle: Text(entry.$3),
                    value: _service.enabled(entry.$1),
                    onChanged: (value) => _service.setEnabled(entry.$1, value),
                  ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Batas air mengikuti konfigurasi setiap wadah. '
                      'Preferensi berlaku untuk peringatan baru dan tidak mengubah kendali otomatis. '
                      'Notifikasi saat aplikasi ditutup belum tersedia.',
                      style: TextStyle(fontSize: 12, height: 1.5)),
                ),
              ]),
            ),
          ),
        ),
      );

  String _timestamp(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
