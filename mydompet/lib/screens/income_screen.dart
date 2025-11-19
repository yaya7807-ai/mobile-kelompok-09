import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  String? selectedMethod;

  final List<String> paymentMethods = [
    "Uang Tunai",
    "Rekening Bank",
    "E-Wallet",
  ];

  /// =============================
  ///  PICK DATE
  /// =============================
  Future<void> pickDate() async {
    DateTime? result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: selectedDate,
    );

    if (result != null) {
      setState(() => selectedDate = result);
    }
  }

  /// =============================
  ///  PICK TIME
  /// =============================
  Future<void> pickTime() async {
    TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (result != null) {
      setState(() => selectedTime = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),

      // ====================== APP BAR ======================
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD339),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pemasukan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= DATE + TIME =================
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.brown.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          DateFormat(
                            "EEE, dd MMM yyyy",
                            "id_ID",
                          ).format(selectedDate),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  GestureDetector(
                    onTap: pickTime,
                    child: Container(
                      width: 85,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.brown.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        "${selectedTime.hour.toString().padLeft(2, '0')} : ${selectedTime.minute.toString().padLeft(2, '0')}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ================= METODE PEMBAYARAN =================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown.withOpacity(0.4)),
                ),
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(border: InputBorder.none),
                  hint: const Text("Metode Pemasukan"),
                  value: selectedMethod,
                  items: paymentMethods.map((item) {
                    return DropdownMenuItem(value: item, child: Text(item));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedMethod = value);
                  },
                ),
              ),

              const SizedBox(height: 15),

              // ================= INPUT =================
              buildTextField("Jumlah", amountController),
              const SizedBox(height: 15),

              buildTextField("Judul Pemasukan", titleController),
              const SizedBox(height: 15),

              buildTextField("Kategori Pemasukan", categoryController),
              const SizedBox(height: 25),

              // ================= BUTTON SIMPAN =================
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                    backgroundColor: const Color(0xFFFFD339),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // ======= KIRIM DATA KE TRANSACTIONSREEN =======
                  onPressed: () {
                    final data = {
                      "judul": titleController.text,
                      "jumlah": double.tryParse(amountController.text) ?? 0,
                      "kategori": categoryController.text,
                      "metode": selectedMethod,
                      "tanggal": selectedDate,
                      "tipe": "pemasukan",
                    };

                    Navigator.pop(context, data);
                  },

                  child: const Text(
                    "Simpan",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TEXTFIELD BUILDER =================
  Widget buildTextField(String hint, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.withOpacity(0.4)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(border: InputBorder.none, hintText: hint),
      ),
    );
  }
}
