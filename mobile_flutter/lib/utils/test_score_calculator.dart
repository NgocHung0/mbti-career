class TestScoreCalculator {
  static const List<String> mbtiKeys = [
    'E',
    'I',
    'S',
    'N',
    'T',
    'F',
    'J',
    'P',
  ];

  static const List<String> interestKeys = [
    'creative',
    'analytic',
    'social',
    'business',
  ];

  static const List<String> abilityKeys = [
    'LANGUAGE',
    'LOGIC',
    'CREATIVE',
    'TECH',
    'LEADERSHIP',
    'TEAMWORK',
    'DETAIL',
    'ADAPT',
    'PRACTICAL',
    'STRATEGIC',
  ];

  static const Map<String, String> _interestCodeMap = {
    'CREATIVE': 'creative',
    'ANALYTIC': 'analytic',
    'SOCIAL': 'social',
    'BUSINESS': 'business',
  };

  static Map<String, int> mbtiScores(
    List<Map<String, dynamic>> answers,
  ) {
    final scores = {for (final key in mbtiKeys) key: 0};

    for (final answer in answers) {
      final selected = _selectedCode(answer);
      if (scores.containsKey(selected)) {
        scores[selected] = (scores[selected] ?? 0) + 1;
      }
    }

    return scores;
  }

  static String mbtiType(List<Map<String, dynamic>> answers) {
    final scores = mbtiScores(answers);

    return '${scores['E']! >= scores['I']! ? 'E' : 'I'}'
        '${scores['S']! >= scores['N']! ? 'S' : 'N'}'
        '${scores['T']! >= scores['F']! ? 'T' : 'F'}'
        '${scores['J']! >= scores['P']! ? 'J' : 'P'}';
  }

  static Map<String, double> interestPercentages(
    List<Map<String, dynamic>> answers,
  ) {
    final selectedCounts = {for (final key in interestKeys) key: 0};
    final appearanceCounts = {for (final key in interestKeys) key: 0};

    for (final answer in answers) {
      final leftCode = _normalizeCode(answer['dir_a'] ?? answer['dirA']);
      final rightCode = _normalizeCode(answer['dir_b'] ?? answer['dirB']);
      final left = _interestCodeMap[leftCode];
      final right = _interestCodeMap[rightCode];

      // Angular chỉ duyệt 20 câu Plus. Yêu cầu cả hai phía đều là
      // mã sở thích cũng giúp đọc được lịch sử cũ chưa lưu package_type,
      // đồng thời tránh nhầm CREATIVE của phần năng lực Premium.
      if (!_belongsToSection(answer, 'plus') &&
          !(_hasNoSection(answer) && left != null && right != null)) {
        continue;
      }

      if (left == null || right == null) continue;

      appearanceCounts[left] = appearanceCounts[left]! + 1;
      appearanceCounts[right] = appearanceCounts[right]! + 1;

      final selected = _interestCodeMap[_selectedCode(answer)];
      if (selected != null) {
        selectedCounts[selected] = selectedCounts[selected]! + 1;
      }
    }

    return {
      for (final key in interestKeys)
        key: _percentage(
          selectedCounts[key] ?? 0,
          appearanceCounts[key] ?? 0,
        ),
    };
  }

  static Map<String, double> abilityPercentages(
    List<Map<String, dynamic>> answers,
  ) {
    final selectedCounts = {for (final key in abilityKeys) key: 0};
    final appearanceCounts = {for (final key in abilityKeys) key: 0};
    final validKeys = abilityKeys.toSet();

    for (final answer in answers) {
      final left = _normalizeCode(answer['dir_a'] ?? answer['dirA']);
      final right = _normalizeCode(answer['dir_b'] ?? answer['dirB']);
      final bothAreAbilityCodes =
          validKeys.contains(left) && validKeys.contains(right);

      // Angular chỉ duyệt 30 câu Premium. Điều kiện hai phía đều là
      // mã năng lực ngăn CREATIVE của phần Plus bị cộng nhầm.
      if (!_belongsToSection(answer, 'premium') &&
          !(_hasNoSection(answer) && bothAreAbilityCodes)) {
        continue;
      }

      if (!bothAreAbilityCodes) continue;

      appearanceCounts[left] = appearanceCounts[left]! + 1;
      appearanceCounts[right] = appearanceCounts[right]! + 1;

      final selected = _selectedCode(answer);
      if (validKeys.contains(selected)) {
        selectedCounts[selected] = selectedCounts[selected]! + 1;
      }
    }

    return {
      for (final key in abilityKeys)
        key: _percentage(
          selectedCounts[key] ?? 0,
          appearanceCounts[key] ?? 0,
        ),
    };
  }

  static Map<String, int> roundedPercentages(Map<String, num> values) {
    return values.map(
      (key, value) => MapEntry(key, value.round().clamp(0, 100).toInt()),
    );
  }

  static bool _belongsToSection(
    Map<String, dynamic> answer,
    String section,
  ) {
    return _section(answer) == section;
  }

  static bool _hasNoSection(Map<String, dynamic> answer) {
    return _section(answer).isEmpty;
  }

  static String _section(Map<String, dynamic> answer) {
    return (answer['package_type'] ??
            answer['packageType'] ??
            answer['section'])
        ?.toString()
        .trim()
        .toLowerCase() ??
        '';
  }

  static String _selectedCode(Map<String, dynamic> answer) {
    final selectedAnswer = _normalizeCode(
      answer['selected_answer'] ?? answer['selectedAnswer'],
    );

    if (selectedAnswer == 'A') {
      return _normalizeCode(answer['dir_a'] ?? answer['dirA']);
    }

    if (selectedAnswer == 'B') {
      return _normalizeCode(answer['dir_b'] ?? answer['dirB']);
    }

    return _normalizeCode(
      answer['choice'] ?? answer['selected_code'] ?? answer['selectedCode'],
    );
  }

  static String _normalizeCode(dynamic value) {
    return value?.toString().trim().toUpperCase() ?? '';
  }

  static double _percentage(int selected, int appearances) {
    if (appearances <= 0) return 0;
    final value = (selected / appearances) * 100;
    return double.parse(value.toStringAsFixed(2));
  }
}
