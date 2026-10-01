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
        brightness: dark ? Brightness.dark : Brightness.light);
    return Theme(
        data: Theme.of(context).copyWith(colorScheme: colors),
        child: Scaffold(
          backgroundColor: dark ? colors.surface : const Color(0xFFF5F9FE),
          body: SafeArea(
              bottom: false,
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(children: [
                        Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                            child: Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(14)),
                                  child: Icon(Icons.person_outline_rounded,
                                      color: colors.onPrimaryContainer,
                                      size: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Semantics(
                                      header: true,
                                      child: Text('Profil saya',
                                          style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5)))),
                              IconButton(
                                  tooltip: 'Perbarui profil',
                                  onPressed: _fetching ? null : _fetchProfile,
                                  icon: _fetching
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: colors.primary))
                                      : Icon(Icons.refresh_rounded,
                                          color: colors.primary)),
                            ])),
                        Expanded(
                            child: _loading
                                ? Center(
                                    child: CircularProgressIndicator(
                                        color: colors.primary))
                                : ListView(
                                    key: const PageStorageKey('profile-list'),
                                    physics: const ClampingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 8, 20, 32),
                                    children: [
                                        if (_error != null) ...[
                                          _surface(
                                              colors,
                                              Column(children: [
                                                Icon(Icons.cloud_off_outlined,
                                                    color: colors.primary,
                                                    size: 32),
                                                const SizedBox(height: 12),
                                                Text(_error!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: colors
                                                            .onSurfaceVariant,
                                                        fontSize: 14,
                                                        height: 1.5)),
                                                const SizedBox(height: 12),
                                                FilledButton.tonal(
                                                    onPressed: _fetchProfile,
                                                    child:
                                                        const Text('Coba lagi'))
                                              ])),
                                          const SizedBox(height: 16),
                                        ],
                                        if (_name != null ||
                                            _username != null) ...[
                                          Container(
                                              padding: const EdgeInsets.all(24),
                                              decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                        Color(0xFF168EED),
                                                        Color(0xFF0865B5),
                                                        Color(0xFF154675)
                                                      ]),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          24)),
                                              child: Column(children: [
                                                Semantics(
                                                    label: 'Avatar pengguna',
                                                    child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                                4),
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: Colors.white.withValues(
                                                                    alpha: 0.4),
                                                                width: 2)),
                                                        child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                    20),
                                                            decoration: BoxDecoration(
                                                                color: Colors.white
                                                                    .withValues(
                                                                        alpha: 0.18),
                                                                shape: BoxShape.circle),
                                                            child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))))),
                                                const SizedBox(height: 16),
                                                Text(
                                                    _name?.trim().isNotEmpty ==
                                                            true
                                                        ? _name!
                                                        : 'Pengguna',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        height: 1.3)),
                                                const SizedBox(height: 6),
                                                Text(
                                                    _username == null
                                                        ? 'Username tidak tersedia'
                                                        : '@$_username',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFFE4F2FF),
                                                        fontSize: 14,
                                                        height: 1.5)),
                                                const SizedBox(height: 16),
                                                const Text('Akun SIMONIKA',
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFFE4F2FF),
                                                        fontSize: 12,
                                                        letterSpacing: 0.5)),
                                              ])),
                                          const SizedBox(height: 24),
                                          _heading('Informasi akun', colors),
                                          const SizedBox(height: 12),
                                          _surface(
                                              colors,
                                              Column(children: [
                                                _info(
                                                    'Nama lengkap',
                                                    _name ?? 'Tidak tersedia',
                                                    Icons.badge_outlined,
                                                    colors),
                                                Divider(
                                                    height: 28,
                                                    color:
                                                        colors.outlineVariant),
                                                _info(
                                                    'Username',
                                                    _username ??
                                                        'Tidak tersedia',
                                                    Icons
                                                        .alternate_email_rounded,
                                                    colors),
                                              ])),
                                          const SizedBox(height: 24),
                                        ],
                                        _heading(
                                            'Pengaturan & informasi', colors),
                                        const SizedBox(height: 12),
                                        Material(
                                            color:
                                                colors.surfaceContainerLowest,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                side: BorderSide(
                                                    color:
                                                        colors.outlineVariant)),
                                            clipBehavior: Clip.antiAlias,
                                            child: Column(children: [
                                              _pending(
                                                  'Keamanan',
                                                  'Pengaturan kata sandi • segera hadir',
                                                  Icons.lock_outline_rounded,
                                                  colors),
                                              Divider(
                                                  height: 1,
                                                  indent: 56,
                                                  endIndent: 16,
                                                  color: colors.outlineVariant),
                                              _pending(
                                                  'Notifikasi',
                                                  'Preferensi notifikasi • segera hadir',
                                                  Icons.notifications_outlined,
                                                  colors),
                                              Divider(
                                                  height: 1,
                                                  indent: 56,
                                                  endIndent: 16,
                                                  color: colors.outlineVariant),
                                              _pending(
                                                  'Bantuan',
                                                  'Pusat bantuan • segera hadir',
                                                  Icons.help_outline_rounded,
                                                  colors),
                                              Divider(
                                                  height: 1,
                                                  indent: 56,
                                                  endIndent: 16,
                                                  color: colors.outlineVariant),
                                              ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 6),
                                                leading: Icon(
                                                    Icons.info_outline_rounded,
                                                    color: colors.primary),
                                                title: Text('Tentang aplikasi',
                                                    style: TextStyle(
                                                        color: colors.onSurface,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                subtitle: Text(
                                                    'SIMONIKA • versi 1.0.0',
                                                    style: TextStyle(
                                                        color: colors
                                                            .onSurfaceVariant,
                                                        fontSize: 12)),
                                                trailing: Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: colors
                                                        .onSurfaceVariant),
                                                onTap: () => showAboutDialog(
                                                    context: context,
                                                    applicationName: 'SIMONIKA',
                                                    applicationVersion: '1.0.0',
                                                    applicationIcon: Icon(
                                                        Icons
                                                            .water_drop_outlined,
                                                        color: colors.primary,
                                                        size: 40),
                                                    children: [
                                                      const Text(
                                                          'Sistem Monitoring dan Kendali Air. Pantau kondisi air dan kelola wadah Anda dalam satu aplikasi.')
                                                    ]),
                                              ),
                                            ])),
                                        const SizedBox(height: 24),
                                        OutlinedButton(
                                            onPressed: _loggingOut
                                                ? null
                                                : () => _logout(colors),
                                            style: OutlinedButton.styleFrom(
                                                foregroundColor: colors.error,
                                                side: BorderSide(
                                                    color: colors.error
                                                        .withValues(
                                                            alpha: 0.4)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 18),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16))),
                                            child: const Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                spacing: 10,
                                                children: [
                                                  Icon(Icons.logout_rounded,
                                                      size: 20),
                                                  Text('Keluar dari akun',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700))
                                                ])),
                                        const SizedBox(height: 20),
                                        Text('Monitoring air, lebih mudah.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: colors.onSurfaceVariant,
                                                fontSize: 12)),
                                      ])),
                      ])))),
        ));
  }

  Widget _heading(String title, ColorScheme colors) => Semantics(
      header: true,
      child: Text(title,
          style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700)));
  Widget _surface(ColorScheme colors, Widget child) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.7))),
      child: child);
  Widget _info(String label, String value, IconData icon, ColorScheme colors) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: colors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4))
        ]))
      ]);
  Widget _pending(
          String title, String subtitle, IconData icon, ColorScheme colors) =>
      ListTile(
          enabled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Icon(icon, color: colors.onSurfaceVariant),
          title: Text(title,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15)),
          subtitle: Text(subtitle,
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 12, height: 1.5)));
}
