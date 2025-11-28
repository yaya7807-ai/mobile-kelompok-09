import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mydompet/screens/create_pocket_screen.dart';
import 'package:mydompet/screens/report_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:mydompet/screens/transaction_screen.dart';
// import 'package:mydompet/screens/edit_balance_screen.dart'; // Aktifkan jika sudah ada

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  // Helper untuk mendapatkan icon berdasarkan string (opsional)
  IconData getIcon(String iconName) {
    switch (iconName) {
      case 'money':
        return Icons.attach_money;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil User ID
    final user = FirebaseAuth.instance.currentUser;

    // Stream Query: Ambil kantong milik user ini
    final Stream<QuerySnapshot> walletsStream = FirebaseFirestore.instance
        .collection('wallets')
        .where('userId', isEqualTo: user?.uid)
        // .orderBy('createdAt', descending: false)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // --- APP BAR (Sama seperti sebelumnya) ---
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
                  // Search Bar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Cari Kantong',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        contentPadding: EdgeInsets.only(top: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // --- BODY DENGAN STREAM BUILDER ---
      body: StreamBuilder<QuerySnapshot>(
        stream: walletsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 1. Ambil data dari Firebase
          final docs = snapshot.data?.docs ?? [];

          // 2. Hitung Total Aset
          double totalBalance = 0;

          // 3. Konversi data Firebase ke List Objek agar mudah diolah & difilter
          List<Map<String, dynamic>> allWallets = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final balance = (data['balance'] ?? 0).toDouble();

            // Tambahkan ke total
            totalBalance += balance;

            return {
              'id': doc.id,
              'name': data['name'] ?? 'Tanpa Nama',
              'balance': balance,
              'icon': data['icon'] ?? 'wallet',
            };
          }).toList();

          // 4. Filter berdasarkan Search Query
          List<Map<String, dynamic>> filteredWallets = allWallets
              .where(
                (w) => w['name'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📌 Total Aset Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Aset Saya',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Rp ${totalBalance.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 🧱 Grid View (Wallet + Tombol Tambah)
                Expanded(
                  child: GridView.builder(
                    // Jumlah item = jumlah kantong + 1 (untuk tombol tambah)
                    itemCount: filteredWallets.length + 1,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                    itemBuilder: (context, index) {
                      // Logika Tombol "Buat Kantong" (Item Terakhir)
                      if (index == filteredWallets.length) {
                        return _buildAddButton(context);
                      }

                      // Logika Kartu Kantong
                      final wallet = filteredWallets[index];
                      return _buildWalletCard(wallet);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // --- BOTTOM NAV (Tetap Sama) ---
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // Widget Kartu Kantong Biasa
  Widget _buildWalletCard(Map<String, dynamic> wallet) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke Edit Balance jika diperlukan
        // Navigator.push(...);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF00695C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(getIcon(wallet['icon']), color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              wallet['name'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Rp ${wallet['balance'].toStringAsFixed(0)}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Tombol Tambah
  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePocketScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Colors.black, size: 32),
            SizedBox(height: 8),
            Text(
              "Buat Kantong",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Bottom Nav (Saya ekstrak biar rapi)
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
              const ReportScreen(),
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
