import 'package:flutter/material.dart';
import '../models/order.dart';
import '../app_theme.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _currentOrder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _updateStatus() async {
    setState(() => _isLoading = true);
    final success = await ApiService.updateStatus(_currentOrder.id);
    if (success) {
      if (mounted) {
        LocationService().checkAndToggleTracking(); // toggle loc tracking
        Navigator.pop(context, true); // kembalikan true agar layar luar me-refresh
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal Memproses Pesanan')));
      }
    }
  }

  void _showConfirmDialog() {
    if (_currentOrder.statusPengiriman == 'DALAM PERJALANAN') {
       // Cooldown check for marking as completed
       final diff = DateTime.now().toUtc().difference(_currentOrder.updatedAt.toUtc());
       if (diff.inMinutes < 5) {
          showDialog(
             context: context,
             builder: (c) => AlertDialog(
                title: const Text('Perjalanan Masih Baru 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                content: const Text('Anda baru saja memulai pengiriman ini kurang dari 5 menit yang lalu.\n\nSistem mengunci penyelesaian untuk sementara waktu. Mohon selesaikan dan antarkan muatan dengan aman baru ulangi konfirmasi Anda.'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text('Baik, Mengerti', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ]
             )
          );
          return;
       }
    }

    final action = _currentOrder.statusPengiriman == 'MENUNGGU PICKUP'
        ? 'memeriksa kelengkapan muatan dan MEMULAI pengiriman'
        : 'MENYELESAIKAN pesanan ini';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin $action?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: context.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ya, Lanjutkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
         color: context.surfaceColor,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: context.borderColor),
      ),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textMutedColor, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            ...children,
         ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, BuildContext context, {bool isLarge = false}) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 14),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Container(
             margin: const EdgeInsets.only(top: 2),
             padding: const EdgeInsets.all(6),
             decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
             child: Icon(icon, size: 18, color: AppColors.primary),
           ),
           const SizedBox(width: 14),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(label, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                 const SizedBox(height: 4),
                 Text(value, style: TextStyle(fontSize: isLarge ? 16 : 14, fontWeight: isLarge ? FontWeight.w700 : FontWeight.w600, color: context.textPrimaryColor)),
               ],
             ),
           ),
         ],
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _currentOrder.statusPengiriman == 'PESANAN TELAH DIKIRIM';
    final buttonText = _currentOrder.statusPengiriman == 'MENUNGGU PICKUP'
        ? 'Ambil & Mulai Pengiriman'
        : 'Tandai Selesai & Terkirim';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengiriman'),
        backgroundColor: context.surfaceColor,
        elevation: 1,
        foregroundColor: context.textPrimaryColor,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero banner
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.successSurface : AppColors.primarySurface, 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Column(
                  children: [
                     Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.local_shipping_rounded, 
                        size: 48, 
                        color: isCompleted ? AppColors.success : AppColors.primary
                     ),
                     const SizedBox(height: 12),
                     Text(_currentOrder.statusPengiriman.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, color: isCompleted ? AppColors.success : AppColors.primaryDark, fontSize: 16)),
                     const SizedBox(height: 4),
                     Text('NO RESI: ${_currentOrder.resi}', style: TextStyle(color: isCompleted ? AppColors.success : AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),

              _buildSection('INFORMASI MUATAN', [
                _buildRow(Icons.business_rounded, 'Kustomer / Nama Pabrik', _currentOrder.namaPabrik, context, isLarge: true),
                _buildRow(Icons.inventory_2_rounded, 'Jenis Barang Dimuat', _currentOrder.jenisBarang, context),
                _buildRow(Icons.scale_rounded, 'Total Tonase Berat', '${_currentOrder.berat} Ton', context, isLarge: true),
              ], context),

              _buildSection('RUTE PENGIRIMAN', [
                _buildRow(Icons.my_location_rounded, 'Lokasi Pengambilan (Asal)', _currentOrder.alamatAsal, context),
                _buildRow(Icons.location_on_rounded, 'Titik Bongkar (Tujuan)', _currentOrder.alamatTujuan, context, isLarge: true),
              ], context),
              const SizedBox(height: 20),
            ],
      ),
      bottomNavigationBar: isCompleted 
        ? null
        : Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.borderColor, width: 0.5))),
            child: SizedBox(
               height: 52,
               width: double.infinity,
               child: ElevatedButton(
                  onPressed: _isLoading ? null : _showConfirmDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
               )
            ),
        ),
    );
  }
}
