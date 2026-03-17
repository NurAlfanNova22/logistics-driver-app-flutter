import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int sopirId = prefs.getInt('sopir_id') ?? 0;
      final data = await ApiService.getDriverOrders(sopirId);
      if (mounted) {
        setState(() {
          orders = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> updateStatus(int orderId) async {
    final success = await ApiService.updateStatus(orderId);
    if (success) {
      await loadOrders();
      LocationService().checkAndToggleTracking();
    }
  }

  void showConfirmDialog(Order order) {
    final action = order.statusPengiriman == 'MENUNGGU PICKUP'
        ? 'memulai pengiriman'
        : 'menandai pesanan sebagai telah dikirim';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: TextStyle(color: context.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              updateStatus(order.id);
              Navigator.pop(context);
            },
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 56, color: context.textMutedColor),
                      const SizedBox(height: 12),
                      Text('Belum ada pesanan aktif',
                          style: TextStyle(
                              color: context.textSecondaryColor)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: loadOrders,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final isCompleted =
                          order.statusPengiriman == 'PESANAN TELAH DIKIRIM';
                      final buttonText =
                          order.statusPengiriman == 'MENUNGGU PICKUP'
                              ? 'Mulai Pengiriman'
                              : 'Tandai Telah Dikirim';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.namaPabrik,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: context.textPrimaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.receipt_outlined,
                                                size: 12,
                                                color: context.textMutedColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              order.resi,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.textMutedColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  _statusBadge(order.statusPengiriman, context),
                                ],
                              ),
                            ),

                            Divider(
                                height: 1,
                                color: context.borderColor),

                            // Details
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Column(
                                children: [
                                  _detailRow(
                                      Icons.my_location_rounded,
                                      'Dari',
                                      order.alamatAsal,
                                      context),
                                  const SizedBox(height: 6),
                                  _detailRow(
                                      Icons.location_on_rounded,
                                      'Tujuan',
                                      order.alamatTujuan,
                                      context),
                                  const SizedBox(height: 6),
                                  _detailRow(
                                      Icons.inventory_2_outlined,
                                      'Barang',
                                      '${order.jenisBarang} • ${order.berat} ton',
                                      context),
                                ],
                              ),
                            ),

                            // Action button
                            if (!isCompleted)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: () => showConfirmDialog(order),
                                    child: Text(buttonText),
                                  ),
                                ),
                              ),

                            if (isCompleted)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 16, color: AppColors.success),
                                    const SizedBox(width: 6),
                                    Text('Pengiriman selesai',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w500,
                                        )),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _statusBadge(String status, BuildContext context) {
    final s = status.toLowerCase();
    Color bg, fg;
    String text;
    switch (s) {
      case 'dalam perjalanan':
        bg = AppColors.infoSurface;
        fg = AppColors.info;
        text = 'AKTIF';
        break;
      case 'pesanan telah dikirim':
        bg = AppColors.successSurface;
        fg = AppColors.success;
        text = 'DIKIRIM';
        break;
      default:
        bg = AppColors.primarySurface;
        fg = AppColors.primary;
        text = 'MENUNGGU';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }

  Widget _detailRow(
      IconData icon, String label, String value, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: context.textMutedColor),
        const SizedBox(width: 6),
        Text('$label: ',
            style:
                TextStyle(fontSize: 12, color: context.textMutedColor)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}