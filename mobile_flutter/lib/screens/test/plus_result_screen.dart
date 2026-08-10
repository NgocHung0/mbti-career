import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/test_history_service.dart';
import '../../core/constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../services/auth_service.dart';
import '../../services/admission_service.dart';
import '../admissions/admissions_screen.dart';
import '../../utils/test_score_calculator.dart';

class PlusResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> answers;
  final bool fromHistory;
  final Map<String, dynamic>? historyPayload;
  final String? historyMbti;

  const PlusResultScreen({
    super.key,
    required this.answers,
    this.fromHistory = false,
    this.historyPayload,
    this.historyMbti,
  });

  @override
  State<PlusResultScreen> createState() => _PlusResultScreenState();
}

class _PlusResultScreenState extends State<PlusResultScreen> {
  bool _saved = false;
  bool loadingCareers = false;
  List<_PlusCareerItem> topCareers = [];

  static const primaryBlue = Color(0xFF8EC5FC);
  static const purple = Color(0xFF9B7BEA);
  static const lightBlue = Colors.white;
  static const textDark = Color(0xFF29425E);
  static const textGrey = Color(0xFF617587);
  static const borderColor = Color(0xFFE4EEF8);

  void _loadFromHistoryPayload() {
    final payload = widget.historyPayload ?? {};

    final majors =
        payload['top_majors'] ??
        payload['top_major'] ??
        payload['recommended_majors'] ??
        payload['career_recommendations'] ??
        payload['careers'] ??
        payload['majors'] ??
        payload['recommendations'];

    if (majors is List) {
      topCareers = majors
          .map(_parseCareer)
          .where((e) => e.name.isNotEmpty)
          .toList();
    }

    setState(() {});
  }

  Future<void> _loadPlusRecommendations() async {
    setState(() => loadingCareers = true);

    final mbtiScores = getScores();
    final interests = interestPercentages();

    final payload = {
      'level': 'plus',
      'mbti_type': getMbtiType(),
      'mbti_scores': mbtiScores,
      'interest_group_scores': interests,
      'top_interest_groups': _topInterestKeys(interests, limit: 2),
      'limit': 5,
    };

    final endpoints = [
      '${AuthService.baseUrl}/recommendations/majors',
    ];

    for (final endpoint in endpoints) {
      try {
        final res = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 12));

        if (res.statusCode < 200 || res.statusCode >= 300) continue;

        final data = jsonDecode(res.body);
        final majors = _extractMajorList(data);

        if (majors.isNotEmpty) {
          topCareers = majors
              .map(_parseCareer)
              .where((e) => e.name.isNotEmpty)
              .toList();

          break;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => loadingCareers = false);
    }
  }

  List<String> _topInterestKeys(Map<String, num> scores, {int limit = 2}) {
    final entries = scores.entries.toList()
      ..sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        if (byValue != 0) return byValue;

        const priority = {
          'creative': 0,
          'analytic': 1,
          'social': 2,
          'business': 3,
        };

        return (priority[a.key] ?? 99).compareTo(priority[b.key] ?? 99);
      });

    return entries
        .where((e) => e.value > 0)
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  List<dynamic> _extractMajorList(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      final candidates = [
        data['top_majors'],
        data['top_major'],
        data['majors'],
        data['recommendations'],
        data['data'] is Map ? data['data']['top_majors'] : null,
        data['data'] is Map ? data['data']['top_major'] : null,
        data['data'] is Map ? data['data']['majors'] : null,
        data['data'] is Map ? data['data']['recommendations'] : null,
      ];

      for (final candidate in candidates) {
        if (candidate is List) return candidate;
      }
    }

    return [];
  }

  _PlusCareerItem _parseCareer(dynamic item) {
    if (item is! Map) {
      return _PlusCareerItem(
        name: '',
        description: '',
        score: 0,
        schools: [],
        reasons: [],
      );
    }

    return _PlusCareerItem(
      name:
          _cleanText(item['name'] ?? item['major_name'] ?? item['title']) ?? '',
      description:
          _cleanText(item['description'] ?? item['short_description']) ??
          'Ngành học này có mức độ phù hợp với MBTI và nhóm sở thích của bạn.',
      score: _toDouble(item['score'] ?? item['match_score'] ?? item['percent']),
      reasons: _extractReasons(item),
      schools: _extractSchools(
        item,
      ).map(_parseSchool).where((e) => e.name.isNotEmpty).toList(),
    );
  }

  List<dynamic> _extractSchools(Map item) {
    final candidates = [
      item['schools'],
      item['universities'],
      item['admissions'],
      item['top_schools'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) return candidate;

      if (candidate is String && candidate.trim().isNotEmpty) {
        try {
          final parsed = jsonDecode(candidate);
          if (parsed is List) return parsed;
        } catch (_) {
          return candidate
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }

    return [];
  }

  List<String> _extractReasons(Map item) {
    final value = item['reasons'];

    if (value is List) {
      return value
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return [];
  }

  _PlusSchoolItem _parseSchool(dynamic item) {
    if (item is String) {
      return _PlusSchoolItem(
        id: 0,
        name: item,
        imageUrl: null,
        city: '',
        majorName: '',
        description: 'Trường có dữ liệu tuyển sinh phù hợp với ngành này.',
        featured: false,
      );
    }

    if (item is! Map) {
      return _PlusSchoolItem(
        id: 0,
        name: '',
        imageUrl: null,
        city: '',
        majorName: '',
        description: '',
        featured: false,
      );
    }

    return _PlusSchoolItem(
      id: _toInt(item['id'] ?? item['admission_id']),
      name:
          _cleanText(
            item['school_name'] ??
                item['name'] ??
                item['university_name'] ??
                item['title'],
          ) ??
          '',
      imageUrl: AdmissionService.resolveImageUrl(
        _cleanText(
          item['image_url'] ??
              item['logo_url'] ??
              item['logoUrl'] ??
              item['imageUrl'] ??
              item['logo'],
        ),
      ),
      city: _cleanText(item['city']) ?? '',
      majorName: _cleanText(item['major_name'] ?? item['majorName']) ?? '',
      description:
          _cleanText(item['short_description'] ?? item['description']) ?? '',
      featured:
          item['featured'] == true ||
          item['featured'] == 1 ||
          item['featured'] == '1' ||
          item['is_featured'] == true ||
          item['is_featured'] == 1 ||
          item['is_featured'] == '1',
    );
  }

  void _goToAdmission(_PlusSchoolItem school, String careerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdmissionsScreen(
          initialSchool: school.name,
          initialMajor: school.majorName.isNotEmpty
              ? school.majorName
              : careerName,
          autoOpen: true,
        ),
      ),
    );
  }

  String? _cleanText(dynamic value) {
    if (value == null) return null;

    return value
        .toString()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .trim();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.fromHistory) {
        _loadFromHistoryPayload();
        return;
      }

      await _loadPlusRecommendations();
      await _saveHistory();
    });
  }

  Map<String, int> getScores() {
    final payloadScores =
        widget.historyPayload?['mbti_scores'] ??
        widget.historyPayload?['scores'];

    if (widget.fromHistory && payloadScores is Map) {
      return {
        'E': _toInt(payloadScores['E'] ?? payloadScores['score_e']),
        'I': _toInt(payloadScores['I'] ?? payloadScores['score_i']),
        'S': _toInt(payloadScores['S'] ?? payloadScores['score_s']),
        'N': _toInt(payloadScores['N'] ?? payloadScores['score_n']),
        'T': _toInt(payloadScores['T'] ?? payloadScores['score_t']),
        'F': _toInt(payloadScores['F'] ?? payloadScores['score_f']),
        'J': _toInt(payloadScores['J'] ?? payloadScores['score_j']),
        'P': _toInt(payloadScores['P'] ?? payloadScores['score_p']),
      };
    }

    return TestScoreCalculator.mbtiScores(widget.answers);
  }

  String getMbtiType() {
    final saved = widget.historyMbti?.trim().toUpperCase();

    if (widget.fromHistory && saved != null && saved.length == 4) {
      return saved;
    }

    final payloadType = widget.historyPayload?['mbti_type']
        ?.toString()
        .trim()
        .toUpperCase();

    if (widget.fromHistory && payloadType != null && payloadType.length == 4) {
      return payloadType;
    }

    return TestScoreCalculator.mbtiType(widget.answers);
  }

  String getName(String type) {
    const names = {
      'INTJ': 'Kiến trúc sư',
      'INTP': 'Nhà tư duy',
      'ENTJ': 'Người chỉ huy',
      'ENTP': 'Người tranh biện',
      'INFJ': 'Người cố vấn',
      'INFP': 'Người hòa giải',
      'ENFJ': 'Người dẫn dắt',
      'ENFP': 'Người truyền cảm hứng',
      'ISTJ': 'Người trách nhiệm',
      'ISFJ': 'Người bảo vệ',
      'ESTJ': 'Người điều hành',
      'ESFJ': 'Người quan tâm',
      'ISTP': 'Nhà kỹ thuật',
      'ISFP': 'Người nghệ sĩ',
      'ESTP': 'Người hành động',
      'ESFP': 'Người trình diễn',
    };
    return names[type] ?? 'Nhóm tính cách';
  }

  String getDescription(String type) {
    if (type.startsWith('I')) {
      return 'Bạn có xu hướng quan sát sâu, suy nghĩ kỹ trước khi đưa ra quyết định. Khi có không gian phù hợp, bạn dễ phát huy khả năng tập trung, phân tích và tự học.';
    }
    return 'Bạn có xu hướng chủ động, dễ kết nối với môi trường xung quanh và thường học tốt thông qua trao đổi, trải nghiệm hoặc làm việc cùng người khác.';
  }

  Map<String, double> interestPercentages() {
    if (widget.fromHistory && widget.answers.isNotEmpty) {
      return TestScoreCalculator.interestPercentages(widget.answers);
    }

    final payloadScores =
        widget.historyPayload?['interest_group_scores'] ??
        widget.historyPayload?['groupScores'] ??
        widget.historyPayload?['group_scores'];

    if (widget.fromHistory && payloadScores is Map) {
      return {
        'creative': _toDouble(payloadScores['creative']).clamp(0.0, 100.0).toDouble(),
        'analytic': _toDouble(payloadScores['analytic']).clamp(0.0, 100.0).toDouble(),
        'social': _toDouble(payloadScores['social']).clamp(0.0, 100.0).toDouble(),
        'business': _toDouble(payloadScores['business']).clamp(0.0, 100.0).toDouble(),
      };
    }

    return TestScoreCalculator.interestPercentages(widget.answers);
  }

  Map<String, int> interestScores() {
    return TestScoreCalculator.roundedPercentages(interestPercentages());
  }

  Future<void> _saveHistory() async {
    if (_saved) return;
    _saved = true;

    final mbti = getMbtiType();

    try {
      await TestHistoryService.storeHistory(
        packageName: 'plus',
        mbtiType: mbti,
        testName: 'Bài test MBTI Plus',
        resultData: {
          'package_name': 'plus',
          'mbti_type': mbti,
          'name': getName(mbti),
          'description': getDescription(mbti),
          'answers': widget.answers,
          'scores': getScores(),
          'mbti_scores': getScores(),
          'interest_group_scores': interestPercentages(),
          'top_majors': topCareers.map((e) {
            return {
              'name': e.name,
              'description': e.description,
              'score': e.score,
              'reasons': e.reasons,
              'schools': e.schools.map((s) {
                return {
                  'id': s.id,
                  'admission_id': s.id,
                  'name': s.name,
                  'school_name': s.name,
                  'image_url': s.imageUrl,
                  'city': s.city,
                  'major_name': s.majorName,
                  'short_description': s.description,
                  'description': s.description,
                  'featured': s.featured,
                };
              }).toList(),
            };
          }).toList(),
        },
      );
    } catch (e) {
      debugPrint('SAVE PLUS HISTORY ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mbti = getMbtiType();
    final name = getName(mbti);
    final desc = getDescription(mbti);

    final mbtiScores = getScores();
    final interests = interestScores();

    return Scaffold(
      backgroundColor: lightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        title: Text(
          'Kết quả Plus',
          style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        child: Column(
          children: [
            _HeroCard(
              kicker: 'KẾT QUẢ GÓI SỞ THÍCH',
              badge: 'Plus',
              title: '$name ($mbti)',
              description: desc,
              mbti: mbti,
            ),

            const SizedBox(height: 16),

            _MbtiRatioCard(scores: mbtiScores),

            const SizedBox(height: 16),

            _InterestCard(scores: interests),

            const SizedBox(height: 16),

            _InterestHighlightCard(scores: interests),

            const SizedBox(height: 16),

            if (loadingCareers)
              _ResultCard(
                title: 'Gợi ý ngành theo MBTI + sở thích',
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (topCareers.isNotEmpty)
              _ResultCard(
                title: 'Gợi ý ngành theo MBTI + sở thích',
                child: Column(
                  children: topCareers.asMap().entries.map((entry) {
                    return _PlusCareerCard(
                      rank: entry.key + 1,
                      item: entry.value,
                      onSchoolDetail: (school) =>
                          _goToAdmission(school, entry.value.name),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 20),

            _BottomButtons(
              onRetry: () => Navigator.pop(context),
              onHome: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}

const _bodyStyle = TextStyle(
  fontSize: 14.5,
  height: 1.6,
  color: _PlusResultScreenState.textGrey,
  fontWeight: FontWeight.w600,
);

class _HeroCard extends StatelessWidget {
  final String kicker, badge, title, description, mbti;
  const _HeroCard({
    required this.kicker,
    required this.badge,
    required this.title,
    required this.description,
    required this.mbti,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(22),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kicker,
                style: TextStyle(
                  fontSize: 12,
                  color: _PlusResultScreenState.purple,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ),
            _Pill(label: badge, color: _PlusResultScreenState.purple),
          ],
        ),
        SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w900,
            color: _PlusResultScreenState.textDark,
          ),
        ),
        SizedBox(height: 14),
        Text(description, style: _bodyStyle),
        SizedBox(height: 22),
        Center(child: _MbtiBox(mbti: mbti)),
      ],
    ),
  );
}

class _MbtiRatioCard extends StatelessWidget {
  final Map<String, int> scores;

  const _MbtiRatioCard({required this.scores});

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      title: 'Tỉ lệ nhóm tính cách',
      child: Column(
        children: [
          _AxisRow(
            left: 'E',
            right: 'I',
            leftName: 'Hướng ngoại',
            rightName: 'Hướng nội',
            leftValue: scores['E'] ?? 0,
            rightValue: scores['I'] ?? 0,
          ),
          _AxisRow(
            left: 'S',
            right: 'N',
            leftName: 'Thực tế',
            rightName: 'Trực giác',
            leftValue: scores['S'] ?? 0,
            rightValue: scores['N'] ?? 0,
          ),
          _AxisRow(
            left: 'T',
            right: 'F',
            leftName: 'Lý trí',
            rightName: 'Cảm xúc',
            leftValue: scores['T'] ?? 0,
            rightValue: scores['F'] ?? 0,
          ),
          _AxisRow(
            left: 'J',
            right: 'P',
            leftName: 'Kế hoạch',
            rightName: 'Linh hoạt',
            leftValue: scores['J'] ?? 0,
            rightValue: scores['P'] ?? 0,
          ),
        ],
      ),
    );
  }
}

class _AxisRow extends StatelessWidget {
  final String left, right;
  final String leftName, rightName;
  final int leftValue, rightValue;

  const _AxisRow({
    required this.left,
    required this.right,
    required this.leftName,
    required this.rightName,
    required this.leftValue,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    final total = math.max(1, leftValue + rightValue);
    final leftPercent = (leftValue / total).clamp(0.0, 1.0);
    final leftPercentText = (leftPercent * 100).round();
    final rightPercentText = 100 - leftPercentText;

    final isBalanced = leftValue == rightValue;

    final dominantCode = leftValue > rightValue ? left : right;
    final dominantName = leftValue > rightValue ? leftName : rightName;
    final dominantPercent = leftValue > rightValue
        ? leftPercentText
        : rightPercentText;

    final summaryText = isBalanced
        ? 'Cân bằng giữa $left - $leftName và $right - $rightName'
        : 'Nghiêng về $dominantCode - $dominantName ($dominantPercent%)';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EEF8)),
        boxShadow: [
          BoxShadow(
            color: _PlusResultScreenState.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AxisBadge(
                code: left,
                name: leftName,
                active: isBalanced || leftValue > rightValue,
              ),
              const Spacer(),
              _AxisBadge(
                code: right,
                name: rightName,
                active: isBalanced || rightValue > leftValue,
                alignRight: true,
              ),
            ],
          ),

          const SizedBox(height: 14),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: leftPercent),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2F8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Container(
                          height: 13,
                          width: constraints.maxWidth * value,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9B7BEA), Color(0xFF8EC5FC)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                '$left $leftPercentText%',
                style: const TextStyle(
                  color: _PlusResultScreenState.textGrey,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$right $rightPercentText%',
                style: const TextStyle(
                  color: _PlusResultScreenState.textGrey,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: _PlusResultScreenState.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              summaryText,
              style: const TextStyle(
                color: _PlusResultScreenState.textDark,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisBadge extends StatelessWidget {
  final String code;
  final String name;
  final bool active;
  final bool alignRight;

  const _AxisBadge({
    required this.code,
    required this.name,
    required this.active,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active
                ? _PlusResultScreenState.purple.withValues(alpha: 0.14)
                : const Color(0xFFEAF2F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              code,
              style: TextStyle(
                color: active
                    ? _PlusResultScreenState.purple
                    : _PlusResultScreenState.textGrey,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            color: active
                ? _PlusResultScreenState.textDark
                : _PlusResultScreenState.textGrey,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InterestCard extends StatelessWidget {
  final Map<String, int> scores;
  const _InterestCard({required this.scores});
  @override
  Widget build(BuildContext context) {
    final labels = {
      'creative': 'Sáng tạo',
      'analytic': 'Phân tích - Công nghệ',
      'social': 'Con người - Giao tiếp',
      'business': 'Kinh doanh - Tổ chức',
    };
    return _ResultCard(
      title: 'Biểu đồ sở thích',
      child: Column(
        children: scores.entries
            .map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _MiniBar(
                  label: labels[e.key] ?? e.key,
                  value: e.value,
                  color: _PlusResultScreenState.purple,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InterestHighlightCard extends StatelessWidget {
  final Map<String, int> scores;

  const _InterestHighlightCard({required this.scores});

  String _label(String key) {
    const labels = {
      'creative': 'Sáng tạo',
      'analytic': 'Phân tích - Công nghệ',
      'social': 'Con người - Giao tiếp',
      'business': 'Kinh doanh - Tổ chức',
    };

    return labels[key] ?? key;
  }

  String _description(String key) {
    const descriptions = {
      'creative':
          'Bạn có xu hướng thích ý tưởng mới, nội dung, hình ảnh, thẩm mỹ và môi trường học tập linh hoạt.',
      'analytic':
          'Bạn thiên về logic, công nghệ, tối ưu hệ thống và giải quyết vấn đề bằng phân tích.',
      'social':
          'Bạn nổi bật ở khả năng giao tiếp, hỗ trợ người khác, làm việc nhóm và kết nối trong môi trường học tập.',
      'business':
          'Bạn có xu hướng quan tâm đến tổ chức, quản lý, kinh doanh, lập kế hoạch và định hướng mục tiêu.',
    };

    return descriptions[key] ??
        'Nhóm sở thích này phản ánh xu hướng học tập và lĩnh vực bạn nên tiếp tục tìm hiểu.';
  }

  Color _color(String key) {
    if (key == 'creative') return const Color(0xFF9B7BEA);
    if (key == 'analytic') return const Color(0xFF58A6FF);
    if (key == 'social') return const Color(0xFF46C878);
    if (key == 'business') return const Color(0xFFFF9F43);
    return _PlusResultScreenState.purple;
  }

  IconData _icon(String key) {
    if (key == 'creative') return Icons.palette_rounded;
    if (key == 'analytic') return Icons.memory_rounded;
    if (key == 'social') return Icons.groups_rounded;
    if (key == 'business') return Icons.business_center_rounded;
    return Icons.auto_graph_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final entries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = entries.where((e) => e.value > 0).take(2).toList();

    final shownEntries = topEntries.isNotEmpty
        ? topEntries
        : [const MapEntry('creative', 0), const MapEntry('analytic', 0)];

    return _ResultCard(
      title: 'Phân tích sở thích nổi trội',
      child: Column(
        children: shownEntries.map((entry) {
          final color = _color(entry.key);

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4EEF8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(_icon(entry.key), color: color, size: 23),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(entry.key),
                        style: const TextStyle(
                          color: _PlusResultScreenState.textDark,
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _description(entry.key),
                        style: const TextStyle(
                          color: _PlusResultScreenState.textGrey,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniBar({
    required this.label,
    required this.value,
    required this.color,
  });

  Color _barColor(String label) {
    if (label.contains('Sáng tạo')) return const Color(0xFF9B7BEA);
    if (label.contains('Phân tích')) return const Color(0xFF58A6FF);
    if (label.contains('Con người')) return const Color(0xFF46C878);
    if (label.contains('Kinh doanh')) return const Color(0xFFFF9F43);
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _barColor(label);
    final percent = value.clamp(0, 100) / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EEF8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: barColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '$value%',
                style: const TextStyle(
                  color: _PlusResultScreenState.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2F8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Container(
                        height: 13,
                        width: constraints.maxWidth * animatedValue,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              barColor.withValues(alpha: 0.75),
                              barColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color background;
  final Color borderColor;
  const _ResultCard({
    required this.title,
    required this.child,
    this.background = Colors.white,
    this.borderColor = _PlusResultScreenState.borderColor,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(19),
    decoration: _cardDecoration(
      background: background,
      borderColor: borderColor,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 23,
            height: 1.2,
            fontWeight: FontWeight.w900,
            color: _PlusResultScreenState.textDark,
          ),
        ),
        SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _MbtiBox extends StatelessWidget {
  final String mbti;

  const _MbtiBox({required this.mbti});

  @override
  Widget build(BuildContext context) {
    final origin = AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final imageUrl = '$origin/images/emoji2/${mbti.toUpperCase()}.png';

    return SizedBox(
      width: 150,
      height: 150,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          return Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  _PlusResultScreenState.purple,
                  _PlusResultScreenState.primaryBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: Text(
                mbti,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
    ),
  );
}

class _BottomButtons extends StatelessWidget {
  final VoidCallback onRetry, onHome;
  const _BottomButtons({required this.onRetry, required this.onHome});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ActionButton(
          text: 'Làm lại',
          color: Color(0xFFEAF6FF),
          textColor: _PlusResultScreenState.textDark,
          onTap: onRetry,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _ActionButton(
          text: 'Về trang chủ',
          color: _PlusResultScreenState.purple,
          textColor: Colors.white,
          onTap: onHome,
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color, textColor;
  final VoidCallback onTap;
  const _ActionButton({
    required this.text,
    required this.color,
    required this.textColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w900)),
    ),
  );
}

BoxDecoration _cardDecoration({
  Color background = Colors.white,
  Color borderColor = _PlusResultScreenState.borderColor,
}) => BoxDecoration(
  color: background,
  borderRadius: BorderRadius.circular(26),
  border: Border.all(color: _PlusResultScreenState.borderColor),
  boxShadow: [
    BoxShadow(
      color: _PlusResultScreenState.primaryBlue.withValues(alpha: .08),
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
  ],
);

class _PlusCareerItem {
  final String name;
  final String description;
  final double score;
  final List<String> reasons;
  final List<_PlusSchoolItem> schools;

  const _PlusCareerItem({
    required this.name,
    required this.description,
    required this.score,
    required this.reasons,
    required this.schools,
  });
}

class _PlusSchoolItem {
  final int id;
  final String name;
  final String? imageUrl;
  final String city;
  final String majorName;
  final String description;
  final bool featured;

  const _PlusSchoolItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.city,
    required this.majorName,
    required this.description,
    required this.featured,
  });
}

class _PlusCareerCard extends StatelessWidget {
  final int rank;
  final _PlusCareerItem item;
  final void Function(_PlusSchoolItem school) onSchoolDetail;

  const _PlusCareerCard({
    required this.rank,
    required this.item,
    required this.onSchoolDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Color(0xFFE4EEF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Color(0xFFEAF6FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: Color(0xFF1689D5),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    color: Color(0xFF29425E),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            item.description,
            style: TextStyle(
              color: Color(0xFF617587),
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.reasons.isNotEmpty) ...[
            SizedBox(height: 10),
            ...item.reasons.map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $e',
                  style: TextStyle(
                    color: Color(0xFF617587),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (item.schools.isNotEmpty) ...[
            SizedBox(height: 14),
            Text(
              'Trường gợi ý',
              style: TextStyle(
                color: Color(0xFF29425E),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 18,
              children: item.schools.map((school) {
                return _PlusSchoolLogo(
                  school: school,
                  onDetail: () => onSchoolDetail(school),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlusSchoolLogo extends StatelessWidget {
  final _PlusSchoolItem school;
  final VoidCallback onDetail;

  const _PlusSchoolLogo({required this.school, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetail,
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: school.featured ? Color(0xFFFFC857) : Color(0xFFE4EEF8),
                width: school.featured ? 2 : 1,
              ),
              boxShadow: school.featured
                  ? [
                      BoxShadow(
                        color: Color(0xFFFFC857).withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: school.imageUrl == null || school.imageUrl!.isEmpty
                ? Center(
                    child: Text(
                      school.name.isEmpty ? 'T' : school.name[0],
                      style: TextStyle(
                        color: Color(0xFF1689D5),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : Image.network(
                    school.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) {
                      return Center(
                        child: Text(
                          school.name.isEmpty ? 'T' : school.name[0],
                          style: TextStyle(
                            color: Color(0xFF1689D5),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (school.featured)
            Positioned(
              bottom: -12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(0xFFFF9F1C),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Nhà tài trợ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
