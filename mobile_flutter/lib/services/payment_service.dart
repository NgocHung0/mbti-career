import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PaymentService {
  static const String baseUrl = AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để thanh toán.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> createMbtiPayment({
    required int packageId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/mbti-payment/create'),
          headers: await _headers(),
          body: jsonEncode({
            'package_id': packageId,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không tạo được mã QR thanh toán.');
    }

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getMbtiPaymentStatus({
    required int orderCode,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/mbti-payment/status/$orderCode'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không kiểm tra được thanh toán.');
    }

    return Map<String, dynamic>.from(data);
  }
}