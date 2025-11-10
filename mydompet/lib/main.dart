import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // warna pink lembut
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gambar bintang
              Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200, // ubah sesuai ukuran logo kamu
              ),

              const SizedBox(height: 40),

              // Teks utama
              const Text(
                'KELOLA KEUANGAN\nDAN JANGAN JUDI ONLINE ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1,
                ),
              ),

              const SizedBox(height: 200),

              // Tombol
              ElevatedButton(
                onPressed: () {
                  // aksi ketika tombol ditekan
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD300), // kuning
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.black),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Ayo Kita Mulai',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
