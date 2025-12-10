import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditBalanceScreen extends StatefulWidget {
  final String name;
  final int balance;
  final Future<void> Function(int newBalance) onUpdate;

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
  late TextEditingController nameController;
  late TextEditingController balanceController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);

    balanceController = TextEditingController(
      text: NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      ).format(widget.balance),
    );
  }

  // Format angka otomatis jadi 3 digit
  void _onBalanceChanged(String value) {
    String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      balanceController.value = TextEditingValue(text: "");
      return;
    }

    String formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(int.parse(clean));

    balanceController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // Simpan perubahan
  Future<void> saveWallet() async {
void saveWallet() async {
  String cleanBalance = balanceController.text.replaceAll('.', '');
  int finalBalance = int.tryParse(cleanBalance) ?? widget.balance;

  await widget.onUpdate(finalBalance);

  if (mounted && Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 235, 59),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Kelola Dompet",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nama Dompet
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown.withOpacity(0.4)),
                ),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: "Nama Dompet",
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Saldo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown.withOpacity(0.4)),
                ),
                child: TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  onChanged: _onBalanceChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: "Saldo",
                    prefixText: "Rp ",
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    backgroundColor: const Color.fromARGB(255, 255, 235, 59),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: saveWallet,
                  child: const Text(
                    "Simpan",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
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
