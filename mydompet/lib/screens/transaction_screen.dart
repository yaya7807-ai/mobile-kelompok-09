import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mydompet/screens/edit_transaction_screen.dart';
import 'package:mydompet/screens/expense_screen.dart';
import 'package:mydompet/screens/income_screen.dart';
import 'package:mydompet/screens/transfer_screen.dart';
import 'package:mydompet/screens/wallet_screen.dart';
import 'package:mydompet/screens/report_screen.dart';
import 'package:mydompet/screens/setting_screen.dart';
import 'package:mydompet/screens/history_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;
  bool isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (isMenuOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  void _closeMenu() {
    _animationController.reverse();
    setState(() {
      isMenuOpen = false;
    });
  }

  String formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount);
  }

  void previousDay() => setState(
    () => selectedDate = selectedDate.subtract(const Duration(days: 1)),
  );
  void nextDay() =>
      setState(() => selectedDate = selectedDate.add(const Duration(days: 1)));

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFFD339),
            onPrimary: Colors.black,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate)
      setState(() => selectedDate = picked);
  }

  void openIncome() {
    _closeMenu();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IncomeScreen()),
    );
  }

  void openExpense() {
    _closeMenu();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseScreen()),
    );
  }

  void openTransfer() {
    _closeMenu();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    );
  }

  void deleteTransaction(
    String docId,
    double amount,
    String type,
    String walletId,
    String? toWalletId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: const Text("Saldo kantong akan dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.runTransaction((
                transaction,
              ) async {
                DocumentReference walletRef = FirebaseFirestore.instance
                    .collection('wallets')
                    .doc(walletId);
                DocumentSnapshot walletSnap = await transaction.get(walletRef);

                if (walletSnap.exists) {
                  int currentBal = walletSnap['balance'];
                  int newBal = currentBal;
                  if (type == 'pemasukan')
                    newBal -= amount.toInt();
                  else if (type == 'pengeluaran')
                    newBal += amount.toInt();
                  else if (type == 'pindah_saldo')
                    newBal += amount.toInt();
                  transaction.update(walletRef, {'balance': newBal});
                }

                if (type == 'pindah_saldo' && toWalletId != null) {
                  DocumentReference toWalletRef = FirebaseFirestore.instance
                      .collection('wallets')
                      .doc(toWalletId);
                  DocumentSnapshot toWalletSnap = await transaction.get(
                    toWalletRef,
                  );
                  if (toWalletSnap.exists) {
                    int toCurrentBal = toWalletSnap['balance'];
                    transaction.update(toWalletRef, {
                      'balance': toCurrentBal - amount.toInt(),
                    });
                  }
                }
                transaction.delete(
                  FirebaseFirestore.instance
                      .collection('transactions')
                      .doc(docId),
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Transaksi dihapus")),
              );
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String formattedDate = DateFormat(
      'EEE, dd MMM yyyy',
      'id_ID',
    ).format(selectedDate);

    DateTime startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      0,
      0,
      0,
    );
    DateTime endOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
      59,
    );

    final Stream<QuerySnapshot> transactionStream = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user?.uid)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFD339),
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            foregroundColor: Colors.black,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: previousDay,
                  icon: const Icon(Icons.chevron_left),
                ),
                GestureDetector(
                  onTap: _selectDate,
                  child: Row(
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: nextDay,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  icon: const Icon(Icons.history),
                ),
              ),
            ],
          ),

          body: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0)
                previousDay();
              else if (details.primaryVelocity! < 0)
                nextDay();
            },
            child: StreamBuilder<QuerySnapshot>(
              stream: transactionStream,
              builder: (context, snapshot) {
                double income = 0;
                double expense = 0;
                List<DocumentSnapshot> docs = [];

                if (snapshot.hasData) {
                  docs = snapshot.data!.docs;
                  for (var doc in docs) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    double amount = (data['jumlah'] ?? 0).toDouble();
                    if (data['tipe'] == 'pemasukan')
                      income += amount;
                    else if (data['tipe'] == 'pengeluaran')
                      expense += amount;
                  }
                }

                return Column(
                  children: [
                    Container(
                      color: const Color(0xFFFFD339),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              label: "Pemasukan",
                              value: "+${formatCurrency(income)}",
                              color: Colors.green,
                            ),
                            _SummaryItem(
                              label: "Pengeluaran",
                              value: formatCurrency(expense),
                              color: Colors.black87,
                            ),
                            _SummaryItem(
                              label: "Selisih",
                              value: (income - expense) >= 0
                                  ? "+${formatCurrency(income - expense)}"
                                  : formatCurrency(income - expense),
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: docs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.receipt_long,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Belum ada transaksi",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  left: 16,
                                  right: 16,
                                  bottom: 150,
                                ),
                                itemCount: docs.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  var doc = docs[index];
                                  Map<String, dynamic> data =
                                      doc.data() as Map<String, dynamic>;
                                  return _buildTransactionItem(doc.id, data);
                                },
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        ),

        // LAYER 2: LATAR PUTIH TRANSPARAN
        if (isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: Container(color: Colors.white.withOpacity(0.92)),
            ),
          ),

        // LAYER 3: MENU ITEMS
        Positioned(
          right: 24,
          bottom: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAnimatedMenuItem(
                index: 2,
                label: "Pindah Saldo",
                iconSvg: "money-bill-transfer-solid-full",
                color: const Color(0xFFA08D45),
                onTap: openTransfer,
              ),
              const SizedBox(height: 20),
              _buildAnimatedMenuItem(
                index: 1,
                label: "Pemasukan",
                iconSvg: "hand-holding-dollar-solid-full",
                color: const Color(0xFF006064),
                onTap: openIncome,
              ),
              const SizedBox(height: 20),
              _buildAnimatedMenuItem(
                index: 0,
                label: "Pengeluaran",
                iconSvg: "basket-shopping-solid-full",
                color: const Color(0xFF00ACC1),
                onTap: openExpense,
              ),
            ],
          ),
        ),

        // LAYER 4: MAIN FAB
        Positioned(
          right: 28,
          bottom: 90,
          child: FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: Colors.white,
            elevation: 4,
            child: RotationTransition(
              turns: _rotateAnimation,
              child: const Icon(Icons.add, color: Colors.black, size: 32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedMenuItem({
    required int index,
    required String label,
    required String iconSvg,
    required Color color,
    required VoidCallback onTap,
  }) {
    final double startInterval = index * 0.1;
    final double endInterval = startInterval + 0.6;

    final Animation<Offset> slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              startInterval,
              endInterval > 1.0 ? 1.0 : endInterval,
              curve: Curves.fastOutSlowIn,
            ),
          ),
        );

    final Animation<double> fadeAnim = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        startInterval,
        endInterval > 1.0 ? 1.0 : endInterval,
        curve: Curves.easeIn,
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnim,
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/icons/$iconSvg.svg',
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String docId, Map<String, dynamic> data) {
    String type = data['tipe'];
    double amount = (data['jumlah'] ?? 0).toDouble();
    String title = data['judul'] ?? 'Tanpa Judul';
    String category = data['kategori'] ?? '';
    Color amountColor = Colors.black;
    String amountPrefix = "";
    String subtitle = category;

    if (type == 'pemasukan') {
      amountColor = Colors.green;
      amountPrefix = "+";
    } else if (type == 'pengeluaran') {
      amountColor = Colors.black87;
      amountPrefix = "-";
    } else if (type == 'pindah_saldo') {
      amountColor = Colors.black54;
      String from = data['walletName'] ?? '?';
      String to = data['toWalletName'] ?? '?';
      subtitle = "$from \u2192 $to";
    }

    return InkWell(
      onLongPress: () => deleteTransaction(
        docId,
        amount,
        type,
        data['walletId'],
        data['toWalletId'],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EditTransactionScreen(docId: docId, data: data),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
            _navItem(Icons.book, "Transaksi", true, const TransactionScreen()),
            _navItem(Icons.wallet, "Kantong", false, const WalletScreen()),
            _navItem(Icons.bar_chart, "Rekap", false, const ReportScreen()),
            _navItem(Icons.settings, "Setting", false, const SettingScreen()),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, Widget screen) {
    return TextButton(
      onPressed: active
          ? null
          : () {
              // 🔥 UPDATE: MENGHILANGKAN ANIMASI PINDAH HALAMAN 🔥
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) => screen,
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
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

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryItem({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
