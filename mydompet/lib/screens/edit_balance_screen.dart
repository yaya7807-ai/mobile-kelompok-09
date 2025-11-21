import 'package:flutter/material.dart';

class EditBalanceScreen extends StatefulWidget {
  final String name;
  final int balance;
  final Function(int) onUpdate;

  const EditBalanceScreen({
    super.key,
    required this.name,
    required this.balance,
    required this.onUpdate,
  });

  @override
  State<EditBalanceScreen> createState() => _EditBalanceScreenState();
}

class _EditBalanceScreenState extends State<EditBalanceScreen> {
  TextEditingController amountController = TextEditingController();

  void updateBalance(bool isAdd) {
    int value = int.tryParse(amountController.text) ?? 0;
    if (value <= 0) return;

    int newBalance = isAdd ? widget.balance + value : widget.balance - value;

    if (newBalance < 0) newBalance = 0;

    widget.onUpdate(newBalance);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kelola ${widget.name}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Saldo Saat Ini: Rp ${widget.balance}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Masukkan jumlah",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => updateBalance(true),
                    child: const Text("Tambah"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => updateBalance(false),
                    child: const Text("Kurangi"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
