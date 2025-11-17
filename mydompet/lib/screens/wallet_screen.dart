import 'package:flutter/material.dart';
import 'package:mydompet/screens/report_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:mydompet/screens/transaction_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> wallets = [
      {
        'icon': Icons.currency_bitcoin,
        'name': 'Kantong Utama',
        'balance': 120000,
      },
      {'icon': Icons.phone_android, 'name': 'Nabung Iqeng', 'balance': 80000},
      {
        'icon': Icons.account_balance_wallet,
        'name': 'Gopay',
        'balance': 200000,
      },
      {'icon': Icons.monetization_on, 'name': 'Dana', 'balance': 100000},
      {'icon': Icons.account_balance, 'name': 'BCA', 'balance': 50000},
      {'icon': Icons.add, 'name': 'Buat Kantong', 'balance': null},
    ];

    int totalBalance = wallets
        .where((w) => w['balance'] != null)
        .fold(0, (sum, w) => sum + (w['balance'] as int));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          backgroundColor: const Color(0xFFFFC107), // warna kuning
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari Kantong',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Aset Saya
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Aset Saya',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Rp ${totalBalance.toString()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid of wallets
            Expanded(
              child: GridView.builder(
                itemCount: wallets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  final bool isAdd = wallet['balance'] == null;

                  return GestureDetector(
                    onTap: () {
                      if (isAdd) {
                        // aksi tambah kantong
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isAdd ? Colors.white : const Color(0xFF00695C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            wallet['icon'],
                            color: isAdd ? Colors.black : Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            wallet['name'],
                            style: TextStyle(
                              color: isAdd ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isAdd)
                            Text(
                              "Rp ${wallet['balance']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation bar (tetap sama)
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
              _navButton(context, Icons.wallet, 'Kantong', null, true),
              _navButton(
                context,
                Icons.bar_chart,
                'Rekap',
                ReportScreen(),
                false,
              ),
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
