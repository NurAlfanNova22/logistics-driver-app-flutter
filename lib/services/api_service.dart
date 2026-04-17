import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class ApiService {

  static const String baseUrl = "https://lancarekspedisi.satcloud.tech/api/";

  // LOGIN
  static Future<Map<String, dynamic>?> login(
    String email,
    String password
  ) async {

    final response = await http.post(
      Uri.parse("${baseUrl}driver/login"),
      body: {
        "email": email,
        "password": password
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // GET DRIVER ORDERS
  static Future<List<Order>> getDriverOrders(int sopirId) async {

    final response = await http.get(
      Uri.parse("${baseUrl}driver/orders/$sopirId"),
    );

    if (response.statusCode == 200) {

      List data = jsonDecode(response.body);

      return data.map((e) => Order.fromJson(e)).toList();
    }

    return [];
  }

  // UPDATE STATUS
  static Future<bool> updateStatus(int orderId) async {

    final response = await http.post(
      Uri.parse("${baseUrl}driver/update-status/$orderId"),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode != 200) {
       print("API UPDATE STATUS ERROR: ${response.statusCode} - ${response.body}");
    }

    return response.statusCode == 200;
  }

  // DRIVER STATS
  static Future<Map<String, dynamic>> getDriverStats(int sopirId) async {

    final response = await http.get(
      Uri.parse("${baseUrl}driver/stats/$sopirId"),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return {
        "hari_ini": data["hari_ini"] ?? 0,
        "bulan_ini": data["bulan_ini"] ?? 0,
        "is_online": data["is_online"] ?? false
      };
    }

    return {
      "hari_ini": 0,
      "bulan_ini": 0,
      "is_online": false
    };
  }

  // TOGGLE ONLINE
  static Future<bool> toggleOnlineStatus(int sopirId, bool isOnline) async {
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}driver/toggle-online"),
        body: {
          "sopir_id": sopirId.toString(),
          "is_online": isOnline ? "1" : "0"
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ADD CHECKPOINT
  static Future<void> addCheckpoint(int orderId, String lokasi, double lat, double lng) async {
    try {
      await http.post(
        Uri.parse("${baseUrl}driver/add-checkpoint"),
        body: {
          "pesanan_id": orderId.toString(),
          "lokasi": lokasi,
          "lat": lat.toString(),
          "lng": lng.toString()
        },
      );
    } catch (e) {
      print('Error push checkpoint: $e');
    }
  }

  // UPDATE PROFILE
  static Future<bool> updateProfile(int userId, String name, String email) async {
    try {
      final response = await http.put(
        Uri.parse("${baseUrl}driver/profile/$userId"),
        body: {
          "name": name,
          "email": email,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}