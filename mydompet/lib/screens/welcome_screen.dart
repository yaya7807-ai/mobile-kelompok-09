import 'package:flutter/material.dart';
// 1. IMPORT file transaction_screen.dart, BUKAN home_screen.dart
// Kita pakai path relatif (langsung) karena filenya ada di folder yang sama ('screens')
import 'transaction_screen.dart'; // <-- PERUBAHAN DI SINI

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Bagian atas: logo dan teks
              Column(
                children: [
                  // PASTIKAN kamu sudah setup 'assets/images/logo.png' di pubspec.yaml
                  Image.asset('assets/images/logo.png', width: 200),
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),
                  const Text(
                    "KELOLA KEUANGAN\nDAN JANGAN JUDI ONLINE",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              // Bagian bawah (Tombol)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // 2. MODIFIKASI BAGIAN INI
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        // Arahkan ke TransactionScreen(), BUKAN HomeScreen()
                        builder: (context) =>
                            const TransactionScreen(), // <-- PERUBAHAN DI SINI
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Ayo Kita Mulai",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
