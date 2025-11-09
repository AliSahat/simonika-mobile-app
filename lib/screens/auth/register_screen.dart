import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  final dio = Dio();

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi!")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await dio.post(
        "http://localhost:3000/api/auth/register",
        data: {
          "name": nameController.text,
          "username": usernameController.text,
          "password": passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data["message"] ?? "Registrasi berhasil"),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, "/login");
        });
      } else {
        // Kalau server balikin status selain 200
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data["message"] ?? "Registrasi gagal"),
          ),
        );
      }
    } on DioException catch (e) {
      // ✅ Ambil pesan error dari API
      final errorMessage =
          e.response?.data["message"] ?? "Gagal daftar, terjadi error";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Terjadi kesalahan")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                // Water Icon
                Center(child: Icon(Icons.water, size: 80, color: Colors.blue)),
                const SizedBox(height: 32),

                const Text(
                  "Register",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                _buildLabel("Name"),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Masukkan nama",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50), // rounded-full
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20), // p-5
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabel("Username"),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: "Masukkan username",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50), // rounded-full
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20), // p-5
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabel("Password"),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Masukkan password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50), // rounded-full
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.15),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20), // p-5
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: isLoading ? null : register,
                    child: Container(
                      padding: const EdgeInsets.all(20), // p-5
                      decoration: BoxDecoration(
                        color: isLoading
                            ? Colors.blue.shade300
                            : Colors.blue, // bg-blue-500
                        borderRadius: BorderRadius.circular(50), // rounded-full
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Register",
                                style: TextStyle(
                                  color: Colors.white, // text-white
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, "/login");
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: "Sudah punya akun? ",
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
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
        ),
      ),
    );
  }
}
