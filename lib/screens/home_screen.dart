import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool isOnline = true;

  int hariIni = 0;
  int bulanIni = 0;

  @override
  void initState() {
    super.initState();
    getDriverStats();
  }

  Future<void> getDriverStats() async {

    try {

      final data = await ApiService.getDriverStats(1);

      setState(() {
        hariIni = data["hari_ini"] ?? 0;
        bulanIni = data["bulan_ini"] ?? 0;
      });

    } catch (e) {

      debugPrint(e.toString());

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Dashboard Driver",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // STATUS DRIVER
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

                    const Text(
                      "Status Driver",
                      style: TextStyle(fontSize: 16),
                    ),

                    Switch(
                      value: isOnline,
                      onChanged: (value) {
                        setState(() {
                          isOnline = value;
                        });
                      },
                    )

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Statistik Pengiriman",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                StatCard(
                  title: "Hari Ini",
                  value: hariIni.toString(),
                ),

                StatCard(
                  title: "Bulan Ini",
                  value: bulanIni.toString(),
                ),

              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Menu",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {

                  // nanti bisa navigasi ke orders
                  // Navigator.push(...)

                },
                child: const Text("Lihat Pesanan"),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Riwayat Order"),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Buka Map"),
              ),
            ),

          ],
        ),
      ),
    );

  }
}

class StatCard extends StatelessWidget {

  final String title;
  final String value;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),

      child: SizedBox(
        width: 150,
        height: 90,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(title),

            const SizedBox(height: 6),

            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )

          ],
        ),
      ),
    );

  }
}