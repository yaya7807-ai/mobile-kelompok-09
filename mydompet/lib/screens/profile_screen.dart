import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        title: const Text(
          "Profil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.yellow,
              child: Icon(Icons.person, size: 55, color: Colors.black),
            ),
            const SizedBox(height: 20),

            const Text(
              "Nama",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              "Yaya Ayyash",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text(
              "Nomor Telepon",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              "0812-3456-7890",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text(
              "Total Dana",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              "Rp 5.200.000",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
