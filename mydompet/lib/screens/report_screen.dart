import 'package:flutter/material.dart';
import 'package:mydompet/screens/wallet_screen.dart';
import 'package:mydompet/screens/transaction_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedTab = 'Hari Ini';

  // -----------------------------
  // DATA DUMMY
  // -----------------------------
  final Map<String, Color> categoryColors = {
    'Saldo': Colors.blue,
    'Internet': Colors.orange,
    'Belanja Baju': Colors.teal,
    'Jajan': Colors.grey,
  };

  final Map<String, double> categoryPercent = {
    'Saldo': 17,
    'Internet': 27,
    'Belanja Baju': 37,
    'Jajan': 20,
  };

  // Data laporan mingguan (dummy)
  final List<Map<String, dynamic>> weeklyReports = [
    {
      "title": "1 Januari - 7 Januari 2025",
      "income": 1500000,
      "expense": 850000,
    },
    {
      "title": "8 Januari - 14 Januari 2025",
      "income": 1800000,
      "expense": 920000,
    },
  ];

  // Data laporan bulanan (dummy)
  final List<Map<String, dynamic>> monthlyReports = [
    {"title": "Januari 2025", "income": 3000000, "expense": 2350000},
    {"title": "Februari 2025", "income": 3200000, "expense": 2400000},
  ];

  // -----------------------------
  // BUILD UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🔥 tombol back dihilangkan
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Rekap",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          _buildTabButtons(),
          Expanded(child: _buildTabContent()),
        ],
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
  // TAB CONTENT
  // -----------------------------
  Widget _buildTabContent() {
    switch (selectedTab) {
      case 'Hari Ini':
        return _buildTodayReport();
      case 'Mingguan':
        return _buildWeeklyReport();
      case 'Bulanan':
        return _buildMonthlyReport();
      default:
        return Container();
    }
  }

  // -----------------------------
  // HARI INI (DUMMY PIECHART)
  // -----------------------------
  Widget _buildTodayReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "1 Januari 2025",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: categoryPercent.entries
                    .map(
                      (e) => PieChartSectionData(
                        color: categoryColors[e.key],
                        value: e.value,
                        title: "",
                        radius: 55,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Column(
            children: categoryPercent.entries.map((e) {
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
                            color: categoryColors[e.key],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(e.key),
                      ],
                    ),
                    Text(
                      "${e.value.toStringAsFixed(0)}%",
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

  // -----------------------------
  // MINGGUAN
  // -----------------------------
  Widget _buildWeeklyReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: weeklyReports.map((week) {
          return _buildWeeklyCard(week);
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyCard(Map<String, dynamic> data) {
    final title = data["title"];
    final income = data["income"];
    final expense = data["expense"];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailReportPage(
              title: title,
              categoryColors: categoryColors,
              categoryPercent: categoryPercent,
            ),
          ),
        );
      },
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
              _buildMoneyRow("Selisih", income - expense),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // BULANAN
  // -----------------------------
  Widget _buildMonthlyReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: monthlyReports.map((month) {
          return _buildMonthlyCard(month);
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyCard(Map<String, dynamic> data) {
    final title = data["title"];
    final income = data["income"];
    final expense = data["expense"];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailReportPage(
              title: title,
              categoryColors: categoryColors,
              categoryPercent: categoryPercent,
            ),
          ),
        );
      },
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
              _buildMoneyRow("Selisih", income - expense),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // Money Row
  // -----------------------------
  Widget _buildMoneyRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value.toString())],
      ),
    );
  }

  // -----------------------------
  // Bottom Navigation
  // -----------------------------
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

// -----------------------------
// DETAIL REPORT PAGE
// -----------------------------
class DetailReportPage extends StatelessWidget {
  final String title;
  final Map<String, Color> categoryColors;
  final Map<String, double> categoryPercent;

  const DetailReportPage({
    super.key,
    required this.title,
    required this.categoryColors,
    required this.categoryPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
      ),
      body: DetailReportContent(
        title: title,
        categoryColors: categoryColors,
        categoryPercent: categoryPercent,
      ),
    );
  }
}

// -----------------------------
// DETAIL CONTENT
// -----------------------------
class DetailReportContent extends StatelessWidget {
  final String title;
  final Map<String, Color> categoryColors;
  final Map<String, double> categoryPercent;

  const DetailReportContent({
    super.key,
    required this.title,
    required this.categoryColors,
    required this.categoryPercent,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: categoryPercent.entries
                    .map(
                      (e) => PieChartSectionData(
                        color: categoryColors[e.key],
                        value: e.value,
                        title: "",
                        radius: 55,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Column(
            children: categoryPercent.entries.map((e) {
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
                            color: categoryColors[e.key],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(e.key),
                      ],
                    ),
                    Text(
                      "${e.value.toStringAsFixed(0)}%",
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
}
