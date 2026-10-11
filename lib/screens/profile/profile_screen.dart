import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.client});
  final Dio? client;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  String? _username;
  String? _error;
  bool _loading = true;
  bool _fetching = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (_fetching) return;
    setState(() {
      _fetching = true;
      _loading = _name == null;
      _error = null;
    });
    try {
      final token = (await SharedPreferences.getInstance()).getString('token');
      if (token == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final response = await (widget.client ??
              Dio(BaseOptions(
                  connectTimeout: const Duration(seconds: 15),
                  receiveTimeout: const Duration(seconds: 15))))
          .get('$baseUrl/api/auth/profile',
              options: Options(headers: {'Authorization': 'Bearer $token'}));
      final user = response.data['user'] as Map;
      if (mounted)
        setState(() {
          _name = user['name']?.toString();
          _username = user['username']?.toString();
        });
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Profil belum dapat dimuat. Periksa koneksi dan coba lagi.');
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
          _fetching = false;
        });
    }
  }

  Future<void> _logout(ColorScheme colors) async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                icon: Icon(Icons.logout_rounded, color: colors.error),
                title: const Text('Keluar dari akun?'),
                content: const Text(
                    'Anda dapat masuk kembali untuk memantau dan mengelola wadah air.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                          backgroundColor: colors.error,
                          foregroundColor: colors.onError),
                      child: const Text('Keluar')),
                ],
              ));
      if (confirm != true) return;
      await (await SharedPreferences.getInstance()).remove('token');
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Belum dapat keluar. Silakan coba lagi.')));
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  String get _initials {
    final parts = (_name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    return parts.isEmpty
        ? 'U'
        : parts.map((part) => part.characters.first.toUpperCase()).join();
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
        backgroundColor: dark ? colors.surface : const Color(0xFFF3F6FA),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  _header(colors),
                  Expanded(
                    child: _loading
                        ? Center(
                            child: CircularProgressIndicator(
                                color: colors.primary))
                        : RefreshIndicator(
                            onRefresh: _fetchProfile,
                            child: ListView(
                              key: const PageStorageKey('profile-list'),
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                              children: [
                                if (_error != null) ...[
                                  _errorCard(colors),
                                  const SizedBox(height: 24),
                                ],
                                if (_name != null || _username != null) ...[
                                  _identityCard(colors),
                                  const SizedBox(height: 28),
                                  _heading(
                                      'Informasi akun',
                                      'Detail identitas Anda di SIMONIKA',
                                      colors),
                                  const SizedBox(height: 16),
                                  _surface(
                                    colors,
                                    Column(children: [
                                      _info('Nama lengkap', _displayName,
                                          Icons.badge_outlined, colors),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 20),
                                        child: Divider(
                                            height: 1,
                                            color: colors.outlineVariant
                                                .withValues(alpha: 0.6)),
                                      ),
                                      _info(
                                          'Username',
                                          _username?.trim().isNotEmpty == true
                                              ? _username!
                                              : 'Tidak tersedia',
                                          Icons.alternate_email_rounded,
                                          colors),
                                    ]),
                                  ),
                                  const SizedBox(height: 28),
                                ],
                                _heading(
                                    'Pengaturan & informasi',
                                    'Preferensi dan bantuan untuk Anda',
                                    colors),
                                const SizedBox(height: 16),
                                _settingsCard(colors),
                                const SizedBox(height: 24),
                                OutlinedButton(
                                  onPressed: _loggingOut
                                      ? null
                                      : () => _logout(colors),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.error,
                                    backgroundColor: colors.errorContainer
                                        .withValues(alpha: dark ? 0.16 : 0.25),
                                    side: BorderSide(
                                        color: colors.error
                                            .withValues(alpha: 0.18)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                  child: const Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    children: [
                                      Icon(Icons.logout_rounded, size: 20),
                                      Text('Keluar dari akun',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Icon(Icons.water_drop_outlined,
                                    size: 24, color: colors.primary),
                                const SizedBox(height: 8),
                                Text('Monitoring air, lebih mudah.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _displayName =>
      _name?.trim().isNotEmpty == true ? _name!.trim() : 'Pengguna';

  Widget _header(ColorScheme colors) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RUANG PERSONAL',
                    style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Semantics(
                  header: true,
                  child: Text('Profil saya',
                      style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8)),
                ),
              ],
            ),
          ),
        ]),
      );

  Widget _identityCard(ColorScheme colors) => Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Positioned.fill(
                  bottom: 44,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF102C4D), Color(0xFF125788)],
                      ),
                    ),
                    child: CustomPaint(painter: _WaterContourPainter()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.water_drop_rounded,
                            color: Color(0xFF8DDFF4), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('SIMONIKA / AKUN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5)),
                        ),
                      ]),
                      const SizedBox(height: 36),
                      Semantics(
                        label: 'Avatar pengguna',
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: colors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(30)),
                          child: Container(
                            constraints: const BoxConstraints(
                                minWidth: 76, minHeight: 76),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color:
                                      colors.primary.withValues(alpha: 0.16)),
                            ),
                            child: Text(_initials,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: colors.onPrimaryContainer,
                                    fontSize: 28,
                                    height: 1.8,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName,
                      style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.2)),
                  const SizedBox(height: 8),
                  Text(
                      _username?.trim().isNotEmpty == true
                          ? '@$_username'
                          : 'Username tidak tersedia',
                      style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 16,
                          height: 1.5)),
                  const SizedBox(height: 20),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Akun SIMONIKA',
                        style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border(
                    top: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.5))),
              ),
              child: Row(children: [
                Icon(Icons.waves_rounded, color: colors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Satu akun untuk setiap tetes.',
                      style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.5)),
                ),
              ]),
            ),
          ],
        ),
      );

  Widget _errorCard(ColorScheme colors) => _surface(
        colors,
        Column(children: [
          Icon(Icons.cloud_off_outlined, color: colors.primary, size: 32),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 16, height: 1.5)),
          const SizedBox(height: 12),
          FilledButton.tonal(
              onPressed: _fetching ? null : _fetchProfile,
              child: const Text('Coba lagi')),
        ]),
      );

  Widget _heading(String title, String subtitle, ColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title,
                style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 12, height: 1.5)),
        ],
      );

  Widget _surface(ColorScheme colors, Widget child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: child,
      );

  Widget _iconTile(IconData icon, ColorScheme colors, {bool muted = false}) =>
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: muted
              ? colors.surfaceContainerHigh
              : colors.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon,
            color: muted ? colors.onSurfaceVariant : colors.primary, size: 22),
      );

  Widget _info(String label, String value, IconData icon, ColorScheme colors) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _iconTile(icon, colors),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5)),
            ],
          ),
        ),
      ]);

  Widget _settingsCard(ColorScheme colors) => Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          _setting('Keamanan', 'Pengaturan kata sandi',
              Icons.lock_outline_rounded, colors),
          _settingDivider(colors),
          _setting('Notifikasi', 'Preferensi pemberitahuan',
              Icons.notifications_outlined, colors,
              onTap: () => Navigator.pushNamed(context, '/notif')),
          _settingDivider(colors),
          _setting('Bantuan', 'Pusat bantuan SIMONIKA',
              Icons.help_outline_rounded, colors),
          _settingDivider(colors),
          _setting('Tentang aplikasi', 'SIMONIKA • versi 1.0.0',
              Icons.info_outline_rounded, colors,
              onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'SIMONIKA',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(Icons.water_drop_outlined,
                        color: colors.primary, size: 40),
                    children: [
                      const Text(
                          'Sistem Monitoring dan Kendali Air. Pantau kondisi air dan kelola wadah Anda dalam satu aplikasi.'),
                    ],
                  )),
        ]),
      );

  Widget _settingDivider(ColorScheme colors) => Divider(
      height: 1,
      indent: 80,
      endIndent: 20,
      color: colors.outlineVariant.withValues(alpha: 0.6));

  Widget _setting(
      String title, String subtitle, IconData icon, ColorScheme colors,
      {VoidCallback? onTap}) {
    final pending = onTap == null;
    return Semantics(
      // Upcoming features are informational, not inactive navigation links.
      button: !pending,
      enabled: !pending,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _iconTile(icon, colors, muted: pending),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.5)),
                  if (pending) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Segera hadir',
                          style: TextStyle(
                              color: colors.onSurfaceVariant, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
            if (!pending) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(Icons.chevron_right_rounded,
                    size: 24, color: colors.onSurfaceVariant),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Quiet contour lines echo the water monitored by the app.
class _WaterContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * 0.93, size.height * 0.85);
    for (var i = 0; i < 9; i++) {
      paint.color = const Color(0xFF8DDFF4).withValues(alpha: 0.10 + i * 0.012);
      canvas.drawOval(
          Rect.fromCenter(
              center: center, width: 72 + i * 42, height: 48 + i * 28),
          paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterContourPainter oldDelegate) => false;
}
