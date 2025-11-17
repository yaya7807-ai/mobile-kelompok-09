import 'package:flutter/material.dart';
import 'package:mydompet/screens/report_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:mydompet/screens/wallet_screen.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // abu-abu muda
      appBar: AppBar(
        backgroundColor: Colors.yellow, // kuning
        foregroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Min, 02 Nov 2024',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
          IconButton(icon: const Icon(Icons.content_copy), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),

      // Isi utama
      body: Column(
        children: [
          // Bagian kartu pemasukan, pengeluaran, selisih
          Container(
            color: Colors.yellow,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _SummaryItem(label: 'Pemasukan', value: '0'),
                  _SummaryItem(label: 'Pengeluaran', value: '0'),
                  _SummaryItem(label: 'Selisih', value: '0'),
                ],
              ),
            ),
          ),

          // Area abu-abu tengah
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 140,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tidak ada data',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Tombol tambah
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.black),
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
                    Icon(Icons.book, color: Colors.black),
                    SizedBox(height: 4),
                    Text(
                      'Transaksi',
                      style: TextStyle(fontSize: 12, color: Colors.black),
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

              // Tombol Setting
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
                    SizedBox(height: 4),
                    Text(
                      'Setting',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
