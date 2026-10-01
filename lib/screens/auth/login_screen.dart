import 'package:flutter/material.dart';
import 'widgets/water_backdrop.dart';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Dio dio = Dio();
  bool isLoading = false;
  bool _obscurePassword = true;

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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0878DE),
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    final theme = Theme.of(context).copyWith(
      colorScheme: colors,
      scaffoldBackgroundColor: dark ? colors.surface : const Color(0xFFF7FBFF),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            dark ? colors.surfaceContainerLowest : const Color(0xFFF8FBFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIconColor: colors.primary,
        suffixIconColor: colors.onSurfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: dark ? colors.outline : const Color(0xFFDCEBFA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: WaterBackdropPainter(dark: dark)),
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
                        EdgeInsets.symmetric(horizontal: gutter, vertical: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 64)
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
                                          Color(0xFF44BFFF),
                                          Color(0xFF0877D9),
                                          Color(0xFF124A88)
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                            color: colors.primary
                                                .withValues(alpha: 0.22),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6))
                                      ],
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(Icons.water_drop_outlined,
                                        size: 28, color: colors.onPrimary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('SIMONIKA',
                                            style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.6,
                                            )),
                                        const SizedBox(height: 4),
                                        Text('Monitoring air, lebih mudah.',
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontSize: 12,
                                            )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 88),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: dark
                                      ? colors.primaryContainer
                                      : const Color(0xFFE1F1FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.waves_outlined,
                                        size: 20,
                                        color: colors.onPrimaryContainer),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Text(
                                      'Satu akses untuk semua wadah air Anda',
                                      style: TextStyle(
                                          color: colors.onPrimaryContainer,
                                          fontSize: 13,
                                          height: 1.5),
                                    )),
                                    Icon(Icons.chevron_right_rounded,
                                        size: 20, color: colors.primary),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Semantics(
                                header: true,
                                child: Text.rich(
                                    TextSpan(children: [
                                      const TextSpan(text: 'Selamat datang\n'),
                                      TextSpan(
                                          text: 'kembali.',
                                          style: TextStyle(
                                              color: dark
                                                  ? colors.primary
                                                  : const Color(0xFF0878DE))),
                                    ]),
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 36,
                                      height: 1.15,
                                      letterSpacing: -1.2,
                                      fontWeight: FontWeight.w800,
                                    )),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Masuk untuk memantau dan mengelola wadah air Anda.',
                                style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 16,
                                    height: 1.5),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.all(
                                    constraints.maxWidth < 400 ? 16 : 20),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: dark
                                          ? colors.outlineVariant
                                          : const Color(0xFFE4EFFA)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.shadow.withValues(
                                          alpha: dark ? 0.12 : 0.04),
                                      blurRadius: 32,
                                      offset: const Offset(0, 12),
                                    )
                                  ],
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
                                          textInputAction: TextInputAction.next,
                                          autocorrect: false,
                                          style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 16),
                                          decoration: const InputDecoration(
                                            labelText: 'Username',
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            hintText: 'Masukkan username Anda',
                                            prefixIcon: Icon(
                                                Icons.person_outline_rounded),
                                          ),
                                          validator: (value) => value == null ||
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
                                          textInputAction: TextInputAction.done,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          onFieldSubmitted: (_) {
                                            if (!isLoading) login();
                                          },
                                          style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 16),
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            hintText: 'Masukkan password Anda',
                                            prefixIcon: const Icon(
                                                Icons.lock_outline_rounded),
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
                                                  ? Icons.visibility_outlined
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
                                                      colors
                                                          .surfaceContainerHighest,
                                                      colors
                                                          .surfaceContainerHighest
                                                    ]
                                                  : const [
                                                      Color(0xFF229DFA),
                                                      Color(0xFF0873CA),
                                                      Color(0xFF124577)
                                                    ],
                                            ),
                                            boxShadow: isLoading
                                                ? []
                                                : [
                                                    BoxShadow(
                                                        color: colors.primary
                                                            .withValues(
                                                                alpha: 0.24),
                                                        blurRadius: 16,
                                                        offset:
                                                            const Offset(0, 6))
                                                  ],
                                          ),
                                          child: FilledButton(
                                            onPressed: isLoading ? null : login,
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16)),
                                            ),
                                            child: Wrap(
                                              alignment: WrapAlignment.center,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 12,
                                              children: [
                                                if (isLoading)
                                                  SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: colors
                                                            .onSurfaceVariant),
                                                  ),
                                                Text(
                                                  isLoading
                                                      ? 'Sedang masuk…'
                                                      : 'Masuk ke akun',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                                if (!isLoading)
                                                  const Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: [
                                  Text('Belum punya akun?',
                                      style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 14)),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.pushNamed(
                                            context, '/register'),
                                    style: TextButton.styleFrom(
                                        minimumSize: const Size(48, 48)),
                                    child: const Text('Daftar sekarang',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'SIMONIKA • Sistem Monitoring Air',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12,
                                    letterSpacing: 0.3),
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
