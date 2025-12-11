import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold adalah kerangka dasar untuk sebuah halaman
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyDompet'),
        backgroundColor: Colors.white, // Sesuaikan warnanya
        elevation: 0, // Menghilangkan bayangan
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: const Center(
        child: Text(
          'Selamat Datang di Halaman Utama!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      // Action Button untuk menambah transaksi selanjutnya
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aksi untuk menambah data
        },
        backgroundColor: Colors.yellow[700],
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
