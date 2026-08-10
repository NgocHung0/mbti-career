import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/mbti_question.dart';
import 'auth_service.dart';

class MbtiService {
  static const String baseUrl = AuthService.baseUrl;

  Future<List<MbtiQuestion>> getQuestions({String level = 'free'}) async {
    final normalizedLevel = level.trim().toLowerCase();
    final packageTypes = switch (normalizedLevel) {
      'premium' => const ['free', 'plus', 'premium'],
      'plus' => const ['free', 'plus'],
      _ => const ['free'],
    };

    final groups = await Future.wait(
      packageTypes.map(_getQuestionsForPackage),
    );

    final sortedQuestions = groups.expand((items) => items).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return a.id.compareTo(b.id);
      });

    final uniqueByOrder = <int, MbtiQuestion>{};
    for (final question in sortedQuestions) {
      uniqueByOrder.putIfAbsent(question.order, () => question);
    }

    return uniqueByOrder.values.toList();
  }

  Future<List<MbtiQuestion>> _getQuestionsForPackage(
    String packageType,
  ) async {
    final token = await AuthService.getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/mbti/questions?package_type=$packageType'),
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Không thể tải câu hỏi $packageType');
    }

    final data = jsonDecode(response.body);
    final rawQuestions = data is Map<String, dynamic>
        ? data['questions']
        : null;

    if (rawQuestions is! List) {
      throw Exception('Dữ liệu câu hỏi $packageType không hợp lệ');
    }

    return rawQuestions
        .whereType<Map>()
        .map(
          (item) => MbtiQuestion.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((question) => question.question.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> submitAnswers(
    List<Map<String, dynamic>> answers,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/mbti/submit'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'answers': answers}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Không thể nộp bài');
    }

    return jsonDecode(response.body);
  }
}
