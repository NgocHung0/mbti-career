import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class TestHistoryService {
  static const String baseUrl = AuthService.baseUrl;

  static Future<List<dynamic>> getHistories() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để xem lịch sử.');
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/user/test-histories'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không thể tải lịch sử.');
    }

    if (data is List) return data;

    if (data['data'] is List) return data['data'];

    if (data['histories'] is List) return data['histories'];

    return [];
  }

  static Future<Map<String, dynamic>> getHistoryDetail(int id) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để xem chi tiết.');
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/user/test-histories/$id'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không thể tải chi tiết lịch sử.');
    }

    if (data is Map<String, dynamic>) return data;

    return {};
  }

  static Future<void> storeHistory({
    required String mbtiType,
    required String testName,
    required Map<String, dynamic> resultData,
    String? packageName,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return;

    final response = await http.post(
      Uri.parse('$baseUrl/user/test-histories'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'test_type': 'mbti',
        'result_code': mbtiType,
        'answers': resultData['answers'] ?? [],
        'scores': resultData['scores'] ?? {},
        'result_payload': {
          ...resultData,
          'mbti_type': mbtiType,
          'package_name': packageName ?? resultData['package_name'],
        },
        'package_name': packageName ?? resultData['package_name'],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.body);
    }
  }
}
