import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_screen.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool isOnline = false;
  int hariIni = 0;
  int bulanIni = 0;
  bool isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _getDriverStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _getDriverStats() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int sopirId = prefs.getInt('sopir_id') ?? 0;
      final data = await ApiService.getDriverStats(sopirId);
      if (mounted) {
        setState(() {
          hariIni = data['hari_ini'] ?? 0;
          bulanIni = data['bulan_ini'] ?? 0;
          isOnline = data['is_online'] ?? false;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _getDriverStats,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard Driver 🚛',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimaryColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kelola pengiriman Anda hari ini',
                                style: TextStyle(
                                    fontSize: 13, color: context.textMutedColor),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(


                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: context.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.borderColor),
                                  ),
                                  child: Icon(Icons.notifications_none_rounded,
                                      size: 20, color: context.textSecondaryColor),
                                ),
                                ValueListenableBuilder<int>(
                                  valueListenable: NotificationService().unreadCountNotifier,
                                  builder: (context, count, _) {
                                    if (count == 0) return const SizedBox();
                                    return Positioned(
                                      top: -5,
                                      right: -5,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          count > 9 ? '9+' : count.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Online Status Card
                      Container(


                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AppColors.primarySurface
                              : context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isOnline
                                ? AppColors.primary.withOpacity(0.3)
                                : context.borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? AppColors.primary.withOpacity(0.15)
                                    : context.surface2Color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isOnline
                                    ? Icons.wifi_rounded
                                    : Icons.wifi_off_rounded,
                                size: 18,
                                color: isOnline
                                    ? AppColors.primary
                                    : context.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOnline ? 'Status: Online' : 'Status: Offline',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isOnline
                                          ? AppColors.primary
                                          : context.textPrimaryColor,
                                    ),
                                  ),
                                  Text(
                                    isOnline
                                        ? 'Siap menerima pesanan baru'
                                        : 'Tidak menerima pesanan baru',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: context.textMutedColor),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isOnline,
                              onChanged: (val) async {
                                final oldVal = isOnline;
                                setState(() => isOnline = val);
                                
                                try {
                                  SharedPreferences prefs = await SharedPreferences.getInstance();
                                  int sopirId = prefs.getInt('sopir_id') ?? 0;
                                  await ApiService.toggleOnlineStatus(sopirId, val);
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => isOnline = oldVal);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Gagal menyinkronkan status online.')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),


                      const SizedBox(height: 24),

                      // Stats Section Title
                      Text(
                        'STATISTIK PENGIRIMAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                          color: context.textMutedColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stats
                      isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary))
                          : Row(
                              children: [
                                _StatCard(
                                  title: 'Hari Ini',
                                  value: hariIni,
                                  icon: Icons.today_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                _StatCard(
                                  title: 'Bulan Ini',
                                  value: bulanIni,
                                  icon: Icons.calendar_month_rounded,
                                  color: AppColors.info,
                                ),
                              ],
                            ),

                      const SizedBox(height: 28),

                      Text(
                        'AKSI CEPAT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                          color: context.textMutedColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ActionTile(
                      icon: Icons.local_shipping_rounded,
                      label: 'Lihat Pesanan Aktif',
                      subtitle: 'Daftar pengiriman yang harus dilakukan',
                      iconColor: AppColors.primary,
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialTabIndex: 0)));
                      },
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.history_rounded,
                      label: 'Riwayat Pengiriman',
                      subtitle: 'Pesanan yang sudah selesai',
                      iconColor: AppColors.success,
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen(initialTabIndex: 1)));
                      },
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(


        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(title,
                style:
                    TextStyle(fontSize: 12, color: context.textMutedColor)),
          ],
        ),
      ),
    );
  }
}

// ─── Action Tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(


          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed ? context.surface2Color : context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, size: 20, color: widget.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: TextStyle(
                            fontSize: 12, color: context.textMutedColor)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: context.textMutedColor),
            ],
          ),
        ),
      ),
    );
  }
}
