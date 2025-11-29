import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mydompet/screens/wallet_screen.dart';
import 'package:mydompet/screens/transaction_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:mydompet/screens/report_detail_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedTab = 'Hari Ini';

  // Helper: Format Rupiah
  String formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount);
  }

  // Helper: Warna Dinamis
  Color getColorForCategory(String category) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.brown,
    ];
    return colors[category.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final Stream<QuerySnapshot> transactionStream = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Rekap",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          return Column(
            children: [
              _buildTabButtons(),
              Expanded(child: _buildTabContent(docs)),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // -----------------------------
  // TAB BUTTONS
  // -----------------------------
  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabButton('Hari Ini'),
          _buildTabButton('Mingguan'),
          _buildTabButton('Bulanan'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isSelected = selectedTab == label;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => setState(() => selectedTab = label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.yellow : Colors.white,
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  // -----------------------------
  // KONTEN TAB
  // -----------------------------
  Widget _buildTabContent(List<DocumentSnapshot> docs) {
    switch (selectedTab) {
      case 'Hari Ini':
        return _buildTodayReport(docs);
      case 'Mingguan':
        return _buildWeeklyReport(docs);
      case 'Bulanan':
        return _buildMonthlyReport(docs);
      default:
        return Container();
    }
  }

  // =======================================================================
  // 1. LAPORAN HARI INI (FINAL: CHART RAPI + LIST DENGAN NOMINAL)
  // =======================================================================
  Widget _buildTodayReport(List<DocumentSnapshot> docs) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    var todayDocs = docs.where((doc) {
      DateTime date = (doc['createdAt'] as Timestamp).toDate();
      return date.isAfter(startOfDay) &&
          date.isBefore(endOfDay) &&
          doc['tipe'] == 'pengeluaran';
    }).toList();

    if (todayDocs.isEmpty) {
      return const Center(child: Text("Belum ada pengeluaran hari ini"));
    }

    Map<String, double> categoryTotals = {};
    double totalExpense = 0;

    for (var doc in todayDocs) {
      String cat = doc['kategori'] ?? 'Lainnya';
      double amount = (doc['jumlah'] ?? 0).toDouble();
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amount;
      totalExpense += amount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. Tanggal
          Text(
            DateFormat("d MMMM yyyy", "id_ID").format(now),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 30),

          // 2. PIE CHART
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: categoryTotals.entries.map((e) {
                  final percentage = (e.value / totalExpense) * 100;
                  final showLabel = percentage > 4;

                  return PieChartSectionData(
                    color: getColorForCategory(e.key),
                    value: percentage,
                    title: showLabel ? e.key : '',
                    radius: 30,
                    titlePositionPercentageOffset: 2.2, // Teks jauh di luar
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 3. LIST RINCIAN (LEGEND) DI BAWAH
          Column(
            children: categoryTotals.entries.map((e) {
              final percentage = (e.value / totalExpense) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kiri: Kotak Warna & Nama
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: getColorForCategory(e.key),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    // Kanan: Persentase + Nominal (DIPERBAIKI DISINI)
                    Text(
                      "${percentage.toStringAsFixed(0)}% (${formatCurrency(e.value)})", // 🔥 Tambah formatCurrency
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // 2. LAPORAN BULANAN
  // =======================================================================
  Widget _buildMonthlyReport(List<DocumentSnapshot> docs) {
    Map<String, Map<String, dynamic>> monthlyData = {};

    for (var doc in docs) {
      if (doc['tipe'] == 'pindah_saldo') continue;
      DateTime date = (doc['createdAt'] as Timestamp).toDate();

      // Hitung Start & End Month
      DateTime startOfMonth = DateTime(date.year, date.month, 1);
      DateTime endOfMonth = DateTime(
        date.year,
        date.month + 1,
        0,
        23,
        59,
        59,
      ); // Hari terakhir bulan ini

      String key = DateFormat('MMMM yyyy', 'id_ID').format(date);

      if (!monthlyData.containsKey(key)) {
        monthlyData[key] = {
          'income': 0.0,
          'expense': 0.0,
          'start': startOfMonth,
          'end': endOfMonth,
        };
      }

      double amount = (doc['jumlah'] ?? 0).toDouble();
      if (doc['tipe'] == 'pemasukan')
        monthlyData[key]!['income'] += amount;
      else
        monthlyData[key]!['expense'] += amount;
    }

    if (monthlyData.isEmpty)
      return const Center(child: Text("Belum ada data transaksi"));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: monthlyData.entries.map((entry) {
        return _buildReportCard(
          entry.key,
          entry.value['income'],
          entry.value['expense'],
          () {
            // 🔥 NAVIGASI KE DETAIL 🔥
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailScreen(
                  title: entry.key,
                  startDate: entry.value['start'],
                  endDate: entry.value['end'],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  // =======================================================================
  // 3. LAPORAN MINGGUAN
  // =======================================================================
  Widget _buildWeeklyReport(List<DocumentSnapshot> docs) {
    // Key: "1 Jan - 7 Jan", Value: {income, expense, startDate, endDate}
    Map<String, Map<String, dynamic>> weeklyData = {};

    for (var doc in docs) {
      if (doc['tipe'] == 'pindah_saldo') continue;
      DateTime date = (doc['createdAt'] as Timestamp).toDate();

      // Hitung Start & End Week
      DateTime startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      startOfWeek = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      ); // Jam 00:00
      DateTime endOfWeek = startOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59),
      );

      String key =
          "${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}";

      if (!weeklyData.containsKey(key)) {
        weeklyData[key] = {
          'income': 0.0,
          'expense': 0.0,
          'start': startOfWeek,
          'end': endOfWeek,
        };
      }

      double amount = (doc['jumlah'] ?? 0).toDouble();
      if (doc['tipe'] == 'pemasukan')
        weeklyData[key]!['income'] += amount;
      else
        weeklyData[key]!['expense'] += amount;
    }

    if (weeklyData.isEmpty)
      return const Center(child: Text("Belum ada data transaksi"));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: weeklyData.entries.map((entry) {
        return _buildReportCard(
          entry.key,
          entry.value['income'],
          entry.value['expense'],
          () {
            // 🔥 NAVIGASI KE DETAIL 🔥
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailScreen(
                  title: entry.key,
                  startDate: entry.value['start'],
                  endDate: entry.value['end'],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  // WIDGET CARD UMUM
  Widget _buildReportCard(
    String title,
    double income,
    double expense,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMoneyRow("Pemasukan", income),
              _buildMoneyRow("Pengeluaran", expense),
              const Divider(),
              _buildMoneyRow("Selisih", income - expense, isBold: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoneyRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatCurrency(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // --- NAVIGASI BAWAH ---
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navButton(
            context,
            Icons.book,
            "Transaksi",
            const TransactionScreen(),
            false,
          ),
          _navButton(
            context,
            Icons.wallet,
            "Kantong",
            const WalletScreen(),
            false,
          ),
          _navButton(context, Icons.bar_chart, "Rekap", null, true),
          _navButton(
            context,
            Icons.settings,
            "Setting",
            const SettingScreen(),
            false,
          ),
        ],
      ),
    );
  }

  Widget _navButton(
    BuildContext context,
    IconData icon,
    String label,
    Widget? screen,
    bool active,
  ) {
    return TextButton(
      onPressed: () {
        if (!active && screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
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
