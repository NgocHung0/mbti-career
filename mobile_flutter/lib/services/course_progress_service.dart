import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/course_learning_history.dart';
import 'auth_service.dart';

class CourseProgressService {
  static const String baseUrl = AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để lưu tiến độ học.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getProgress(int lessonId) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/course-progress/$lessonId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không tải được tiến độ bài học.');
    }

    return Map<String, dynamic>.from(data['progress'] ?? {});
  }

  static Future<void> saveProgress({
    required int lessonId,
    required int videoProgress,
    required bool completed,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/course-progress'),
          headers: await _headers(),
          body: jsonEncode({
            'lesson_id': lessonId,
            'video_progress': videoProgress,
            'completed': completed,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không lưu được tiến độ bài học.');
    }
  }

  static Future<List<CourseLearningHistory>> getLearningHistories() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/course-progress-history'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không tải được lịch sử học tập.');
    }

    List list = [];

    if (data is List) {
      list = data;
    } else if (data is Map && data['histories'] is List) {
      list = data['histories'];
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    }

    return list
        .map(
          (item) => CourseLearningHistory.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}