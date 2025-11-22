import 'package:flutter/material.dart';
import 'package:mydompet/screens/report_screen.dart';
import 'package:mydompet/screens/transaction_screen.dart';
import 'package:mydompet/screens/wallet_screen.dart';
import 'profile_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        children: [
          _SettingTile(
            icon: Icons.person,
            label: 'Profil',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),

      // 🔻 Bottom Nav (versi rapi seperti contohmu)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.white)),
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
              _navButton(
                context,
                Icons.bar_chart,
                'Rekap',
                const ReportScreen(),
                false,
              ),
              _navButton(
                context,
                Icons.settings,
                'Setting',
                null, // halaman ini aktif
                true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔘 NAV BUTTON — sama persis format seperti contohmu
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text("Apakah Anda ingin logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Berhasil logout")),
                );
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black),
          ),
          title: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
