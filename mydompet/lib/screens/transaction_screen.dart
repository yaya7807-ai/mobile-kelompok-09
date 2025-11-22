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

  List<Map<String, dynamic>> allTransactions = [];

  // ================================
  //   FILTER TRANSAKSI BERDASARKAN selectedDate
  // ================================
  List<Map<String, dynamic>> get todayTransactions {
    return allTransactions.where((t) {
      return t["tanggal"].day == selectedDate.day &&
          t["tanggal"].month == selectedDate.month &&
          t["tanggal"].year == selectedDate.year;
    }).toList();
  }

  double get totalIncome {
    return todayTransactions
        .where((t) => t["tipe"] == "pemasukan")
        .fold(0, (sum, t) => sum + t["jumlah"]);
  }

  double get totalExpense {
    return todayTransactions
        .where((t) => t["tipe"] == "pengeluaran")
        .fold(0, (sum, t) => sum + t["jumlah"]);
  }

  void previousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
  }

  void nextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
  }

  // ================================
  //     TAMBAH TRANSAKSI — mengikuti selectedDate
  // ================================
  void openIncome() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IncomeScreen()),
    );

    if (result != null) {
      result["tanggal"] = selectedDate; // FIX
      setState(() => allTransactions.add(result));
    }
  }

  void openExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExpenseScreen()),
    );

    if (result != null) {
      result["tanggal"] = selectedDate; // FIX
      setState(() => allTransactions.add(result));
    }
  }

  void openTransfer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TransferScreen()),
    );

    if (result != null) {
      result["tanggal"] = selectedDate; // FIX
      setState(() => allTransactions.add(result));
    }
  }

  // ================================
  //   KONFIRMASI HAPUS
  // ================================
  void deleteTransaction(Map<String, dynamic> t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: const Text("Transaksi ini akan dihapus secara permanen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                allTransactions.remove(t);
              });
              Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat(
      'EEE, dd MMM yyyy',
      'id_ID',
    ).format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ===================== APPBAR =====================
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HistoryScreen(allTransactions: allTransactions),
                  ),
                );
              },
              icon: const Icon(Icons.history),
            ),
          ),
        ],
      ),

      // ===================== BODY =====================
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFFD339),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                    value: "Rp ${totalIncome.toStringAsFixed(0)}",
                  ),
                  _SummaryItem(
                    label: "Pengeluaran",
                    value: "Rp ${totalExpense.toStringAsFixed(0)}",
                  ),
                  _SummaryItem(
                    label: "Selisih",
                    value:
                        "Rp ${(totalIncome - totalExpense).toStringAsFixed(0)}",
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: todayTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 130,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Tidak ada data",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: todayTransactions.length,
                    itemBuilder: (context, index) {
                      final t = todayTransactions[index];

                      final formattedDate = DateFormat(
                        'dd MMM yyyy',
                        'id_ID',
                      ).format(t["tanggal"]);

                      return ListTile(
                        onLongPress: () => deleteTransaction(t),
                        title: Text(t["judul"]),
                        subtitle: Text("${t["kategori"]} • $formattedDate"),
                        trailing: Text(
                          (t["tipe"] == "pemasukan" ? "+ " : "- ") +
                              t["jumlah"].toString(),
                          style: TextStyle(
                            color: t["tipe"] == "pemasukan"
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
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
