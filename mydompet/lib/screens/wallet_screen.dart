import 'package:flutter/material.dart';
import 'package:mydompet/screens/report_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:mydompet/screens/transaction_screen.dart';
import 'package:mydompet/screens/edit_balance_screen.dart';
import 'package:mydompet/screens/create_pocket_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> wallets = [
    {'icon': Icons.attach_money, 'name': 'Uang Tunai', 'balance': 120000},
    {'icon': Icons.account_balance, 'name': 'Rekening', 'balance': 450000},
    {'icon': Icons.wallet, 'name': 'E-Wallet', 'balance': 220000},
    {'icon': Icons.add, 'name': 'Buat Kantong', 'balance': null},
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredWallets = wallets
        .where(
          (item) =>
              item['name'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();

    int totalBalance = wallets
        .where((w) => w['balance'] != null)
        .fold(0, (sum, w) => sum + (w['balance'] as int));

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🔥 Hilangkan tombol back
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFFFC107),
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // 🔍 Search Bar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                      decoration: const InputDecoration(
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
            // 📌 Total Aset
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
                    "Rp $totalBalance",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 🧱 Grid View
            Expanded(
              child: GridView.builder(
                itemCount: filteredWallets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final wallet = filteredWallets[index];
                  final bool isAdd = wallet['balance'] == null;

                  return GestureDetector(
                    onTap: () {
                      if (isAdd) {
                        // ➤ MASUK KE HALAMAN BUAT KANTONG
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePocketScreen(
                              onCreate: (name, balance) {
                                setState(() {
                                  wallets.insert(wallets.length - 1, {
                                    'icon': Icons.wallet,
                                    'name': name,
                                    'balance': balance,
                                  });
                                });
                              },
                            ),
                          ),
                        );
                      } else {
                        // ➤ MASUK KE HALAMAN EDIT / UPDATE SALDO
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditBalanceScreen(
                              name: wallet['name'],
                              balance: wallet['balance'],
                              onUpdate: (newBalance) {
                                setState(() {
                                  wallet['balance'] = newBalance;
                                });
                              },
                            ),
                          ),
                        );
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

      // 🔻 Bottom Nav
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
