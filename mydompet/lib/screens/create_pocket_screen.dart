import 'package:flutter/material.dart';

class CreatePocketScreen extends StatefulWidget {
  final Function(String, int) onCreate;

  const CreatePocketScreen({super.key, required this.onCreate});

  @override
  State<CreatePocketScreen> createState() => _CreatePocketScreenState();
}

class _CreatePocketScreenState extends State<CreatePocketScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController balanceController = TextEditingController();

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

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final bal = int.tryParse(balanceController.text) ?? 0;

                if (name.isEmpty) return;

                widget.onCreate(name, bal);
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }
}
