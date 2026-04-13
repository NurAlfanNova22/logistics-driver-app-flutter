import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final int initialTabIndex;
  const OrdersScreen({super.key, this.initialTabIndex = 0});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  List<Order> orders = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    // Filter data
    final activeOrders = orders.where((o) => o.statusPengiriman != 'PESANAN TELAH DIKIRIM').toList();
    final completedOrders = orders.where((o) => o.statusPengiriman == 'PESANAN TELAH DIKIRIM').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.textMutedColor,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          tabs: const [
            Tab(text: 'Daftar Aktif'),
            Tab(text: 'Riwayat Selesai'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(activeOrders),
                _buildOrderList(completedOrders),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<Order> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: context.textMutedColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Tidak ada data pesanan', style: TextStyle(color: context.textSecondaryColor, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final order = list[index];

          return GestureDetector(
            onTap: () async {
               final needsRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order)),
               );
               if (needsRefresh == true) {
                 loadOrders(); // Refresh after confirming in detail screen
               }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.namaPabrik,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: context.textPrimaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.receipt_long_rounded, size: 14, color: context.textMutedColor),
                                  const SizedBox(width: 6),
                                  Text(order.resi, style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(order.statusPengiriman, context),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: context.borderColor),

                  // Details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      children: [
                        _detailRow(Icons.place_rounded, 'Tujuan', order.alamatTujuan, context),
                        const SizedBox(height: 10),
                        _detailRow(Icons.scale_rounded, 'Muatan', '${order.jenisBarang} (${order.berat} ton)', context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        text = 'DI JALAN';
        break;
      case 'pesanan telah dikirim':
        bg = AppColors.successSurface;
        fg = AppColors.success;
        text = 'SELESAI';
        break;
      default:
        bg = AppColors.primarySurface;
        fg = AppColors.primary;
        text = 'MENUNGGU PICKUP';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.textMutedColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$label: ',
              style: TextStyle(fontSize: 13, color: context.textMutedColor, fontFamily: 'Inter', height: 1.4),
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.w600),
                )
              ]
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}