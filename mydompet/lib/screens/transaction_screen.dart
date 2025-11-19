import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mydompet/screens/expense_screen.dart';
import 'package:mydompet/screens/report_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:mydompet/screens/transfer_screen.dart';
import 'package:mydompet/screens/wallet_screen.dart';
import 'package:mydompet/screens/income_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  DateTime selectedDate = DateTime.now();

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

  void showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Export PDF"),
        content: const Text("Export transaksi pada tanggal ini ke PDF?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Export"),
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
        centerTitle: true,

        actions: [
          IconButton(
            onPressed: showExportDialog,
            icon: const Icon(Icons.download_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.receipt_long_rounded),
          ),
        ],
      ),

      // ===================== BODY =====================
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            previousDay();
          } else {
            nextDay();
          }
        },

        child: Column(
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
                  children: const [
                    _SummaryItem(label: 'Pemasukan', value: '0'),
                    _SummaryItem(label: 'Pengeluaran', value: '0'),
                    _SummaryItem(label: 'Selisih', value: '0'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Center(
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
              ),
            ),
          ],
        ),
      ),

      // ===================== FAB =====================
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

                    // ➕ Pemasukan
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle_rounded,
                        size: 28,
                        color: Colors.green,
                      ),
                      title: const Text("Pemasukan"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IncomeScreen(),
                          ),
                        );
                      },
                    ),

                    // ➖ Pengeluaran
                    ListTile(
                      leading: const Icon(
                        Icons.remove_circle_rounded,
                        size: 28,
                        color: Colors.red,
                      ),
                      title: const Text("Pengeluaran"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExpenseScreen(),
                          ),
                        );
                      },
                    ),

                    // ↔ Pindah Saldo
                    ListTile(
                      leading: const Icon(
                        Icons.swap_horiz_rounded,
                        size: 28,
                        color: Colors.blue,
                      ),
                      title: const Text("Pindah Saldo"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransferScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      // ===================== BOTTOM NAV =====================
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // Bottom navigation builder
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
