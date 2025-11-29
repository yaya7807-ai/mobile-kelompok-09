import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mydompet/screens/wallet_screen.dart';
import 'package:mydompet/screens/transaction_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:mydompet/screens/report_detail_screen.dart'; // Pastikan file ini ada

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

  // Helper: Warna Dinamis untuk Kategori (Berdasarkan Hash String)
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

    // Ambil SEMUA transaksi user, diurutkan tanggal terbaru
    // Kita akan filter manual di dalam StreamBuilder sesuai Tab yang dipilih
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
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
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
  // LOGIKA KONTEN UTAMA
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
  // 1. LAPORAN HARI INI (PIE CHART PENGELUARAN)
  // =======================================================================
  Widget _buildTodayReport(List<DocumentSnapshot> docs) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Filter transaksi hari ini & tipe Pengeluaran
    var todayDocs = docs.where((doc) {
      DateTime date = (doc['createdAt'] as Timestamp).toDate();
      return date.isAfter(startOfDay) &&
          date.isBefore(endOfDay) &&
          doc['tipe'] == 'pengeluaran';
    }).toList();

    if (todayDocs.isEmpty) {
      return const Center(child: Text("Belum ada pengeluaran hari ini"));
    }

    // Kelompokkan data untuk Pie Chart
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
          Text(
            DateFormat("d MMMM yyyy", "id_ID").format(now),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // PIE CHART
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: categoryTotals.entries.map((e) {
                  final percentage = (e.value / totalExpense) * 100;
                  return PieChartSectionData(
                    color: getColorForCategory(e.key),
                    value: percentage,
                    title: "", // Sembunyikan teks di dalam chart biar rapi
                    radius: 50,
                  );
                }).toList(),
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // LEGEND LIST
          Column(
            children: categoryTotals.entries.map((e) {
              final percentage = (e.value / totalExpense) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: getColorForCategory(e.key),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(e.key),
                      ],
                    ),
                    Text(
                      "${percentage.toStringAsFixed(1)}% (Rp ${formatCurrency(e.value)})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
  // 2. LAPORAN BULANAN (GROUP BY MONTH)
  // =======================================================================
  Widget _buildMonthlyReport(List<DocumentSnapshot> docs) {
    // Grouping Logic
    Map<String, Map<String, double>> monthlyData = {};

    for (var doc in docs) {
      // Abaikan pindah saldo
      if (doc['tipe'] == 'pindah_saldo') continue;

      DateTime date = (doc['createdAt'] as Timestamp).toDate();
      String key = DateFormat(
        'MMMM yyyy',
        'id_ID',
      ).format(date); // Contoh: "Januari 2025"

      if (!monthlyData.containsKey(key)) {
        monthlyData[key] = {'income': 0, 'expense': 0};
      }

      double amount = (doc['jumlah'] ?? 0).toDouble();
      if (doc['tipe'] == 'pemasukan') {
        monthlyData[key]!['income'] =
            (monthlyData[key]!['income'] ?? 0) + amount;
      } else {
        monthlyData[key]!['expense'] =
            (monthlyData[key]!['expense'] ?? 0) + amount;
      }
    }

    if (monthlyData.isEmpty) {
      return const Center(child: Text("Belum ada data transaksi"));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: monthlyData.entries.map((entry) {
        String title = entry.key;
        double income = entry.value['income']!;
        double expense = entry.value['expense']!;

        return _buildReportCard(
          title,
          income,
          expense,
          // Logika sederhana: untuk detail pie chart bulanan,
          // kita perlu mengirim data spesifik bulan itu.
          // Untuk sekarang kita kosongkan dulu navigasinya atau kirim data dummy
          // agar tidak error. Nanti bisa kita kembangkan di ReportDetailScreen.
          () {
            // Navigasi ke detail (Future Feature)
          },
        );
      }).toList(),
    );
  }

  // =======================================================================
  // 3. LAPORAN MINGGUAN (GROUP BY WEEK)
  // =======================================================================
  Widget _buildWeeklyReport(List<DocumentSnapshot> docs) {
    Map<String, Map<String, double>> weeklyData = {};

    for (var doc in docs) {
      if (doc['tipe'] == 'pindah_saldo') continue;

      DateTime date = (doc['createdAt'] as Timestamp).toDate();

      // Cari tanggal awal minggu (Senin)
      DateTime startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

      String key =
          "${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}";

      if (!weeklyData.containsKey(key)) {
        weeklyData[key] = {'income': 0, 'expense': 0};
      }

      double amount = (doc['jumlah'] ?? 0).toDouble();
      if (doc['tipe'] == 'pemasukan') {
        weeklyData[key]!['income'] = (weeklyData[key]!['income'] ?? 0) + amount;
      } else {
        weeklyData[key]!['expense'] =
            (weeklyData[key]!['expense'] ?? 0) + amount;
      }
    }

    if (weeklyData.isEmpty) {
      return const Center(child: Text("Belum ada data transaksi"));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: weeklyData.entries.map((entry) {
        return _buildReportCard(
          entry.key,
          entry.value['income']!,
          entry.value['expense']!,
          () {},
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

  // --- NAVIGASI BAWAH (Sama seperti sebelumnya) ---
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
