import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'widgets/water_backdrop.dart';
import '../../constants/api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  final dio = Dio();

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    developer.log(
      'Attempting register',
      name: 'RegisterScreen',
      error: {
        'username': usernameController.text.trim(),
        'name': nameController.text.trim(),
      },
    );

    try {
      final response = await dio.post(
        "$baseUrl/api/auth/register",
        data: {
          "name": nameController.text.trim(),
          "username": usernameController.text.trim(),
          "password": passwordController.text.trim(),
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          developer.log(
            'Register successful',
            name: 'RegisterScreen',
            error: response.data,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      response.data["message"] ?? "Registrasi berhasil!",
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, "/login");
            }
          });
        } else {
          developer.log(
            'Register failed (status code)',
            name: 'RegisterScreen',
            error: response.data,
          );

          String errorMessage = "Registrasi gagal";
          if (response.data is Map) {
            errorMessage = response.data["message"] ?? errorMessage;
          } else if (response.data is String) {
            errorMessage = response.data;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(errorMessage),
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
      }
    } on DioException catch (e) {
      developer.log(
        'Register failed (DioException)',
        name: 'RegisterScreen',
        error: e,
      );

      if (mounted) {
        String errorMessage = "Gagal daftar, terjadi error";
        if (e.response?.data is Map) {
          errorMessage = e.response?.data["message"] ?? errorMessage;
        } else if (e.response?.data is String) {
          errorMessage = e.response?.data;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
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
    } catch (e) {
      developer.log(
        'Register failed (Generic)',
        name: 'RegisterScreen',
        error: e,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text("Terjadi kesalahan"),
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
                              const SizedBox(height: 64),
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
                                      const TextSpan(text: 'Buat akun\n'),
                                      TextSpan(
                                          text: 'baru.',
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
                                'Daftar untuk mulai memantau dan mengelola wadah air Anda.',
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
                                          controller: nameController,
                                          enabled: !isLoading,
                                          autofillHints: const [
                                            AutofillHints.name
                                          ],
                                          textCapitalization:
                                              TextCapitalization.words,
                                          textInputAction: TextInputAction.next,
                                          style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 16),
                                          decoration: const InputDecoration(
                                            labelText: 'Nama lengkap',
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            hintText:
                                                'Masukkan nama lengkap Anda',
                                            prefixIcon:
                                                Icon(Icons.badge_outlined),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty)
                                              return 'Nama tidak boleh kosong';
                                            if (value.trim().length < 3)
                                              return 'Nama minimal 3 karakter';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: usernameController,
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
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty)
                                              return 'Username tidak boleh kosong';
                                            if (value.trim().length < 3)
                                              return 'Username minimal 3 karakter';
                                            if (value.contains(' '))
                                              return 'Username tidak boleh mengandung spasi';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: passwordController,
                                          enabled: !isLoading,
                                          obscureText: _obscurePassword,
                                          autofillHints: const [
                                            AutofillHints.newPassword
                                          ],
                                          textInputAction: TextInputAction.done,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          onFieldSubmitted: (_) {
                                            if (!isLoading) register();
                                          },
                                          style: TextStyle(
                                              color: colors.onSurface,
                                              fontSize: 16),
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            hintText: 'Buat password Anda',
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
                                            onPressed:
                                                isLoading ? null : register,
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
                                                      ? 'Membuat akun…'
                                                      : 'Buat akun',
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
                                  Text('Sudah punya akun?',
                                      style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 14)),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.pushReplacementNamed(
                                            context, '/login'),
                                    style: TextButton.styleFrom(
                                        minimumSize: const Size(48, 48)),
                                    child: const Text('Masuk sekarang',
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
