import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/major.dart';
import 'auth_service.dart';

class MajorService {
  static const String baseUrl = AuthService.baseUrl;

  Future<List<Major>> getMajors() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/majors'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách ngành nghề');
    }

    final List data = jsonDecode(response.body);

    return data.map((e) => Major.fromJson(e)).toList();
  }
}