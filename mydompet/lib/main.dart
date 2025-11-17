import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// 1. Import file 'firebase_options.dart'
import 'firebase_options.dart';

// 2. Perbaiki import 'welcome_screen.dart' ke alamat yang benar
import 'screens/welcome_screen.dart';
// Baris 'import 'transaction_screen.dart';' dihapus karena tidak dipakai di file ini

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Aktifkan 'options' agar Firebase tahu harus konek ke mana
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 4. Kita aktifkan (uncomment) pengaturan tema ini
      title: 'MyDompet',
      debugShowCheckedModeBanner: false, // Menghilangkan banner "Debug"
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Latar belakang putih
      ),
      // Home sudah benar, mengarah ke WelcomeScreen
      home: const WelcomeScreen(),
    );
  }
}
