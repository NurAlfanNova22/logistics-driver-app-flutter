import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'api_service.dart';
import '../models/order.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  bool _isTracking = false;
  int? _sopirId;
  int? _activeOrderId;
  String? _activeResi;
  String? _lastCity;

  Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _sopirId = prefs.getInt('sopir_id');
    checkAndToggleTracking();
  }

  Future<void> checkAndToggleTracking() async {
    if (_sopirId == null) return;

    try {
      final orders = await ApiService.getDriverOrders(_sopirId!);
      final activeOrder = orders.firstWhere(
        (o) => o.statusPengiriman == 'DALAM PERJALANAN',
        orElse: () => Order(id: 0, resi: '', namaPabrik: '', alamatAsal: '', alamatTujuan: '', jenisBarang: '', berat: 0, status: '', statusPengiriman: '', updatedAt: DateTime.now()),
      );

      if (activeOrder.id != 0) {
        _activeOrderId = activeOrder.id;
        startTracking(activeOrder.resi);
      } else {
        _activeOrderId = null;
        stopTracking();
      }
    } catch (e) {
      print('Error checking tracking: $e');
    }
  }

  Future<void> startTracking(String resi) async {
    if (_isTracking && _activeResi == resi) return;
    
    _activeResi = resi;
    bool hasPermission = await _handlePermission();
    if (!hasPermission) return;

    _isTracking = true;
    
    // Konfigurasi Geolocator untuk hemat baterai
    // Interval 15 menit = tidak bisa pakai Stream biasa jika ingin benar-benar 'tidur'
    // Tapi untuk demonstrasi ini kita pakai Stream dengan distanceFilter tinggi.
    // Untuk 15 menit murni, lebih baik pakai WorkManager atau Alarm Manager.
    
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 500, // Update setiap 500 meter
    );

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _updateFirebase(position);
        _checkForCheckpointUpdate(position);
      },
    );
    
    // Initial update
    Position? currentPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    _updateFirebase(currentPos);
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    _activeResi = null;
  }

  Future<void> _updateFirebase(Position position) async {
    if (_activeResi == null) return;

    await _db.ref('tracking/$_activeResi').set({
      'lat': position.latitude,
      'lng': position.longitude,
      'updated_at': ServerValue.timestamp,
      'status': 'AKTIF',
    });
  }

  Future<void> _checkForCheckpointUpdate(Position position) async {
    if (_activeOrderId == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.subAdministrativeArea ?? place.locality ?? place.administrativeArea ?? "Wilayah Tidak Dikenal";

        if (city != _lastCity) {
          _lastCity = city;
          await ApiService.addCheckpoint(_activeOrderId!, city, position.latitude, position.longitude);
          print('Checkpoint updated: $city');
        }
      }
    } catch (e) {
      print('Error geocoding: $e');
    }
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }
}
