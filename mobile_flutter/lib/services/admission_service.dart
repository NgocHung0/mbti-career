import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/admission.dart';
import 'auth_service.dart';

class AdmissionService {
  static const String baseUrl = AuthService.baseUrl;

  static Future<List<Admission>> getAdmissions() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/admissions'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Không tải được danh sách tuyển sinh.',
      );
    }

    final list = _extractList(data);

    return list
        .map((item) => Admission.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<Admission> getAdmissionDetail(int id) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/admissions/$id'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Không tải được chi tiết tuyển sinh.',
      );
    }

    if (data is Map<String, dynamic>) {
      if (data['data'] is Map) {
        return Admission.fromJson(Map<String, dynamic>.from(data['data']));
      }

      if (data['admission'] is Map) {
        return Admission.fromJson(Map<String, dynamic>.from(data['admission']));
      }

      return Admission.fromJson(data);
    }

    throw Exception('Dữ liệu tuyển sinh không hợp lệ.');
  }

  static String? resolveImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;

    var raw = imageUrl.trim();

    raw = raw.replaceFirst('http://http//', 'http://');
    raw = raw.replaceFirst('https://https//', 'https://');

    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('data:')) {
      return raw;
    }

    final origin = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final cleaned = raw.replaceFirst(RegExp(r'^/+'), '');

    if (cleaned.startsWith('images/') ||
        cleaned.startsWith('assets/') ||
        cleaned.startsWith('storage/')) {
      return '$origin/$cleaned';
    }

    if (cleaned.startsWith('admissions/')) {
      return '$origin/storage/$cleaned';
    }

    if (!cleaned.contains('/')) {
      return '$origin/storage/admissions/$cleaned';
    }

    return '$origin/storage/$cleaned';
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      if (data['data'] is List) return data['data'];
      if (data['admissions'] is List) return data['admissions'];
      if (data['items'] is List) return data['items'];
    }

    return [];
  }
}
