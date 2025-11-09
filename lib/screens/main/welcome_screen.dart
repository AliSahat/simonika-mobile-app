import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fishery Icon
            Icon(Icons.water, size: 80, color: Colors.blue),

            const SizedBox(height: 32),

            const Text(
              "Selamat Datang di SIMONIKA",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            const Text(
              "Sistem Monitoring dan Kendali Air",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Container(
                  padding: const EdgeInsets.all(20), // p-5
                  decoration: BoxDecoration(
                    color: Colors.blue, // bg-blue-500
                    borderRadius: BorderRadius.circular(50), // rounded-full
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Mulai Sekarang",
                    style: TextStyle(
                      color: Colors.white, // text-white
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
