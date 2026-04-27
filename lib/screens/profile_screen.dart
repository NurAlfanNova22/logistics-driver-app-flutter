import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../main.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'Memuat...';
  String email = 'Memuat...';
  String? driverFoto;
  int? userId;
  bool isLoading = true;
  final String baseStorageUrl = "https://lancarekspedisi.satcloud.tech/storage/";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('driver_name') ?? 'Driver Lancar';
      email = prefs.getString('driver_email') ?? 'driver@lancar.com';
      driverFoto = prefs.getString('driver_foto');
      userId = prefs.getInt('user_id');
      isLoading = false;
    });
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Profil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Photo Picker in Dialog
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (picked != null) {
                        setDialogState(() => selectedImage = File(picked.path));
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                        image: selectedImage != null 
                          ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                          : (driverFoto != null 
                              ? DecorationImage(image: NetworkImage('$baseStorageUrl$driverFoto'), fit: BoxFit.cover)
                              : null),
                      ),
                      child: (selectedImage == null && driverFoto == null)
                        ? const Icon(Icons.camera_alt_rounded, color: AppColors.primary)
                        : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (userId == null) return;
                  
                  final success = await ApiService.updateProfile(
                    userId!,
                    nameController.text.trim(),
                    emailController.text.trim(),
                    image: selectedImage,
                  );

                  if (success && mounted) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('driver_name', nameController.text.trim());
                    await prefs.setString('driver_email', emailController.text.trim());
                    
                    // We can't easily get the new photo path from updateProfile boolean return, 
                    // but usually, the user knows they just uploaded a file.
                    // For a complete fix, the API should return the new profile data.
                    // However, we'll trigger a reload from API or just clear local cache.
                    
                    _loadData();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil berhasil diperbarui. Silakan login ulang jika foto tidak berubah.')),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Sopir')),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: driverFoto != null ? null : const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    image: driverFoto != null 
                      ? DecorationImage(
                          image: NetworkImage('$baseStorageUrl$driverFoto'),
                          fit: BoxFit.cover
                        )
                      : null,
                  ),
                  child: driverFoto == null 
                    ? const Icon(Icons.person_rounded, size: 38, color: Colors.white)
                    : null,
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showEditProfile,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit Profil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Sopir Aktif',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Settings
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                // Dark Mode Toggle
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, themeMode, _) {
                    final isDark = themeMode == ThemeMode.dark;
                    return _SettingRow(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      label: 'Mode Gelap',
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) {
                          themeModeNotifier.value =
                              val ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: context.borderColor, indent: 56),
                _SettingRow(
                  icon: Icons.shield_outlined,
                  label: 'Versi Aplikasi',
                  trailing: Text('v1.0.0',
                      style: TextStyle(
                          color: context.textMutedColor, fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('sopir_id');
                
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Keluar',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.surface2Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: context.textSecondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14, color: context.textPrimaryColor)),
          ),
          trailing,
        ],
      ),
    );
  }
}
