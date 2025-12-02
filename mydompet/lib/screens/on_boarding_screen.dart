import 'package:flutter/material.dart';
import 'package:mydompet/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  List<Map<String, String>> data = [
    {
      "title": "SAFE",
      "desc": "Kelola dan catat keuanganmu dengan aman dan rapi.",
      "img": "assets/images/onboard1.png",
    },
    {
      "title": "SMART",
      "desc": "Pantau pemasukan dan pengeluaranmu kapan saja, tanpa ribet.",
      "img": "assets/images/onboard2.png",
    },
    {
      "title": "TRACK",
      "desc":
          "Lihat riwayat transaksi harian hingga bulanan, semuanya dalam satu aplikasi.",
      "img": "assets/images/onboard3.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: PageView.builder(
              controller: _pageController,
              itemCount: data.length,
              onPageChanged: (value) {
                setState(() {
                  currentIndex = value;
                });
              },
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBC02D), // kuning background
                        ),
                        child: Center(
                          child: Image.asset(data[index]["img"]!, height: 400),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // TEXT TITLE
          Text(
            data[currentIndex]["title"]!,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          // TEXT DESKRIPSI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              data[currentIndex]["desc"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),

          const SizedBox(height: 25),

          // INDICATOR
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              data.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: currentIndex == index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: currentIndex == index
                      ? Colors.amber
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),

          const SizedBox(height: 35),

          // TOMBOL NEXT / MULAI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: GestureDetector(
              onTap: () {
                if (currentIndex == data.length - 1) {
                  // pindah ke home/login
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    currentIndex == data.length - 1 ? "Mulai" : "Lanjut",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
