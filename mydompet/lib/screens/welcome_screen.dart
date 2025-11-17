import 'package:flutter/material.dart';
// 1. IMPORT file home_screen.dart YANG BARU KITA BUAT
import 'package:mydompet/screens/home_screen.dart'; // <-- Sesuaikan 'mydompet' dengan nama paket Anda

class WelcomeScreen extends StatelessWidget {
  // ... (kode di atas sini tidak berubah) ...
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
              // ... (Bagian atas: logo dan teks tidak berubah) ...
              Column(
                children: [
                  // Path-nya langsung dari root proyek
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
                    // Ini adalah kode untuk berpindah halaman
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  // ... (bagian style: warna, bentuk, dll tidak berubah) ...
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
