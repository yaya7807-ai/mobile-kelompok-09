import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  // Kita simpan ID Kantong dan Nama Kantong
  String? selectedWalletId;
  String? selectedWalletName;

  bool isLoading = false;

  // --- FORMATTER RUPIAH SAAT MENGETIK ---
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

  // --- FUNGSI PICK DATE & TIME ---
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

  // --- FUNGSI SIMPAN KE FIREBASE ---
  Future<void> saveIncome() async {
    // 1. Validasi Input
    String cleanAmount = amountController.text.replaceAll('.', '');
    if (titleController.text.isEmpty ||
        cleanAmount.isEmpty ||
        selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi semua data")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final int amount = int.parse(cleanAmount);

      // Gabungkan Date dan Time menjadi satu DateTime utuh
      final DateTime fullDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // 2. JALANKAN TRANSAKSI DATABASE (ATOMIC)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // A. Ambil Referensi Dokumen Kantong
        DocumentReference walletRef = FirebaseFirestore.instance
            .collection('wallets')
            .doc(selectedWalletId);

        // B. Baca Data Kantong Terbaru (Snapshot)
        DocumentSnapshot walletSnapshot = await transaction.get(walletRef);

        if (!walletSnapshot.exists) {
          throw Exception("Kantong tidak ditemukan!");
        }

        // C. Hitung Saldo Baru (Saldo Lama + Pemasukan Baru)
        int currentBalance = walletSnapshot['balance'] ?? 0;
        int newBalance = currentBalance + amount;

        // D. Update Saldo di Database
        transaction.update(walletRef, {'balance': newBalance});

        // E. Buat Dokumen Transaksi Baru
        DocumentReference newTransRef = FirebaseFirestore.instance
            .collection('transactions') // Koleksi baru khusus transaksi
            .doc();

        transaction.set(newTransRef, {
          'userId': user?.uid,
          'judul': titleController.text,
          'jumlah': amount,
          'kategori': categoryController.text.isEmpty
              ? 'Lainnya'
              : categoryController.text,
          'tipe': 'pemasukan',
          'walletId': selectedWalletId,
          'walletName': selectedWalletName,
          'createdAt': Timestamp.fromDate(
            fullDateTime,
          ), // Simpan waktu yang dipilih user
        });
      });

      // 3. Sukses
      if (mounted) {
        Navigator.pop(context, true); // Kembali dengan sinyal sukses
      }
    } catch (e) {
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
          "Pemasukan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DATE PICKER UI (Sama seperti sebelumnya)
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

              // ================= DROPDOWN KANTONG DARI FIREBASE =================
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('wallets')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildBox("Memuat Kantong..."); // Loading state
                  }

                  List<DropdownMenuItem<String>> walletItems = [];
                  for (var doc in snapshot.data!.docs) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    walletItems.add(
                      DropdownMenuItem(
                        value: doc.id, // Value-nya adalah ID dokumen
                        child: Text(data['name']), // Tampilannya adalah Nama
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown.withOpacity(0.4)),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      hint: const Text("Pilih Kantong"),
                      value: selectedWalletId,
                      items: walletItems,
                      onChanged: (value) {
                        setState(() {
                          selectedWalletId = value;
                          // Cari nama kantong berdasarkan ID untuk disimpan juga
                          var selectedDoc = snapshot.data!.docs.firstWhere(
                            (doc) => doc.id == value,
                          );
                          selectedWalletName = selectedDoc['name'];
                        });
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),
              _buildTextField("Jumlah", amountController, isNumber: true),
              const SizedBox(height: 15),
              _buildTextField("Judul Pemasukan", titleController),
              const SizedBox(height: 15),
              _buildTextField("Kategori (opsional)", categoryController),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : saveIncome,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
