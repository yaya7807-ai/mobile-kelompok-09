import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mydompet/screens/expense_screen.dart';
import 'package:mydompet/screens/income_screen.dart';
import 'package:mydompet/screens/transfer_screen.dart';
import 'package:mydompet/screens/wallet_screen.dart';
import 'package:mydompet/screens/report_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:mydompet/screens/history_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  DateTime selectedDate = DateTime.now();

  // Helper Format Rupiah
  String formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount);
  }

  // --- NAVIGASI HARI ---
  void previousDay() {
    setState(
      () => selectedDate = selectedDate.subtract(const Duration(days: 1)),
    );
  }

  void nextDay() {
    setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));
  }

  // --- PILIH TANGGAL (DATE PICKER) ---
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFD339),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // --- FUNGSI BUKA HALAMAN ---
  void openIncome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IncomeScreen()),
    );
  }

  void openExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseScreen()),
    );
  }

  void openTransfer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    );
  }

  // --- HAPUS TRANSAKSI ---
  void deleteTransaction(
    String docId,
    double amount,
    String type,
    String walletId,
    String? toWalletId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: const Text("Saldo kantong akan dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseFirestore.instance.runTransaction((
                transaction,
              ) async {
                DocumentReference walletRef = FirebaseFirestore.instance
                    .collection('wallets')
                    .doc(walletId);
                DocumentSnapshot walletSnap = await transaction.get(walletRef);

                if (walletSnap.exists) {
                  int currentBal = walletSnap['balance'];
                  int newBal = currentBal;

                  if (type == 'pemasukan')
                    newBal -= amount.toInt();
                  else if (type == 'pengeluaran')
                    newBal += amount.toInt();
                  else if (type == 'pindah_saldo')
                    newBal += amount.toInt();

                  transaction.update(walletRef, {'balance': newBal});
                }

                if (type == 'pindah_saldo' && toWalletId != null) {
                  DocumentReference toWalletRef = FirebaseFirestore.instance
                      .collection('wallets')
                      .doc(toWalletId);
                  DocumentSnapshot toWalletSnap = await transaction.get(
                    toWalletRef,
                  );
                  if (toWalletSnap.exists) {
                    int toCurrentBal = toWalletSnap['balance'];
                    transaction.update(toWalletRef, {
                      'balance': toCurrentBal - amount.toInt(),
                    });
                  }
                }

                transaction.delete(
                  FirebaseFirestore.instance
                      .collection('transactions')
                      .doc(docId),
                );
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Transaksi dihapus")),
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String formattedDate = DateFormat(
      'EEE, dd MMM yyyy',
      'id_ID',
    ).format(selectedDate);

    DateTime startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      0,
      0,
      0,
    );
    DateTime endOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
      59,
    );

    final Stream<QuerySnapshot> transactionStream = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user?.uid)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ===================== APPBAR DIPERBAIKI =====================
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD339),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        foregroundColor: Colors.black,
        title: Row(
          // KITA KEMBALIKAN KE CENTER SUPAYA TIDAK OVERFLOW (ERROR)
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: previousDay,
              icon: const Icon(Icons.chevron_left),
            ),

            // KLIK TANGGAL
            GestureDetector(
              onTap: _selectDate,
              child: Row(
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),

            IconButton(
              onPressed: nextDay,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        actions: [
          // SISA ICON REKAP SAJA (ICON DOWNLOAD SUDAH DIHAPUS)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {}, // Nanti dihubungkan ke halaman Report/History
              icon: const Icon(Icons.description),
            ),
          ),
        ],
      ),

      // ===================== BODY =====================
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            previousDay();
          } else if (details.primaryVelocity! < 0) {
            nextDay();
          }
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: transactionStream,
          builder: (context, snapshot) {
            double income = 0;
            double expense = 0;
            List<DocumentSnapshot> docs = [];

            if (snapshot.hasData) {
              docs = snapshot.data!.docs;
              for (var doc in docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                double amount = (data['jumlah'] ?? 0).toDouble();

                if (data['tipe'] == 'pemasukan')
                  income += amount;
                else if (data['tipe'] == 'pengeluaran')
                  expense += amount;
              }
            }

            return Column(
              children: [
                // HEADER SUMMARY
                Container(
                  color: const Color(0xFFFFD339),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          label: "Pemasukan",
                          value: "+${formatCurrency(income)}",
                          color: Colors.green,
                        ),
                        _SummaryItem(
                          label: "Pengeluaran",
                          value: formatCurrency(expense),
                          color: Colors.black87,
                        ),
                        _SummaryItem(
                          label: "Selisih",
                          value: (income - expense) >= 0
                              ? "+${formatCurrency(income - expense)}"
                              : formatCurrency(income - expense),
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                // LIST TRANSAKSI
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: docs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.receipt_long,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Belum ada transaksi",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: docs.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              var doc = docs[index];
                              Map<String, dynamic> data =
                                  doc.data() as Map<String, dynamic>;
                              return _buildTransactionItem(doc.id, data);
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            builder: (context) {
              return SizedBox(
                height: 250,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(
                        Icons.arrow_downward_rounded,
                        size: 28,
                        color: Colors.green,
                      ),
                      title: const Text("Pemasukan"),
                      onTap: () {
                        Navigator.pop(context);
                        openIncome();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 28,
                        color: Colors.red,
                      ),
                      title: const Text("Pengeluaran"),
                      onTap: () {
                        Navigator.pop(context);
                        openExpense();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.swap_horiz_rounded,
                        size: 28,
                        color: Colors.blue,
                      ),
                      title: const Text("Pindah Saldo"),
                      onTap: () {
                        Navigator.pop(context);
                        openTransfer();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTransactionItem(String docId, Map<String, dynamic> data) {
    String type = data['tipe'];
    double amount = (data['jumlah'] ?? 0).toDouble();
    String title = data['judul'] ?? 'Tanpa Judul';
    String category = data['kategori'] ?? '';

    Color amountColor = Colors.black;
    String amountPrefix = "";
    String subtitle = category;

    if (type == 'pemasukan') {
      amountColor = Colors.green;
      amountPrefix = "+";
    } else if (type == 'pengeluaran') {
      amountColor = Colors.black87;
      amountPrefix = "-";
    } else if (type == 'pindah_saldo') {
      amountColor = Colors.black54;
      String from = data['walletName'] ?? '?';
      String to = data['toWalletName'] ?? '?';
      subtitle = "$from \u2192 $to";
    }

    return InkWell(
      onLongPress: () => deleteTransaction(
        docId,
        amount,
        type,
        data['walletId'],
        data['toWalletId'],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                Text(
                  "$amountPrefix${formatCurrency(amount)}",
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.book, "Transaksi", true, const TransactionScreen()),
            _navItem(Icons.wallet, "Kantong", false, const WalletScreen()),
            _navItem(Icons.bar_chart, "Rekap", false, const ReportScreen()),
            _navItem(Icons.settings, "Setting", false, const SettingScreen()),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, Widget screen) {
    return TextButton(
      onPressed: active
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? Colors.black : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
