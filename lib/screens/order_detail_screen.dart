import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order.dart';
import '../app_theme.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _currentOrder;
  bool _isLoading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  Future<void> _updateStatus({String? filePath}) async {
    setState(() => _isLoading = true);
    final success = await ApiService.updateStatus(_currentOrder.id, filePath: filePath);
    if (success) {
      if (mounted) {
        // Tunggu sebentar agar server selesai memproses status sebelum kita fetch ulang untuk tracking
        Future.delayed(const Duration(seconds: 1), () {
            LocationService().checkAndToggleTracking(); 
        });
        Navigator.pop(context, true); // kembalikan true agar layar luar me-refresh
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal Memproses Pesanan. Harap coba lagi.')));
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

       // Reset selected image file
       _imageFile = null;

       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (context) {
           return StatefulBuilder(
             builder: (context, setDialogState) {
               return AlertDialog(
                 title: const Text('Bukti Pengiriman 📸', style: TextStyle(fontWeight: FontWeight.bold)),
                 content: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Text('Sopir wajib mengambil foto bukti pengiriman (barang tiba di tujuan) sebelum menandai pesanan terkirim.'),
                     const SizedBox(height: 16),
                     _imageFile != null
                         ? Container(
                             height: 150,
                             width: double.infinity,
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Colors.grey.shade300),
                               image: DecorationImage(
                                 image: FileImage(_imageFile!),
                                 fit: BoxFit.cover,
                               ),
                             ),
                           )
                         : Container(
                             height: 150,
                             width: double.infinity,
                             decoration: BoxDecoration(
                               color: Colors.grey.shade100,
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                             ),
                             child: const Center(
                               child: Column(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Icon(Icons.camera_alt_rounded, size: 40, color: Colors.grey),
                                   SizedBox(height: 8),
                                   Text('Belum ada foto terpilih', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                 ],
                               ),
                             ),
                           ),
                     const SizedBox(height: 16),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                       children: [
                         ElevatedButton.icon(
                           onPressed: () async {
                             await _pickImage(ImageSource.camera);
                             setDialogState(() {});
                           },
                           icon: const Icon(Icons.camera_alt_rounded, size: 18),
                           label: const Text('Kamera'),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primary,
                             foregroundColor: Colors.white,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                           ),
                         ),
                         ElevatedButton.icon(
                           onPressed: () async {
                             await _pickImage(ImageSource.gallery);
                             setDialogState(() {});
                           },
                           icon: const Icon(Icons.photo_library_rounded, size: 18),
                           label: const Text('Galeri'),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.grey.shade600,
                             foregroundColor: Colors.white,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 actions: [
                   TextButton(
                     onPressed: () => Navigator.pop(context),
                     child: Text('Batal', style: TextStyle(color: context.textSecondaryColor)),
                   ),
                   ElevatedButton(
                     onPressed: _imageFile == null
                         ? null
                         : () {
                             Navigator.pop(context);
                             _updateStatus(filePath: _imageFile!.path);
                           },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       disabledBackgroundColor: Colors.grey.shade300,
                     ),
                     child: const Text('Kirim & Selesaikan', style: TextStyle(color: Colors.white)),
                   ),
                 ],
               );
             },
           );
         },
       );
       return;
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

  Future<void> _openMap(String address, String? coordinate) async {
    final destination = coordinate != null && coordinate.trim().isNotEmpty 
        ? coordinate 
        : Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$destination");
    
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka peta: $e')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(launchUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat melakukan panggilan: $e')),
        );
      }
    }
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
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textMutedColor, letterSpacing: 1.0)),
            const SizedBox(height: 16),
            ...children,
         ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, BuildContext context, {bool isLarge = false, Widget? trailing}) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 14),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.center,
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
                 Text(value, style: TextStyle(fontSize: isLarge ? 16 : 14, fontWeight: isLarge ? FontWeight.w600 : FontWeight.w500, color: context.textPrimaryColor)),
               ],
             ),
           ),
           if (trailing != null) ...[
             const SizedBox(width: 8),
             trailing,
           ]
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
                     Text(_currentOrder.statusPengiriman.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, color: isCompleted ? AppColors.success : AppColors.primaryDark, fontSize: 16)),
                     const SizedBox(height: 4),
                     Text('NO RESI: ${_currentOrder.resi}', style: TextStyle(color: isCompleted ? AppColors.success : AppColors.primary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ],
                ),
              ),

              _buildSection('INFORMASI MUATAN', [
                _buildRow(Icons.business_rounded, 'Kustomer / Nama Pabrik', _currentOrder.namaPabrik, context, isLarge: true),
                if (_currentOrder.customerName != null && _currentOrder.customerName!.isNotEmpty)
                  _buildRow(
                    Icons.person_rounded,
                    'Nama Pemesan',
                    _currentOrder.customerName!,
                    context,
                  ),
                if (_currentOrder.customerNoHp != null && _currentOrder.customerNoHp!.isNotEmpty)
                  _buildRow(
                    Icons.phone_rounded,
                    'Kontak Pemesan',
                    _currentOrder.customerNoHp!,
                    context,
                    trailing: IconButton(
                      icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
                      tooltip: 'Hubungi Pemesan',
                      onPressed: () => _makePhoneCall(_currentOrder.customerNoHp!),
                    ),
                  ),
                _buildRow(Icons.inventory_2_rounded, 'Jenis Barang Dimuat', _currentOrder.jenisBarang, context),
                _buildRow(Icons.scale_rounded, 'Total Tonase Berat', '${_currentOrder.berat / 1000} Ton', context, isLarge: true),
                if (_currentOrder.tanggalPemesanan != null && _currentOrder.tanggalPemesanan!.isNotEmpty)
                  _buildRow(
                    Icons.calendar_today_rounded,
                    'Tanggal Rencana Kirim (Preorder)',
                    DateFormat('dd MMMM yyyy').format(DateTime.parse(_currentOrder.tanggalPemesanan!)),
                    context,
                  ),
                if (_currentOrder.estimasiDatang != null && _currentOrder.estimasiDatang != '-')
                  _buildRow(
                    Icons.timelapse_rounded,
                    'Estimasi Tiba',
                    _currentOrder.estimasiDatang!,
                    context,
                  ),
              ], context),

              _buildSection('RUTE PENGIRIMAN', [
                _buildRow(
                  Icons.my_location_rounded,
                  'Lokasi Pengambilan (Asal)',
                  _currentOrder.alamatAsalClean,
                  context,
                  trailing: IconButton(
                    icon: Icon(Icons.navigation_rounded, color: AppColors.primary),
                    tooltip: 'Navigasi ke Lokasi Asal',
                    onPressed: () => _openMap(_currentOrder.alamatAsalClean, _currentOrder.alamatAsalCoordinate),
                  ),
                ),
                _buildRow(
                  Icons.location_on_rounded,
                  'Titik Bongkar (Tujuan)',
                  _currentOrder.alamatTujuanClean,
                  context,
                  isLarge: true,
                  trailing: IconButton(
                    icon: Icon(Icons.navigation_rounded, color: AppColors.primary),
                    tooltip: 'Navigasi ke Tujuan',
                    onPressed: () => _openMap(_currentOrder.alamatTujuanClean, _currentOrder.alamatTujuanCoordinate),
                  ),
                ),
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
                  child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
               )
            ),
        ),
    );
  }
}
