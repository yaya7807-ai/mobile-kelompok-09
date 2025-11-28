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
      symbol: 'Rp ',
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

  // --- FUNGSI BUKA HALAMAN ---
  // Tidak perlu setState manual lagi karena StreamBuilder akan otomatis update
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
  // Kita harus menghapus data di database, bukan di list lokal
  void deleteTransaction(
    String docId,
    double amount,
    String type,
    String walletId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: const Text("Saldo kantong juga akan dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog dulu

              // 1. Jalankan Logic Hapus & Kembalikan Saldo
              final walletRef = FirebaseFirestore.instance
                  .collection('wallets')
                  .doc(walletId);

              await FirebaseFirestore.instance.runTransaction((
                transaction,
              ) async {
                // A. Baca saldo dompet saat ini
                DocumentSnapshot walletSnapshot = await transaction.get(
                  walletRef,
                );
                if (walletSnapshot.exists) {
                  int currentBalance = walletSnapshot['balance'];

                  // B. Kembalikan saldo (Kebalikan dari tipe transaksi)
                  // Kalau Pemasukan dihapus -> Saldo BERKURANG
                  // Kalau Pengeluaran dihapus -> Saldo BERTAMBAH
                  int newBalance = currentBalance;
                  if (type == 'pemasukan') {
                    newBalance -= amount.toInt();
                  } else if (type == 'pengeluaran') {
                    newBalance += amount.toInt();
                  }

                  transaction.update(walletRef, {'balance': newBalance});
                }

                // C. Hapus dokumen transaksi
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

    // Filter tanggal untuk query Firebase
    // Kita ambil data dari jam 00:00:00 sampai 23:59:59 pada selectedDate
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
        .orderBy('createdAt', descending: true) // Urutkan dari yang terbaru
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD339),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        foregroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: previousDay,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: nextDay,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        actions: [
          // Untuk history nanti, sementara saya matikan passing parameter allTransactions
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                // Navigator.push... (HistoryScreen logic needs update later)
              },
              icon: const Icon(Icons.history),
            ),
          ),
        ],
      ),

      // ============ BODY DENGAN STREAM BUILDER ============
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionStream,
        builder: (context, snapshot) {
          // --- CALCULATE SUMMARY ---
          double income = 0;
          double expense = 0;
          List<DocumentSnapshot> docs = [];

          if (snapshot.hasData) {
            docs = snapshot.data!.docs;
            for (var doc in docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              double amount = (data['jumlah'] ?? 0).toDouble();
              if (data['tipe'] == 'pemasukan') {
                income += amount;
              } else if (data['tipe'] == 'pengeluaran') {
                expense += amount;
              }
            }
          }

          return Column(
            children: [
              // HEADER SUMMARY
              Container(
                color: const Color(0xFFFFD339),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(
                        label: "Pemasukan",
                        value: formatCurrency(income),
                        color: Colors.green,
                      ),
                      _SummaryItem(
                        label: "Pengeluaran",
                        value: formatCurrency(expense),
                        color: Colors.red,
                      ),
                      _SummaryItem(
                        label: "Selisih",
                        value: formatCurrency(income - expense),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),

              // LIST TRANSAKSI
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 100,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Belum ada transaksi hari ini",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var doc = docs[index];
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;

                          // Convert timestamp to DateTime
                          DateTime date = (data['createdAt'] as Timestamp)
                              .toDate();
                          String timeStr = DateFormat('HH:mm').format(date);

                          return ListTile(
                            onLongPress: () => deleteTransaction(
                              doc.id,
                              (data['jumlah'] as num).toDouble(),
                              data['tipe'],
                              data['walletId'],
                            ),
                            leading: CircleAvatar(
                              backgroundColor: data['tipe'] == 'pemasukan'
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              child: Icon(
                                data['tipe'] == 'pemasukan'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: data['tipe'] == 'pemasukan'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            title: Text(data['judul'] ?? 'Tanpa Judul'),
                            subtitle: Text("${data['walletName']} • $timeStr"),
                            trailing: Text(
                              (data['tipe'] == 'pemasukan' ? "+ " : "- ") +
                                  formatCurrency(data['jumlah']),
                              style: TextStyle(
                                color: data['tipe'] == 'pemasukan'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          // ... (KODE MODAL BOTTOM SHEET SAMA SEPERTI SEBELUMNYA) ...
          // Copy Paste bagian showModalBottomSheet kamu yang lama di sini
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            builder: (context) {
              return SizedBox(
                height: 230,
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
                        Icons.add_circle_rounded,
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
                        Icons.remove_circle_rounded,
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

  // ... (KODE _buildBottomNav dan _navItem SAMA SEPERTI SEBELUMNYA) ...
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
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
