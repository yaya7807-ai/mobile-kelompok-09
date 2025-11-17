import 'package:flutter/material.dart';
import 'package:mydompet/report_screen.';
import 'package:mydompet/transaction_screen.dart';
import 'package:mydompet/wallet_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ISI UTAMA
      body: ListView(
        children: [
          _SettingTile(icon: Icons.restore, label: 'Restore Purchased Items'),
          _SettingTile(icon: Icons.check_box, label: 'Remove Ads'),
          _SettingTile(
            icon: Icons.attach_money,
            label: 'Show Decimals',
            trailing: Switch(value: false, onChanged: (val) {}),
          ),
          _SettingTile(icon: Icons.backup, label: 'Backup and Restore Data'),
          _SettingTile(icon: Icons.delete, label: 'Clear Data'),
          _SettingTile(icon: Icons.notifications, label: 'Reminder'),
          _SettingTile(icon: Icons.color_lens, label: 'Theme Color'),
          _SettingTile(icon: Icons.language, label: 'Language'),
        ],
      ),

      // Navigasi bawah (pakai tombol terpisah)
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
              // Tombol Transaksi
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.book, color: Colors.grey),
                    SizedBox(height: 4),
                    Text(
                      'Transaksi',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Tombol Kantong
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalletScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wallet, color: Colors.grey),
                    SizedBox(height: 4),
                    Text(
                      'Kantong',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Tombol Rekap
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart, color: Colors.grey),
                    SizedBox(height: 4),
                    Text(
                      'Rekap',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Tombol Setting (aktif)
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, color: Colors.black),
                    SizedBox(height: 4),
                    Text(
                      'Setting',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;

  const _SettingTile({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black),
          ),
          trailing: trailing,
          onTap: () {},
        ),
        const Divider(height: 1),
      ],
    );
  }
}
