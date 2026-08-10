import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PackageService {
  static const String baseUrl = AuthService.baseUrl;

  static Future<Map<String, dynamic>?> getCurrentPackage() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) return null;

    final response = await http
        .get(
          Uri.parse('$baseUrl/user/packages'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return null;
  }

  static Map<String, dynamic>? normalizePackage(Map<String, dynamic>? data) {
    if (data == null) return null;

    if (data['current_package'] is Map) {
      return Map<String, dynamic>.from(data['current_package']);
    }

    if (data['package'] is Map) {
      return Map<String, dynamic>.from(data['package']);
    }

    if (data['currentPackage'] is Map) {
      return Map<String, dynamic>.from(data['currentPackage']);
    }

    if (data['service_package'] is Map) {
      return Map<String, dynamic>.from(data['service_package']);
    }

    if (data['servicePackage'] is Map) {
      return Map<String, dynamic>.from(data['servicePackage']);
    }

    if (data['id'] != null ||
        data['name'] != null ||
        data['slug'] != null ||
        data['price'] != null) {
      return data;
    }

    return null;
  }

  static String getMode(Map<String, dynamic>? data) {
    if (data == null) return 'free';

    final role = data['user']?['role']?.toString().toLowerCase().trim() ?? '';

    if (role.contains('premium')) return 'premium';
    if (role.contains('plus')) return 'plus';

    final package = normalizePackage(data);

    if (package == null) return 'free';

    final name = package['name']?.toString().toLowerCase().trim() ?? '';
    final slug = package['slug']?.toString().toLowerCase().trim() ?? '';
    final code = package['code']?.toString().toLowerCase().trim() ?? '';
    final type = package['type']?.toString().toLowerCase().trim() ?? '';
    final id = package['id']?.toString().trim() ?? '';

    final price =
        double.tryParse(package['price']?.toString() ?? '0') ?? 0;

    final text = '$name $slug $code $type';

    if (text.contains('premium') ||
        text.contains('nang-luc') ||
        text.contains('năng-lực') ||
        text.contains('ability') ||
        id == '2' ||
        price >= 39000) {
      return 'premium';
    }

    if (text.contains('plus') ||
        text.contains('so-thich') ||
        text.contains('sở-thích') ||
        text.contains('interest') ||
        id == '1' ||
        price >= 19000) {
      return 'plus';
    }

    return 'free';
  }

  static bool isPlus(Map<String, dynamic>? data) {
    return getMode(data) == 'plus';
  }

  static bool isPremium(Map<String, dynamic>? data) {
    return getMode(data) == 'premium';
  }

  static String packageLabel(Map<String, dynamic>? data) {
    final mode = getMode(data);

    if (mode == 'premium') return 'Premium';
    if (mode == 'plus') return 'Plus';

    return 'Free';
  }
}