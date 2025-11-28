import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreatePocketScreen extends StatefulWidget {
  // Kita tidak butuh callback onCreate lagi karena data langsung ke Firebase
  const CreatePocketScreen({super.key});

  @override
  State<CreatePocketScreen> createState() => _CreatePocketScreenState();
}

class _CreatePocketScreenState extends State<CreatePocketScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  bool isLoading = false; // Untuk efek loading saat menyimpan

  Future<void> savePocket() async {
    final name = nameController.text.trim();
    final balanceString = balanceController.text.trim();

    if (name.isEmpty || balanceString.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Mohon isi semua data")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final int balance = int.parse(balanceString);

        await FirebaseFirestore.instance.collection('wallets').add({
          'userId': user.uid,
          'name': name,
          'balance': balance,
          'icon': 'wallet',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Cek mounted sebelum navigasi
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // --- PERBAIKAN DI SINI ---
      // Kita cek dulu apakah widget masih "mounted" (aktif)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Kantong Baru")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nama Kantong",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Saldo Awal",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : savePocket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107), // Warna kuning tema
                  foregroundColor: Colors.black,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Simpan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
