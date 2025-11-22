class TransactionModel {
  final String name;
  final String category;
  final double amount;
  final String type; // "income" / "expense"
  final DateTime date;

  TransactionModel({
    required this.name,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });
}
