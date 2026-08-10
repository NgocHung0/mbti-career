class MbtiQuestion {
  final int id;

  // Thứ tự câu hỏi trong cơ sở dữ liệu
  final int order;

  final String question;
  final String optionA;
  final String optionB;

  // Trục MBTI hoặc mã tiêu chí
  final String axis;

  // Tên tiêu chí hiển thị
  final String axisLabel;

  // Giá trị của đáp án A và B
  final String dirA;
  final String dirB;

  // Câu hỏi thuộc gói free, plus hay premium
  final String packageType;

  MbtiQuestion({
    required this.id,
    required this.order,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.axis,
    required this.axisLabel,
    required this.dirA,
    required this.dirB,
    required this.packageType,
  });

  factory MbtiQuestion.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']);

    final dirA = _toText(
      json['dirA'] ?? json['dir_a'],
    ).toUpperCase();

    final dirB = _toText(
      json['dirB'] ?? json['dir_b'],
    ).toUpperCase();

    final axis = _toText(json['axis']);

    return MbtiQuestion(
      id: id,

      order: _toInt(
        json['order'],
        fallback: id,
      ),

      question: _toText(
        json['question'] ?? json['content'],
      ),

      optionA: _toText(
        json['optionA'] ??
            json['option_a'] ??
            json['label_a'],
      ),

      optionB: _toText(
        json['optionB'] ??
            json['option_b'] ??
            json['label_b'],
      ),

      axis: axis.isNotEmpty ? axis : '$dirA/$dirB',

      axisLabel: _toText(
        json['axisLabel'] ??
            json['axis_label'] ??
            json['axis'],
      ),

      dirA: dirA,
      dirB: dirB,

      packageType: _toText(
        json['package_type'] ??
            json['packageType'] ??
            json['section'],
      ).toLowerCase(),
    );
  }

  static int _toInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static String _toText(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}