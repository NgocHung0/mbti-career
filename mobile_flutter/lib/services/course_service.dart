import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/course.dart';
import 'auth_service.dart';

class CourseService {
  static const String baseUrl = AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để xem khóa học.');
    }

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Course>> getCourses() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/courses'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không tải được danh sách khóa học.');
    }

    final list = data['courses'] is List ? data['courses'] as List : [];

    return list
        .map((item) => Course.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<Course> getCourseDetail(int id) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/courses/$id'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không tải được chi tiết khóa học.');
    }

    return Course.fromJson(Map<String, dynamic>.from(data['course']));
  }

  static Future<List<CourseLesson>> getLessons(int courseId) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/courses/$courseId/lessons'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không tải được bài học.');
    }

    final list = data['lessons'] is List ? data['lessons'] as List : [];

    return list
        .map((item) => CourseLesson.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}