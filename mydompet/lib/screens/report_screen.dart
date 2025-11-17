import 'package:flutter/material.dart';
import 'package:mydompet/screens/wallet_screen.dart';
import 'package:mydompet/screens/transaction_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedTab = 'Hari Ini';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Rekap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // Tombol tab: Hari Ini / Mingguan / Bulanan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton('Hari Ini'),
                _buildTabButton('Mingguan'),
                _buildTabButton('Bulanan'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Konten sesuai tab
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: _buildTabContent(),
            ),
          ),
        ],
      ),

      // Navigasi bawah (tetap tombol terpisah)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navButton(
                context,
                Icons.book,
                'Transaksi',
                const TransactionScreen(),
                false,
              ),
              _navButton(
                context,
                Icons.wallet,
                'Kantong',
                const WalletScreen(),
                false,
              ),
              _navButton(context, Icons.bar_chart, 'Rekap', null, true),
              _navButton(
                context,
                Icons.settings,
                'Setting',
                const SettingScreen(),
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final bool isSelected = selectedTab == label;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              selectedTab = label;
            });
          },
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

  Widget _buildTodayReport() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.pie_chart, size: 100, color: Colors.teal),
          SizedBox(height: 8),
          Text('Data Hari Ini', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildWeeklyReport() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.show_chart, size: 100, color: Colors.orange),
          SizedBox(height: 8),
          Text('Data Mingguan', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bar_chart, size: 100, color: Colors.blue),
          SizedBox(height: 8),
          Text('Data Bulanan', style: TextStyle(fontSize: 16)),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        }
      },
      style: TextButton.styleFrom(foregroundColor: Colors.black),
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
