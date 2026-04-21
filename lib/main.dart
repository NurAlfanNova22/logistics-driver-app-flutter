import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/order_screen.dart';
import 'screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';

import 'app_theme.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<int?> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = SharedPreferences.getInstance().then((prefs) => prefs.getInt('sopir_id'));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Lancar Driver',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 600),
          themeAnimationCurve: Curves.easeInOut,
          home: FutureBuilder<int?>(
            future: _authFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: AppColors.primary,
                  body: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return const MainScreen();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    LocationService().init();
    NotificationService().init();
  }

  final List<Widget> pages = const [
    HomeScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (selectedIndex != 0) {
          setState(() => selectedIndex = 0);
          return;
        }

        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tekan sekali lagi untuk keluar'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_rounded),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    ),
    );
  }
}