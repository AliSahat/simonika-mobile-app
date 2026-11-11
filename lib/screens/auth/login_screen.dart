import 'dart:ui';
import 'package:flutter/material.dart';
import 'widgets/water_backdrop.dart';
import 'widgets/google_sign_in_button.dart';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';
import '../../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.googleAuthService});

  final GoogleAuthService? googleAuthService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Dio dio = Dio();
  bool isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  late final GoogleAuthService _googleAuthService =
      widget.googleAuthService ?? GoogleAuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    developer.log(
      'Attempting login',
      name: 'LoginScreen',
      error: {'username': _usernameController.text.trim()},
    );

    try {
      final response = await dio.post(
        "$baseUrl/api/auth/login",
        data: {
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim(),
        },
      );

      final data = response.data;
      final token = data["token"];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);

      developer.log(
        'Login successful',
        name: 'LoginScreen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Login berhasil!"),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pushReplacementNamed(context, "/bnav");
      }
    } catch (e) {
      developer.log(
        'Login failed',
        name: 'LoginScreen',
        error: e,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text("Login gagal, periksa kembali username/password"),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> loginWithGoogle() async {
    if (isLoading) return;
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      _isGoogleLoading = true;
    });

    try {
      final signedIn = await _googleAuthService.signIn();
      if (!signedIn || !mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Login Google berhasil!"),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacementNamed(context, "/bnav");
      }
    } catch (e) {
      final message = e is GoogleLoginException
          ? e.message
          : 'Login Google gagal. Silakan coba lagi.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.dark,
    );
    final theme = Theme.of(context).copyWith(
      brightness: Brightness.dark,
      colorScheme: colors,
      scaffoldBackgroundColor: const Color(0xFF060911),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B1120).withOpacity(0.68),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIconColor: const Color(0xFF60A5FA),
        suffixIconColor: const Color(0xFF94A3B8),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.8),
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: const Color(0xFF060911),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: const WaterBackdropPainter(dark: true),
                      ),
                    ),
                    Positioned(
                      top: -40,
                      right: -30,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF59E0B).withOpacity(0.28),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 220,
                      left: -60,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2563EB).withOpacity(0.30),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 90,
                      left: 50,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withOpacity(0.20),
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
                            color: const Color(0xFF06B6D4).withOpacity(0.25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gutter = constraints.maxWidth < 400 ? 20.0 : 32.0;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding:
                        EdgeInsets.symmetric(horizontal: gutter, vertical: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 56)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF38BDF8),
                                          Color(0xFF2563EB),
                                          Color(0xFF1E40AF),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF60A5FA)
                                            .withOpacity(0.40),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB)
                                              .withOpacity(0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.water_drop_rounded,
                                      size: 26,
                                      color: Color(0xFFF8FAFC),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SIMONIKA',
                                          style: TextStyle(
                                            color: Color(0xFFF8FAFC),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Monitoring air, lebih mudah.',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 36),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF1E40AF).withOpacity(0.55),
                                      const Color(0xFF0E7490).withOpacity(0.45),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF60A5FA)
                                        .withOpacity(0.28),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.waves_rounded,
                                      size: 19,
                                      color: Color(0xFF38BDF8),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Satu akses untuk semua wadah air Anda',
                                        style: TextStyle(
                                          color: Color(0xFFE2E8F0),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: Color(0xFF60A5FA),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              Semantics(
                                header: true,
                                child: const Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: 'Selamat datang\n'),
                                      TextSpan(
                                        text: 'kembali.',
                                        style: TextStyle(
                                          color: Color(0xFF38BDF8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    color: Color(0xFFF8FAFC),
                                    fontSize: 34,
                                    height: 1.15,
                                    letterSpacing: -1.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Masuk untuk memantau dan mengelola wadah air Anda.',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.45),
                                      blurRadius: 32,
                                      offset: const Offset(0, 14),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF2563EB)
                                          .withOpacity(0.16),
                                      blurRadius: 28,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 24, sigmaY: 24),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                          constraints.maxWidth < 400
                                              ? 18
                                              : 22),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFF1E3A8A)
                                                .withOpacity(0.38),
                                            const Color(0xFF0E7490)
                                                .withOpacity(0.24),
                                            const Color(0xFF101624)
                                                .withOpacity(0.86),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: const Color(0xFF60A5FA)
                                              .withOpacity(0.24),
                                        ),
                                      ),
                                      child: AutofillGroup(
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              TextFormField(
                                                controller: _usernameController,
                                                enabled: !isLoading,
                                                autofillHints: const [
                                                  AutofillHints.username
                                                ],
                                                textInputAction:
                                                    TextInputAction.next,
                                                autocorrect: false,
                                                style: const TextStyle(
                                                  color: Color(0xFFF8FAFC),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Username',
                                                  floatingLabelBehavior:
                                                      FloatingLabelBehavior
                                                          .never,
                                                  hintText:
                                                      'Masukkan username Anda',
                                                  prefixIcon: Icon(Icons
                                                      .person_outline_rounded),
                                                ),
                                                validator: (value) => value ==
                                                            null ||
                                                        value.trim().isEmpty
                                                    ? 'Username tidak boleh kosong'
                                                    : null,
                                              ),
                                              const SizedBox(height: 14),
                                              TextFormField(
                                                controller: _passwordController,
                                                enabled: !isLoading,
                                                obscureText: _obscurePassword,
                                                autofillHints: const [
                                                  AutofillHints.password
                                                ],
                                                textInputAction:
                                                    TextInputAction.done,
                                                autocorrect: false,
                                                enableSuggestions: false,
                                                onFieldSubmitted: (_) {
                                                  if (!isLoading) login();
                                                },
                                                style: const TextStyle(
                                                  color: Color(0xFFF8FAFC),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                decoration: InputDecoration(
                                                  labelText: 'Password',
                                                  floatingLabelBehavior:
                                                      FloatingLabelBehavior
                                                          .never,
                                                  hintText:
                                                      'Masukkan password Anda',
                                                  prefixIcon: const Icon(Icons
                                                      .lock_outline_rounded),
                                                  suffixIcon: IconButton(
                                                    tooltip: _obscurePassword
                                                        ? 'Tampilkan password'
                                                        : 'Sembunyikan password',
                                                    onPressed: isLoading
                                                        ? null
                                                        : () => setState(() =>
                                                            _obscurePassword =
                                                                !_obscurePassword),
                                                    icon: Icon(_obscurePassword
                                                        ? Icons
                                                            .visibility_outlined
                                                        : Icons
                                                            .visibility_off_outlined),
                                                  ),
                                                ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty)
                                                    return 'Password tidak boleh kosong';
                                                  if (value.length < 6)
                                                    return 'Password minimal 6 karakter';
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 20),
                                              DecoratedBox(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: isLoading
                                                        ? [
                                                            const Color(
                                                                    0xFF1E293B)
                                                                .withOpacity(
                                                                    0.8),
                                                            const Color(
                                                                    0xFF0F172A)
                                                                .withOpacity(
                                                                    0.8),
                                                          ]
                                                        : const [
                                                            Color(0xFF2563EB),
                                                            Color(0xFF1D8CF8),
                                                            Color(0xFF0EA5E9),
                                                          ],
                                                  ),
                                                  boxShadow: isLoading
                                                      ? []
                                                      : [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0xFF2563EB)
                                                                .withOpacity(
                                                                    0.38),
                                                            blurRadius: 18,
                                                            offset:
                                                                const Offset(
                                                                    0, 6),
                                                          ),
                                                        ],
                                                ),
                                                child: FilledButton(
                                                  onPressed:
                                                      isLoading ? null : login,
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    disabledBackgroundColor:
                                                        Colors.transparent,
                                                    foregroundColor:
                                                        const Color(0xFFF8FAFC),
                                                    disabledForegroundColor:
                                                        const Color(0xFF94A3B8),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 18),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                  ),
                                                  child: Wrap(
                                                    alignment:
                                                        WrapAlignment.center,
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    spacing: 12,
                                                    children: [
                                                      if (isLoading &&
                                                          !_isGoogleLoading)
                                                        const SizedBox(
                                                          height: 20,
                                                          width: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Color(
                                                                0xFF60A5FA),
                                                          ),
                                                        ),
                                                      Text(
                                                        isLoading &&
                                                                !_isGoogleLoading
                                                            ? 'Sedang masuk…'
                                                            : 'Masuk ke akun',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      if (!isLoading ||
                                                          _isGoogleLoading)
                                                        const Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          size: 20,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Divider(
                                                      color: Colors.white
                                                          .withOpacity(0.12),
                                                    ),
                                                  ),
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16),
                                                    child: Text(
                                                      'atau',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF94A3B8),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Divider(
                                                      color: Colors.white
                                                          .withOpacity(0.12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              GoogleSignInButton(
                                                isLoading: _isGoogleLoading,
                                                onPressed: isLoading
                                                    ? null
                                                    : loginWithGoogle,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: [
                                  const Text(
                                    'Belum punya akun?',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.pushNamed(
                                            context, '/register'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF60A5FA),
                                      minimumSize: const Size(48, 48),
                                    ),
                                    child: const Text(
                                      'Daftar sekarang',
                                      style: TextStyle(
                                        color: Color(0xFF60A5FA),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'SIMONIKA • Sistem Monitoring Air',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
