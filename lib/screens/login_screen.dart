import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Dio dio = Dio();
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);

    try {
      final response = await dio.post(
        "http://localhost:3000/api/auth/login",
        data: {
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim(),
        },
      );

      final data = response.data;
      final token = data["token"];

      // simpan token ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Login berhasil!")),
      );

      Navigator.pushReplacementNamed(context, "/bnav");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Login gagal, periksa kembali username/password")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Label + Username Field
                _buildLabel("Username"),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Masukkan username",
                  ),
                ),
                const SizedBox(height: 20),

                // Label + Password Field
                _buildLabel("Password"),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Masukkan password",
                  ),
                ),
                const SizedBox(height: 28),

// Login Button - Tailwind style
GestureDetector(
  onTap: isLoading ? null : login,
  child: Container(
    width: double.infinity, // w-full
    padding: const EdgeInsets.all(20), // p-5 (5 x 4px = 20px)
    decoration: BoxDecoration(
      color: isLoading ? Colors.blue.shade300 : Colors.blue, // bg-blue-500
      borderRadius: BorderRadius.circular(999), // rounded-full
    ),
    child: Center(
      child: Text(
        isLoading ? "Loading..." : "Login",
        style: const TextStyle(
          color: Colors.white, // text-white
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
),


                const SizedBox(height: 24),

                // Sudah punya akun? register
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, "/register"),
                    child: const Text.rich(
                      TextSpan(
                        text: "Belum punya akun? ",
                        children: [
                          TextSpan(
                            text: "Daftar",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
