import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Import file halaman welcome screen yang baru kita buat
import 'package:mydompet/screens/welcome_screen.dart'; // <-- Ganti 'mydompet' dengan nama proyek Anda

// Fungsi main() sekarang 'async' karena kita perlu 'await' Firebase
Future<void> main() async {
  // Pastikan semua binding Flutter siap sebelum menjalankan Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Jika Anda menggunakan FlutterFire CLI
  );

  // Menjalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDompet',
      debugShowCheckedModeBanner: false, // Menghilangkan banner "Debug"
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Latar belakang putih
      ),
      // Di sinilah kita memberi tahu aplikasi untuk memulai dengan WelcomeScreen
      home: const WelcomeScreen(),
    );
  }
}
