import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  // Variabel untuk menyimpan Kantong yang dipilih
  String? selectedWalletId;
  String? selectedWalletName;

  bool isLoading = false;

  // --- FORMATTER ANGKA (Menambahkan titik otomatis) ---
  void _onAmountChanged(String value) {
    // 1. Hapus semua karakter kecuali angka
    String cleanString = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanString.isEmpty) return;

    // 2. Parse ke double
    double number = double.parse(cleanString);

    // 3. Format ulang dengan locale Indonesia
    String formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(number);

    // 4. Update controller tanpa mengganggu posisi kursor
    amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// =============================
  ///  PICK DATE & TIME
  /// =============================
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

  /// =============================
  ///  SIMPAN PENGELUARAN KE FIREBASE
  /// =============================
  Future<void> saveExpense() async {
    // 1. Bersihkan format titik dari jumlah (misal "10.000" jadi "10000")
    String cleanAmount = amountController.text.replaceAll('.', '');

    // 2. Validasi Input
    if (titleController.text.isEmpty ||
        cleanAmount.isEmpty ||
        selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon lengkapi judul, jumlah, dan metode!"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final int amount = int.parse(cleanAmount);

      // Gabungkan Date dan Time
      final DateTime fullDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // 3. JALANKAN TRANSAKSI DATABASE (Agar saldo berkurang aman)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // A. Ambil Data Kantong
        DocumentReference walletRef = FirebaseFirestore.instance
            .collection('wallets')
            .doc(selectedWalletId);

        DocumentSnapshot walletSnapshot = await transaction.get(walletRef);

        if (!walletSnapshot.exists) {
          throw Exception("Kantong tidak ditemukan!");
        }

        // B. Hitung Saldo Baru (DIKURANGI)
        int currentBalance = walletSnapshot['balance'] ?? 0;
        int newBalance =
            currentBalance - amount; // <--- INI BEDANYA DENGAN PEMASUKAN

        // C. Update Saldo Dompet
        transaction.update(walletRef, {'balance': newBalance});

        // D. Simpan Riwayat Transaksi
        DocumentReference newTransRef = FirebaseFirestore.instance
            .collection('transactions')
            .doc();

        transaction.set(newTransRef, {
          'userId': user?.uid,
          'judul': titleController.text,
          'jumlah': amount,
          'kategori': categoryController.text.isEmpty
              ? 'Lainnya'
              : categoryController.text,
          'metode': selectedWalletName, // Simpan nama kantong untuk display
          'walletId': selectedWalletId, // Simpan ID untuk relasi
          'walletName': selectedWalletName,
          'tipe': 'pengeluaran', // <--- Tipe Pengeluaran
          'createdAt': Timestamp.fromDate(fullDateTime),
        });
      });

      // 4. Sukses
      if (mounted) {
        Navigator.pop(context); // Tutup halaman
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
        backgroundColor: const Color(0xFFFFD339),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pengeluaran",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= DATE + TIME UI =================
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

              // ================= DROPDOWN KANTONG (FIREBASE) =================
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('wallets')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildBox("Memuat Kantong...");
                  }

                  // Buat daftar dropdown item dari data Firebase
                  List<DropdownMenuItem<String>> walletItems = [];
                  for (var doc in snapshot.data!.docs) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    walletItems.add(
                      DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['name']),
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
                      hint: const Text("Metode Pengeluaran"),
                      value: selectedWalletId,
                      items: walletItems,
                      onChanged: (value) {
                        setState(() {
                          selectedWalletId = value;
                          // Cari nama kantong untuk disimpan juga
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

              // ================= INPUT FIELDS =================
              // Jumlah (Pakai Formatter)
              _buildTextField("Jumlah", amountController, isNumber: true),
              const SizedBox(height: 15),

              // Judul
              _buildTextField("Judul Pengeluaran", titleController),
              const SizedBox(height: 15),

              // Kategori
              _buildTextField("Kategori Pengeluaran", categoryController),
              const SizedBox(height: 25),

              // ================= BUTTON SIMPAN =================
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    backgroundColor: const Color(0xFFFFD339),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : saveExpense,
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

  // Helper Widget untuk Kotak Putih (Date/Time)
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

  // Helper Widget untuk TextField
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
        onChanged: isNumber ? _onAmountChanged : null, // Panggil formatter
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixText: isNumber ? "Rp " : null, // Tambah prefix Rp
        ),
      ),
    );
  }
}
