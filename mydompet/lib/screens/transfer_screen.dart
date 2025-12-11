import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final TextEditingController amountController = TextEditingController();

  String? fromWalletId;
  String? fromWalletName;

  String? toWalletId;
  String? toWalletName;

  bool isLoading = false;

  void _onAmountChanged(String value) {
    String cleanString = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) return;
    double number = double.parse(cleanString);
    String formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(number);

    amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> pickDate() async {
    DateTime? result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: selectedDate,
    );
    if (result != null) setState(() => selectedDate = result);
  }

  Future<void> pickTime() async {
    TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (result != null) setState(() => selectedTime = result);
  }

  Future<void> saveTransfer() async {
    String cleanAmount = amountController.text.replaceAll('.', '');

    if (cleanAmount.isEmpty || fromWalletId == null || toWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi semua data")),
      );
      return;
    }

    if (fromWalletId == toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Dompet asal dan tujuan tidak boleh sama"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final int amount = int.parse(cleanAmount);

      final DateTime fullDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference fromRef = FirebaseFirestore.instance
            .collection('wallets')
            .doc(fromWalletId);
        DocumentReference toRef = FirebaseFirestore.instance
            .collection('wallets')
            .doc(toWalletId);

        DocumentSnapshot fromSnapshot = await transaction.get(fromRef);
        DocumentSnapshot toSnapshot = await transaction.get(toRef);

        if (!fromSnapshot.exists || !toSnapshot.exists) {
          throw Exception("Salah satu kantong tidak ditemukan!");
        }

        int sourceBalance = fromSnapshot['balance'] ?? 0;
        int destBalance = toSnapshot['balance'] ?? 0;

        if (sourceBalance < amount) {
          throw Exception("Saldo di ${fromSnapshot['name']} tidak mencukupi!");
        }

        int newSourceBalance = sourceBalance - amount;
        int newDestBalance = destBalance + amount;

        transaction.update(fromRef, {'balance': newSourceBalance});
        transaction.update(toRef, {'balance': newDestBalance});

        DocumentReference newTransRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc();

        transaction.set(newTransRef, {
          'userId': user?.uid,
          'judul': "Transfer ke $toWalletName",
          'jumlah': amount,
          'kategori': 'Transfer',
          'walletId': fromWalletId, // Kita link ke dompet pengirim
          'walletName': fromWalletName,
          'toWalletId': toWalletId, // Info tambahan
          'toWalletName': toWalletName, // Info tambahan
          'tipe': 'pindah_saldo', // Tipe khusus
          'createdAt': Timestamp.fromDate(fullDateTime),
        });
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil memindahkan saldo")),
        );
      }
    } catch (e) {
      String errorMsg = e.toString().replaceAll("Exception: ", "");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          "Pindah Saldo",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: pickDate,
                      child: _buildBox(
                        DateFormat(
                          "EEE, dd MMM yyyy",
                          "id_ID",
                        ).format(selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: pickTime,
                    child: _buildBox(
                      "${selectedTime.hour.toString().padLeft(2, '0')} : ${selectedTime.minute.toString().padLeft(2, '0')}",
                      width: 85,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('wallets')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Siapkan List untuk Dropdown
                  List<DropdownMenuItem<String>> walletItems = [];

                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      //"Nama Kantong (Rp 100.000)" supaya user tahu saldonya
                      String formattedBal = NumberFormat.compactCurrency(
                        locale: 'id_ID',
                        symbol: 'Rp',
                        decimalDigits: 0,
                      ).format(data['balance']);

                      walletItems.add(
                        DropdownMenuItem(
                          value: doc.id,
                          child: Text(
                            "${data['name']} ($formattedBal)",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    }
                  }

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.brown.withOpacity(0.4),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: "Sumber Dana",
                          ),
                          value: fromWalletId,
                          items: walletItems,
                          onChanged: (value) {
                            setState(() {
                              fromWalletId = value;
                              var doc = snapshot.data!.docs.firstWhere(
                                (d) => d.id == value,
                              );
                              fromWalletName = doc['name'];
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.brown.withOpacity(0.4),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: "Tujuan Transfer",
                          ),
                          value: toWalletId,
                          items: walletItems,
                          onChanged: (value) {
                            setState(() {
                              toWalletId = value;
                              var doc = snapshot.data!.docs.firstWhere(
                                (d) => d.id == value,
                              );
                              toWalletName = doc['name'];
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 15),

              _buildTextField(
                "Jumlah yang dipindah",
                amountController,
                isNumber: true,
              ),
              const SizedBox(height: 25),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    backgroundColor: const Color.fromARGB(255, 255, 235, 59),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : saveTransfer,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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

  Widget _buildBox(String text, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: Colors.brown.withOpacity(0.4)),
      ),
      child: Text(
        text,
        textAlign: width != null ? TextAlign.center : TextAlign.start,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.withOpacity(0.4)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onChanged: isNumber ? _onAmountChanged : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixText: isNumber ? "Rp " : null,
        ),
      ),
    );
  }
}
