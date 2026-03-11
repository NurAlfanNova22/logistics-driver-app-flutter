import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {

  List<Order> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {

    try {

      final data = await ApiService.getDriverOrders(1);

      setState(() {
        orders = data;
        isLoading = false;
      });

    } catch (e) {

      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });

    }

  }

  Future<void> updateStatus(int orderId) async {

    final success = await ApiService.updateStatus(orderId);

    if (success) {
      loadOrders();
    }

  }

  void showConfirmDialog(Order order) {

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(

          title: const Text("Konfirmasi"),

          content: const Text(
              "Apakah Anda yakin ingin memperbarui status pengiriman?"),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),

            ElevatedButton(
              onPressed: () {

                updateStatus(order.id);

                Navigator.pop(context);

              },
              child: const Text("Ya"),
            ),

          ],
        );

      },
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesanan Saya"),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),

              child: ListView.builder(
                itemCount: orders.length,

                itemBuilder: (context, index) {

                  final order = orders[index];

                  String buttonText = "";

                  if (order.statusPengiriman == "MENUNGGU PICKUP") {
                    buttonText = "Mulai Pengiriman";
                  } else {
                    buttonText = "Selesaikan";
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text("Resi : ${order.resi}"),

                          const SizedBox(height: 4),

                          Text("Pabrik : ${order.namaPabrik}"),
                          Text("Dari : ${order.alamatAsal}"),
                          Text("Tujuan : ${order.alamatTujuan}"),
                          Text("Barang : ${order.jenisBarang}"),
                          Text("Berat : ${order.berat} ton"),

                          const SizedBox(height: 8),

                          Text(
                            "Status Pengiriman : ${order.statusPengiriman}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          if (order.statusPengiriman != "SELESAI")

                            ElevatedButton(
                              onPressed: () {
                                showConfirmDialog(order);
                              },
                              child: Text(buttonText),
                            )

                        ],
                      ),
                    ),
                  );

                },
              ),
            ),

    );

  }

}