import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  final List<String> avatarList = [
    'profile-1.jpg',
    'profile-2.jpg',
    'profile-3.jpg',
    'profile-4.jpg',
    'profile-5.jpg',
    'profile-6.jpeg',
    'profile-7.jpeg',
    'profile-8.jpeg',
  ];

  // Format Mata Uang
  String formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  //update Data User
  Future<void> _updateUserData({
    String? name,
    String? phone,
    String? photo,
  }) async {
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      if (name != null) 'fullName': name,
      if (phone != null) 'phoneNumber': phone,
      if (photo != null) 'profilePic': photo,
      'email': user!.email,
    }, SetOptions(merge: true));

    setState(() {});
  }

  // Dialog: Edit Nama & No HP
  void _showEditDialog(String currentName, String currentPhone) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Lengkap"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Nomor Telepon"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              _updateUserData(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
            child: const Text("Simpan", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Foto Profil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: avatarList.length,
                  itemBuilder: (context, index) {
                    final fileName = avatarList[index];
                    return GestureDetector(
                      onTap: () {
                        _updateUserData(photo: fileName);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipOval(
                          child: Transform.scale(
                            scale: 1.1,
                            child: Image.asset(
                              'assets/images/$fileName',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .snapshots();

    final walletsStream = FirebaseFirestore.instance
        .collection('wallets')
        .where('userId', isEqualTo: user?.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Profil Saya",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: userDocStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              return IconButton(
                onPressed: () => _showEditDialog(
                  data?['fullName'] ?? '',
                  data?['phoneNumber'] ?? '',
                ),
                icon: const Icon(Icons.edit),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: userDocStream,
                builder: (context, snapshot) {
                  String profilePic = '';
                  String name = 'Orang';
                  String email = user?.email ?? 'Tidak ada email';
                  String phone = 'Nomor tidak diset';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    profilePic = data['profilePic'] ?? '';
                    name = (data['fullName'] == null || data['fullName'] == '')
                        ? 'Orang'
                        : data['fullName'];
                    phone =
                        (data['phoneNumber'] == null ||
                            data['phoneNumber'] == '')
                        ? 'Nomor tidak diset'
                        : data['phoneNumber'];
                  }

                  String imagePath = profilePic;
                  if (profilePic.isNotEmpty && !profilePic.contains('.')) {
                    imagePath = '$profilePic.jpg';
                  }

                  return Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.yellow,
                                width: 3,
                              ),
                              color: Colors.grey[200],
                            ),
                            child: ClipOval(
                              child: profilePic.isNotEmpty
                                  ? Transform.scale(
                                      scale: 1.15,
                                      child: Image.asset(
                                        'assets/images/$imagePath',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              );
                                            },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showAvatarPicker,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.yellow,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(phone, style: const TextStyle(fontSize: 16)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),

              // --- BAGIAN TOTAL SALDO ---
              StreamBuilder<QuerySnapshot>(
                stream: walletsStream,
                builder: (context, snapshot) {
                  double totalBalance = 0;

                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      totalBalance += (doc['balance'] ?? 0).toDouble();
                    }
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Total Aset Saya",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatCurrency(totalBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
