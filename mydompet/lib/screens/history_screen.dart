import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> allTransactions;

  const HistoryScreen({super.key, required this.allTransactions});

  @override
  Widget build(BuildContext context) {
    // Urutkan transaksi berdasarkan tanggal terbaru
    final sortedTx = [...allTransactions];
    sortedTx.sort((a, b) => b["tanggal"].compareTo(a["tanggal"]));

    return Scaffold(
      appBar: AppBar(
        title: const Text("History Transaksi"),
        backgroundColor: Colors.amber,
      ),
      body: sortedTx.isEmpty
          ? const Center(
              child: Text(
                "Belum ada history transaksi",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: sortedTx.length,
              itemBuilder: (context, index) {
                final t = sortedTx[index];
                final formattedDate = DateFormat(
                  'dd MMM yyyy',
                  'id_ID',
                ).format(t["tanggal"]);

                return ListTile(
                  leading: Icon(
                    t["tipe"] == "pemasukan"
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: t["tipe"] == "pemasukan" ? Colors.green : Colors.red,
                  ),
                  title: Text(t["judul"]),
                  subtitle: Text("${t["kategori"]} • $formattedDate"),
                  trailing: Text(
                    (t["tipe"] == "pemasukan" ? "+ " : "- ") +
                        t["jumlah"].toString(),
                    style: TextStyle(
                      color: t["tipe"] == "pemasukan"
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
