import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportDetailScreen extends StatefulWidget {
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  const ReportDetailScreen({
    super.key,
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Helper Format Rupiah
  String formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount);
  }

  // Helper Warna Kategori
  Color getColorForCategory(String category) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.brown,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[category.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final Stream<QuerySnapshot> detailStream = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user?.uid)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(widget.startDate),
        )
        .where(
          'createdAt',
          isLessThanOrEqualTo: Timestamp.fromDate(widget.endDate),
        )
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          "Detail Rekap",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFD339), // Kuning
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 0,

        // --- 3. PERBAIKAN TAB BAR (Menempel di AppBar) ---
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: const Color(0xFFFFD339), // Background Kuning
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3), // Sedikit transparan
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: TabBar(
                controller: _tabController,
                // Indikator aktif berwarna KUNING TERANG solid dengan border hitam tipis
                indicator: BoxDecoration(
                  color: const Color(0xFFFFD339),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Grafik"),
                  Tab(text: "Detail"),
                ],
              ),
            ),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: detailStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];

          // --- OLAH DATA ---
          double totalIncome = 0;
          double totalExpense = 0;
          Map<String, double> expenseByCategory = {};
          Map<String, double> incomeBySource =
              {}; // Simpan sumber pemasukan (misal: Gaji, Bonus)

          for (var doc in docs) {
            String type = doc['tipe'];
            double amount = (doc['jumlah'] ?? 0).toDouble();
            String category = doc['kategori'] ?? 'Lainnya';
            String title = doc['judul'] ?? 'Pemasukan Lain';

            if (type == 'pemasukan') {
              totalIncome += amount;
              // Kelompokkan pemasukan berdasarkan kategori atau judul jika kategori kosong
              String sourceKey = category.isNotEmpty ? category : title;
              incomeBySource[sourceKey] =
                  (incomeBySource[sourceKey] ?? 0) + amount;
            } else if (type == 'pengeluaran') {
              totalExpense += amount;
              expenseByCategory[category] =
                  (expenseByCategory[category] ?? 0) + amount;
            }
          }

          int daysCount =
              widget.endDate.difference(widget.startDate).inDays + 1;
          double dailyIncomeAvg = totalIncome / daysCount;
          double dailyExpenseAvg = totalExpense / daysCount;

          return Column(
            children: [
              // Judul Periode (Misal: 1 Jan - 7 Jan)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // === TAB 1: GRAFIK ===
                    _buildGraphicTab(expenseByCategory, totalExpense),

                    // === TAB 2: DETAIL ===
                    _buildDetailTab(
                      totalIncome,
                      totalExpense,
                      dailyIncomeAvg,
                      dailyExpenseAvg,
                      incomeBySource,
                      expenseByCategory,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------
  // WIDGET TAB 1: GRAFIK (Perbaikan Filter 0%)
  // ------------------------------------------
  Widget _buildGraphicTab(Map<String, double> data, double total) {
    if (total == 0) return const Center(child: Text("Tidak ada pengeluaran"));

    // 1. Filter Data: Hapus yang nilainya 0
    final filteredData = Map.fromEntries(
      data.entries.where((e) => e.value > 0),
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: filteredData.entries.map((e) {
                  final percentage = (e.value / total) * 100;
                  final showLabel =
                      percentage > 4; // Label chart hanya muncul jika > 4%
                  return PieChartSectionData(
                    color: getColorForCategory(e.key),
                    value: percentage,
                    title: showLabel ? e.key : '',
                    radius: 40,
                    titlePositionPercentageOffset: 1.5,
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

          // Legend List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: filteredData.entries.map((e) {
                final percentage = (e.value / total) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: getColorForCategory(e.key),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            e.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(
                        "${percentage.toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // WIDGET TAB 2: DETAIL TEXT (Tambah Daftar Pemasukan)
  // ------------------------------------------
  Widget _buildDetailTab(
    double income,
    double expense,
    double avgIn,
    double avgOut,
    Map<String, double> incomeList, // Data Pemasukan
    Map<String, double> expenseList, // Data Pengeluaran
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ringkasan Atas
          _rowDetail("Pemasukan", income),
          _rowDetail("Rata - rata per hari", avgIn, isSub: true),
          const SizedBox(height: 10),
          _rowDetail("Pengeluaran", expense),
          _rowDetail("Rata - rata per hari", avgOut, isSub: true),
          const SizedBox(height: 10),
          _rowDetail("Selisih", income - expense, isBold: true),
          const SizedBox(height: 30),

          // 2. DAFTAR PEMASUKAN (BARU)
          if (incomeList.isNotEmpty) ...[
            const Center(
              child: Text(
                "Daftar Pemasukan",
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Kita filter juga pemasukan 0 (jaga-jaga)
            ...incomeList.entries
                .where((e) => e.value > 0)
                .map(
                  (e) =>
                      _progressBarItem(e.key, e.value, income, isIncome: true),
                )
                .toList(),
            const SizedBox(height: 20),
          ],

          // Daftar Pengeluaran
          if (expenseList.isNotEmpty) ...[
            const Center(
              child: Text(
                "Daftar Pengeluaran",
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...expenseList.entries
                .where((e) => e.value > 0)
                .map((e) => _progressBarItem(e.key, e.value, expense))
                .toList(),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _rowDetail(
    String label,
    double value, {
    bool isSub = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSub ? Colors.black54 : Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatCurrency(value),
            style: TextStyle(
              color: isSub ? Colors.black54 : Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBarItem(
    String label,
    double value,
    double total, {
    bool isIncome = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                formatCurrency(value),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : value / total,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              // Pemasukan = Hijau/Teal, Pengeluaran = Cyan/Biru
              color: isIncome ? Colors.teal : const Color(0xFF00ACC1),
            ),
          ),
        ],
      ),
    );
  }
}
