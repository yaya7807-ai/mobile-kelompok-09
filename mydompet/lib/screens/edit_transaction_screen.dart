import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditTransactionScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditTransactionScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;

  late TextEditingController amountController;
  late TextEditingController titleController;
  late TextEditingController categoryController;

  String? selectedWalletId;
  String? toWalletId; // Khusus Pindah Saldo

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Inisialisasi Data dari Transaksi yang Diedit
    DateTime date = (widget.data['createdAt'] as Timestamp).toDate();
    selectedDate = date;
    selectedTime = TimeOfDay.fromDateTime(date);

    titleController = TextEditingController(text: widget.data['judul']);
    categoryController = TextEditingController(text: widget.data['kategori']);

    // Format Uang Awal
    double amount = (widget.data['jumlah'] as num).toDouble();
    String formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount);
    amountController = TextEditingController(text: formatted);

    selectedWalletId = widget.data['walletId'];
    toWalletId = widget.data['toWalletId'];
  }

  // --- FORMATTER ---
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

  // --- PICKERS ---
  Future<void> pickDate() async {
    DateTime? result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: selectedDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFFD339),
            onPrimary: Colors.black,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
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

  // --- HAPUS TRANSAKSI (Logic sama seperti di TransactionScreen) ---
  void deleteTransaction() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: const Text("Tindakan ini tidak bisa dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup Dialog
              setState(() => isLoading = true);

              try {
                await FirebaseFirestore.instance.runTransaction((
                  transaction,
                ) async {
                  // Rollback Saldo
                  DocumentReference walletRef = FirebaseFirestore.instance
                      .collection('wallets')
                      .doc(widget.data['walletId']);
                  DocumentSnapshot walletSnap = await transaction.get(
                    walletRef,
                  );

                  if (walletSnap.exists) {
                    int currentBal = walletSnap['balance'];
                    int oldAmount = (widget.data['jumlah'] as num).toInt();
                    int newBal = currentBal;

                    if (widget.data['tipe'] == 'pemasukan')
                      newBal -= oldAmount;
                    else if (widget.data['tipe'] == 'pengeluaran')
                      newBal += oldAmount;
                    else if (widget.data['tipe'] == 'pindah_saldo')
                      newBal += oldAmount;

                    transaction.update(walletRef, {'balance': newBal});
                  }

                  // Rollback Tujuan (Jika Pindah Saldo)
                  if (widget.data['tipe'] == 'pindah_saldo' &&
                      widget.data['toWalletId'] != null) {
                    DocumentReference toRef = FirebaseFirestore.instance
                        .collection('wallets')
                        .doc(widget.data['toWalletId']);
                    DocumentSnapshot toSnap = await transaction.get(toRef);
                    if (toSnap.exists) {
                      int toBal = toSnap['balance'];
                      transaction.update(toRef, {
                        'balance':
                            toBal - (widget.data['jumlah'] as num).toInt(),
                      });
                    }
                  }

                  transaction.delete(
                    FirebaseFirestore.instance
                        .collection('transactions')
                        .doc(widget.docId),
                  );
                });

                if (mounted) {
                  Navigator.pop(context); // Kembali ke Home
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Transaksi Dihapus")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- UPDATE TRANSAKSI ---
  Future<void> updateTransaction() async {
    String cleanAmount = amountController.text.replaceAll('.', '');
    if (titleController.text.isEmpty || cleanAmount.isEmpty) return;

    setState(() => isLoading = true);

    try {
      int newAmount = int.parse(cleanAmount);
      DateTime fullDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Ambil Data Wallet
        DocumentReference walletRef = FirebaseFirestore.instance
            .collection('wallets')
            .doc(widget.data['walletId']);
        DocumentSnapshot walletSnap = await transaction.get(walletRef);

        if (!walletSnap.exists) throw Exception("Dompet tidak ditemukan");

        int currentBal = walletSnap['balance'];
        int oldAmount = (widget.data['jumlah'] as num).toInt();
        String type = widget.data['tipe'];

        // 2. Hitung Saldo Koreksi
        // Logika: Kembalikan saldo lama -> Terapkan saldo baru
        int correctedBal = currentBal;

        if (type == 'pemasukan') {
          correctedBal = (currentBal - oldAmount) + newAmount;
        } else if (type == 'pengeluaran') {
          correctedBal = (currentBal + oldAmount) - newAmount;
        } else if (type == 'pindah_saldo') {
          // Khusus pindah saldo, update 2 dompet
          correctedBal = (currentBal + oldAmount) - newAmount;

          if (toWalletId != null) {
            DocumentReference toRef = FirebaseFirestore.instance
                .collection('wallets')
                .doc(toWalletId);
            DocumentSnapshot toSnap = await transaction.get(toRef);
            if (toSnap.exists) {
              int toBal = toSnap['balance'];
              // Di dompet tujuan: (Saldo - Lama) + Baru
              transaction.update(toRef, {
                'balance': (toBal - oldAmount) + newAmount,
              });
            }
          }
        }

        // 3. Update DB
        transaction.update(walletRef, {'balance': correctedBal});
        transaction.update(
          FirebaseFirestore.instance
              .collection('transactions')
              .doc(widget.docId),
          {
            'judul': titleController.text,
            'jumlah': newAmount,
            'kategori': categoryController.text,
            'createdAt': Timestamp.fromDate(fullDate),
          },
        );
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Berhasil diperbarui")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal update: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String typeLabel = "Transaksi";
    if (widget.data['tipe'] == 'pemasukan')
      typeLabel = "Pemasukan";
    else if (widget.data['tipe'] == 'pengeluaran')
      typeLabel = "Pengeluaran";
    else
      typeLabel = "Pindah Saldo";

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
        title: Text(
          "Edit $typeLabel",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          // TOMBOL SAMPAH (HAPUS)
          IconButton(
            onPressed: deleteTransaction,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            children: [
              // DATE PICKER
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

              // INFO WALLET (READ ONLY UTK EDIT)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.data['tipe'] == 'pindah_saldo'
                      ? "Dari: ${widget.data['walletName']} \u2192 Ke: ${widget.data['toWalletName']}"
                      : "Dompet: ${widget.data['walletName']}",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              _buildTextField("Jumlah", amountController, isNumber: true),
              const SizedBox(height: 15),
              _buildTextField("Judul", titleController),
              const SizedBox(height: 15),

              // Kategori (Disembunyikan jika pindah saldo)
              if (widget.data['tipe'] != 'pindah_saldo')
                _buildTextField("Kategori", categoryController),

              const SizedBox(height: 25),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    backgroundColor: const Color(0xFFFFD339),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : updateTransaction,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          "Update",
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
