class CourseLearningHistory {
  final int lessonId;
  final String lessonTitle;
  final String courseName;
  final String updatedAt;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final bool completed;
  final List<CourseLearningQuestionHistory> questions;

  const CourseLearningHistory({
    required this.lessonId,
    required this.lessonTitle,
    required this.courseName,
    required this.updatedAt,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.completed,
    required this.questions,
  });

  factory CourseLearningHistory.fromJson(Map<String, dynamic> json) {
    return CourseLearningHistory(
      lessonId: _toInt(json['lesson_id']),
      lessonTitle: _toText(json['lesson_title']) ?? 'Bài học',
      courseName: _toText(json['course_name']) ?? 'Khóa học',
      updatedAt: _toText(json['updated_at']) ?? '',
      totalQuestions: _toInt(json['total_questions']),
      correctCount: _toInt(json['correct_count']),
      wrongCount: _toInt(json['wrong_count']),
      completed: _toBool(json['completed']),
      questions: ((json['questions'] as List?) ?? [])
          .map(
            (item) => CourseLearningQuestionHistory.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_id': lessonId,
      'lesson_title': lessonTitle,
      'course_name': courseName,
      'updated_at': updatedAt,
      'total_questions': totalQuestions,
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'completed': completed,
      'questions': questions.map((item) => item.toJson()).toList(),
    };
  }

  String get scoreLabel {
    if (totalQuestions <= 0) return '$correctCount câu đúng';
    return '$correctCount/$totalQuestions câu đúng';
  }

  String get statusLabel {
    if (questions.isEmpty) return 'Chưa làm';
    if (completed) return 'Đã làm xong';
    return 'Đang làm';
  }

  String get updatedAtLabel {
    if (updatedAt.trim().isEmpty) return 'Chưa cập nhật';

    try {
      final date = DateTime.parse(updatedAt).toLocal();
      String two(int value) => value.toString().padLeft(2, '0');

      return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
    } catch (_) {
      return updatedAt;
    }
  }

  static String? _toText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value == 1;

    final text = value.toString().toLowerCase().trim();
    return text == 'true' || text == '1' || text == 'yes';
  }
}

class CourseLearningQuestionHistory {
  final String questionId;
  final String question;
  final String selectedLabel;
  final int selectedOptionIndex;
  final String selectedOptionContent;
  final bool isCorrect;
  final String answeredAt;
  final List<CourseLearningOptionHistory> options;

  const CourseLearningQuestionHistory({
    required this.questionId,
    required this.question,
    required this.selectedLabel,
    required this.selectedOptionIndex,
    required this.selectedOptionContent,
    required this.isCorrect,
    required this.answeredAt,
    required this.options,
  });

  factory CourseLearningQuestionHistory.fromJson(Map<String, dynamic> json) {
    return CourseLearningQuestionHistory(
      questionId: json['question_id']?.toString() ?? '',
      question: json['question']?.toString() ?? 'Câu hỏi',
      selectedLabel: json['selected_label']?.toString() ?? '',
      selectedOptionIndex: CourseLearningHistory._toInt(
        json['selected_option_index'],
      ),
      selectedOptionContent:
          json['selected_option_content']?.toString() ?? '',
      isCorrect: CourseLearningHistory._toBool(json['is_correct']),
      answeredAt: json['answered_at']?.toString() ?? '',
      options: ((json['options'] as List?) ?? [])
          .map(
            (item) => CourseLearningOptionHistory.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'question': question,
      'selected_label': selectedLabel,
      'selected_option_index': selectedOptionIndex,
      'selected_option_content': selectedOptionContent,
      'is_correct': isCorrect,
      'answered_at': answeredAt,
      'options': options.map((item) => item.toJson()).toList(),
    };
  }
}

class CourseLearningOptionHistory {
  final String label;
  final String content;
  final bool isCorrect;

  const CourseLearningOptionHistory({
    required this.label,
    required this.content,
    required this.isCorrect,
  });

  factory CourseLearningOptionHistory.fromJson(Map<String, dynamic> json) {
    return CourseLearningOptionHistory(
      label: json['label']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isCorrect: CourseLearningHistory._toBool(json['is_correct']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'content': content,
      'is_correct': isCorrect,
    };
  }
}