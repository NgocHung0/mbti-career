import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course_learning_history.dart';
import 'auth_service.dart';

class CourseQuizHistoryService {
  static const String baseUrl = AuthService.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập để xem lịch sử học tập.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<CourseLearningHistory>> getHistories() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/course-quiz-history'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không tải được lịch sử học tập.');
    }

    final list = data is Map && data['histories'] is List
        ? data['histories'] as List
        : [];

    return list
        .map(
          (item) => CourseLearningHistory.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static Future<CourseLearningHistory?> getHistoryByLessonId(
    int lessonId,
  ) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/course-quiz-history/$lessonId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 404) {
      return null;
    }

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Không tải được bài làm.');
    }

    if (data is Map && data['history'] is Map) {
      return CourseLearningHistory.fromJson(
        Map<String, dynamic>.from(data['history']),
      );
    }

    return null;
  }

  static Future<void> saveAnswer({
    required int lessonId,
    required String lessonTitle,
    required int totalQuestions,
    required String questionId,
    required String question,
    required String selectedLabel,
    required int selectedOptionIndex,
    required String selectedOptionContent,
    required bool isCorrect,
    required List<CourseLearningOptionHistory> options,
    String courseName = 'Khóa học',
  }) async {
    final quizId = int.tryParse(questionId);

    if (quizId == null) {
      throw Exception('Không tìm thấy ID câu hỏi để lưu lịch sử.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/course-quiz-history/answer'),
          headers: await _headers(),
          body: jsonEncode({
            'lesson_id': lessonId,
            'quiz_id': quizId,
            'selected_answer': selectedLabel,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Không lưu được câu trả lời.');
    }
  }
}