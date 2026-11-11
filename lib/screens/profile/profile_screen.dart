import 'dart:ui';
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
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.dark,
    );
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        colorScheme: colors,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF060911),
        extendBody: true,
        body: Stack(
          children: [
            IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -30,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF59E0B).withOpacity(0.32),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 220,
                    left: -70,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2563EB).withOpacity(0.28),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: 60,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withOpacity(0.22),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    right: -30,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                      child: Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF06B6D4).withOpacity(0.26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      _header(colors),
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF3B82F6)))
                            : RefreshIndicator(
                                onRefresh: _fetchProfile,
                                color: const Color(0xFF3B82F6),
                                backgroundColor: const Color(0xFF121826),
                                child: ListView(
                                  key: const PageStorageKey('profile-list'),
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 8, 20, 110),
                                  children: [
                                    if (_error != null) ...[
                                      _errorCard(colors),
                                      const SizedBox(height: 24),
                                    ],
                                    if (_name != null ||
                                        _username != null) ...[
                                      _identityCard(colors),
                                      const SizedBox(height: 24),
                                      _heading(
                                          'Informasi akun',
                                          'Detail identitas Anda di SIMONIKA',
                                          colors),
                                      const SizedBox(height: 14),
                                      _surface(
                                        colors,
                                        Column(children: [
                                          _info(
                                              'Nama lengkap',
                                              _displayName,
                                              Icons.badge_outlined,
                                              colors,
                                              accent: const Color(0xFF3B82F6)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 18),
                                            child: Divider(
                                                height: 1,
                                                color: Colors.white
                                                    .withOpacity(0.08)),
                                          ),
                                          _info(
                                              'Username',
                                              _username?.trim().isNotEmpty ==
                                                      true
                                                  ? _username!
                                                  : 'Tidak tersedia',
                                              Icons.alternate_email_rounded,
                                              colors,
                                              accent: const Color(0xFF06B6D4)),
                                        ]),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                    _heading(
                                        'Pengaturan & informasi',
                                        'Preferensi dan bantuan untuk Anda',
                                        colors),
                                    const SizedBox(height: 14),
                                    _settingsCard(colors),
                                    const SizedBox(height: 24),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444)
                                                .withOpacity(0.18),
                                            blurRadius: 20,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: OutlinedButton(
                                        onPressed: _loggingOut
                                            ? null
                                            : () => _logout(colors),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFF87171),
                                          backgroundColor:
                                              const Color(0xFFEF4444)
                                                  .withOpacity(0.14),
                                          side: BorderSide(
                                              color: const Color(0xFFF87171)
                                                  .withOpacity(0.32)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 16),
                                          shape: const StadiumBorder(),
                                        ),
                                        child: const Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 10,
                                          children: [
                                            Icon(Icons.logout_rounded,
                                                size: 20,
                                                color: Color(0xFFF87171)),
                                            Text('Keluar dari akun',
                                                style: TextStyle(
                                                    color: Color(0xFFF87171),
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    const Icon(Icons.water_drop_outlined,
                                        size: 24, color: Color(0xFF38BDF8)),
                                    const SizedBox(height: 8),
                                    const Text('Monitoring air, lebih mudah.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Color(0xFF94A3B8),
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
          ],
        ),
      ),
    );
  }

  String get _displayName =>
      _name?.trim().isNotEmpty == true ? _name!.trim() : 'Pengguna';

  Widget _header(ColorScheme colors) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RUANG PERSONAL',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Semantics(
                  header: true,
                  child: const Text(
                    'Profil saya',
                    style: TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      );

  Widget _identityCard(ColorScheme colors) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.42),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF17253B).withOpacity(0.82),
                    const Color(0xFF101624).withOpacity(0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.09),
                  width: 1.0,
                ),
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
                              colors: [
                                Color(0xFF102A4C),
                                Color(0xFF1D4ED8),
                              ],
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
                                  color: Color(0xFF93C5FD), size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('SIMONIKA / AKUN',
                                    style: TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.4)),
                              ),
                            ]),
                            const SizedBox(height: 32),
                            Semantics(
                              label: 'Avatar pengguna',
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(
                                      minWidth: 74, minHeight: 74),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                        color: const Color(0xFF3B82F6)
                                            .withOpacity(0.35)),
                                  ),
                                  child: Text(
                                    _initials,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFF8FAFC),
                                      fontSize: 26,
                                      height: 1.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _username?.trim().isNotEmpty == true
                              ? '@$_username'
                              : 'Username tidak tersedia',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color:
                                  const Color(0xFF3B82F6).withOpacity(0.28),
                            ),
                          ),
                          child: const Text(
                            'Akun SIMONIKA',
                            style: TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.07)),
                      ),
                    ),
                    child: const Row(children: [
                      Icon(Icons.waves_rounded,
                          color: Color(0xFF60A5FA), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Satu akun untuk setiap tetes.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _errorCard(ColorScheme colors) => _surface(
        colors,
        Column(children: [
          const Icon(Icons.cloud_off_outlined,
              color: Color(0xFFF87171), size: 32),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: _fetching ? null : _fetchProfile,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: const Color(0xFFF8FAFC),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Coba lagi',
              style: TextStyle(color: Color(0xFFF8FAFC)),
            ),
          ),
        ]),
      );

  Widget _heading(String title, String subtitle, ColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      );

  Widget _surface(ColorScheme colors, Widget child,
          {EdgeInsetsGeometry padding = const EdgeInsets.all(20)}) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF181F30).withOpacity(0.76),
                    const Color(0xFF101624).withOpacity(0.66),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.09),
                  width: 1.0,
                ),
              ),
              child: child,
            ),
          ),
        ),
      );

  Widget _iconTile(IconData icon, ColorScheme colors,
      {bool muted = false, Color accent = const Color(0xFF3B82F6)}) {
    final bg = muted
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF2563EB).withOpacity(0.15);
    final fg = muted ? const Color(0xFF94A3B8) : const Color(0xFF60A5FA);
    final border = muted
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFF3B82F6).withOpacity(0.28);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Icon(icon, color: fg, size: 22),
    );
  }

  Widget _info(String label, String value, IconData icon, ColorScheme colors,
          {Color accent = const Color(0xFF3B82F6)}) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _iconTile(icon, colors, accent: accent),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ]);

  Widget _settingsCard(ColorScheme colors) => _surface(
        colors,
        padding: EdgeInsets.zero,
        Material(
          color: Colors.transparent,
          child: Column(children: [
            _setting(
              'Keamanan',
              'Pengaturan kata sandi',
              Icons.lock_outline_rounded,
              colors,
            ),
            _settingDivider(colors),
            _setting(
              'Notifikasi',
              'Preferensi pemberitahuan',
              Icons.notifications_outlined,
              colors,
              onTap: () => Navigator.pushNamed(context, '/notif'),
            ),
            _settingDivider(colors),
            _setting(
              'Bantuan',
              'Pusat bantuan SIMONIKA',
              Icons.help_outline_rounded,
              colors,
            ),
            _settingDivider(colors),
            _setting(
              'Tentang aplikasi',
              'SIMONIKA • versi 1.0.0',
              Icons.info_outline_rounded,
              colors,
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'SIMONIKA',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.water_drop_outlined,
                    color: Color(0xFF60A5FA), size: 40),
                children: const [
                  Text(
                      'Sistem Monitoring dan Kendali Air. Pantau kondisi air dan kelola wadah Anda dalam satu aplikasi.'),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _settingDivider(ColorScheme colors) => Divider(
      height: 1,
      indent: 80,
      endIndent: 20,
      color: Colors.white.withOpacity(0.07));

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
                  Text(
                    title,
                    style: TextStyle(
                      color: pending
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFFF8FAFC),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (pending) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: const Text(
                        'Segera hadir',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!pending) ...[
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(Icons.chevron_right_rounded,
                    size: 24, color: Color(0xFF94A3B8)),
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
      paint.color = const Color(0xFF8DDFF4).withOpacity(0.10 + i * 0.012);
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
