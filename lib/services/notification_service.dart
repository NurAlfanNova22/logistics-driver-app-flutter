import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool _isInit = false;

  // Notification data
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  List<Map<String, dynamic>> notifications = [];

  Future<void> init() async {
    if (_isInit) return;

    // Request permissions for Android 13+
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS
    const DarwinInitializationSettings initSettingsDarwin = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initSettings);
    _isInit = true;

    await _loadFromLocal();
    _startListening();
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('saved_notifications');
    unreadCountNotifier.value = prefs.getInt('unread_count') ?? 0;
    
    if (saved != null) {
      try {
        final List<dynamic> decoded = jsonDecode(saved);
        notifications = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        notifications = [];
      }
    }
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_notifications', jsonEncode(notifications));
    await prefs.setInt('unread_count', unreadCountNotifier.value);
  }

  void clearUnread() {
    unreadCountNotifier.value = 0;
    _saveToLocal();
  }

  Future<void> _startListening() async {
    final prefs = await SharedPreferences.getInstance();
    final sopirId = prefs.getInt('sopir_id');

    if (sopirId == null) return;

    // Hanya dengarkan notifikasi yang masuk SETELAH layanan ini dimulai
    final startTime = DateTime.now().millisecondsSinceEpoch;

    _dbRef
        .child('notifications_driver/$sopirId')
        .orderByChild('timestamp')
        .startAt(startTime)
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // Simpan ke riwayat lokal
        notifications.insert(0, data); // Tambah di paling atas
        unreadCountNotifier.value++;
        _saveToLocal();

        _showNotification(data['title'], data['body']);
        
        // Hapus dari Firebase agar tidak menumpuk
        event.snapshot.ref.remove();
      }
    });
  }

  Future<void> _showNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'driver_order_channel',
      'Pesanan Baru',
      channelDescription: 'Notifikasi penugasan pesanan baru untuk sopir',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond, // ID Unik
      title ?? 'Ada Update',
      body ?? 'Cek aplikasi Anda sekarang.',
      platformDetails,
    );
  }
}
