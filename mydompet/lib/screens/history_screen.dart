import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mydompet/screens/edit_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Helper Format Rupiah
  String formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final Stream<QuerySnapshot> transactionStream = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // --- WARNA KEMBALI KUNING ---
        backgroundColor: const Color(0xFFFFD339),
        foregroundColor: Colors.black, // Teks & Ikon jadi Hitam
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Riwayat",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          // --- KOLOM PENCARIAN ---
          Container(
            color: const Color(
              0xFFFFD339,
            ), // Background Kuning menyatu dengan AppBar
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Cari transaksi...",
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchQuery = "");
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // --- LIST DATA ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: transactionStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // 1. FILTER DATA (PENCARIAN)
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['judul'] ?? '').toString().toLowerCase();
                  final category = (data['kategori'] ?? '')
                      .toString()
                      .toLowerCase();
                  final query = searchQuery.toLowerCase();

                  return title.contains(query) || category.contains(query);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "Tidak ada riwayat transaksi",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // 2. KELOMPOKKAN DATA PER HARI
                Map<String, List<DocumentSnapshot>> groupedData = {};
                for (var doc in filteredDocs) {
                  DateTime date = (doc['createdAt'] as Timestamp).toDate();
                  String dateKey = DateFormat('yyyy-MM-dd').format(date);

                  if (!groupedData.containsKey(dateKey)) {
                    groupedData[dateKey] = [];
                  }
                  groupedData[dateKey]!.add(doc);
                }

                List<String> sortedKeys = groupedData.keys.toList();

                return ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    String dateKey = sortedKeys[index];
                    List<DocumentSnapshot> dayTransactions =
                        groupedData[dateKey]!;

                    // Hitung Total Harian
                    double dayIncome = 0;
                    double dayExpense = 0;

                    for (var t in dayTransactions) {
                      String type = t['tipe'];
                      double amount = (t['jumlah'] ?? 0).toDouble();
                      if (type == 'pemasukan')
                        dayIncome += amount;
                      else if (type == 'pengeluaran')
                        dayExpense += amount;
                    }

                    // Parse Tanggal
                    DateTime dateObj = DateTime.parse(dateKey);
                    String dayNum = DateFormat('dd').format(dateObj);
                    String monthYear = DateFormat('MM yyyy').format(dateObj);
                    String dayName = DateFormat(
                      'EEEE',
                      'id_ID',
                    ).format(dateObj);

                    return Column(
                      children: [
                        // HEADER TANGGAL
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: Colors.grey[100],
                          child: Row(
                            children: [
                              Text(
                                dayNum,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    monthYear,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      dayName,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),

                              // Ringkasan Kanan
                              if (dayIncome > 0)
                                Text(
                                  "+${formatCurrency(dayIncome)}",
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),

                              if (dayIncome > 0 && dayExpense > 0)
                                const SizedBox(width: 10),

                              if (dayExpense > 0)
                                Text(
                                  "-${formatCurrency(dayExpense)}",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // LIST ITEM
                        ...dayTransactions.map((doc) {
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;
                          return _buildHistoryItem(doc.id, data);
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String docId, Map<String, dynamic> data) {
    String type = data['tipe'];
    double amount = (data['jumlah'] ?? 0).toDouble();
    String title = data['judul'] ?? 'Tanpa Judul';
    String category = data['kategori'] ?? '';

    Color amountColor = Colors.black87;
    String amountPrefix = "-";

    if (type == 'pemasukan') {
      amountColor = Colors.teal;
      amountPrefix = "+";
    } else if (type == 'pindah_saldo') {
      amountPrefix = "";
      amountColor = Colors.black54;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EditTransactionScreen(docId: docId, data: data),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (category.isNotEmpty)
                    Text(
                      category,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  "$amountPrefix${formatCurrency(amount)}",
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
