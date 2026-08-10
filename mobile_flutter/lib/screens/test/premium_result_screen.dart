import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../services/test_history_service.dart';
import '../main/main_screen.dart';
import '../admissions/admissions_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../utils/test_score_calculator.dart';
import '../../core/widgets/premium_overview_card.dart';

class PremiumResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> answers;
  final bool fromHistory;
  final Map<String, dynamic>? historyPayload;
  final String? historyMbti;

  const PremiumResultScreen({
    super.key,
    required this.answers,
    this.fromHistory = false,
    this.historyMbti,
    this.historyPayload,
  });

  @override
  State<PremiumResultScreen> createState() => _PremiumResultScreenState();
}

class _PremiumResultScreenState extends State<PremiumResultScreen> {
  bool _saved = false;
  bool loadingCareers = false;
  String aiCareerAnalysis = '';
  List<_CareerItem> topCareers = [];
  List<_AbilityDisplayItem> aiTopAbilities = [];

  static const primaryBlue = Color(0xFF8EC5FC);
  static const purple = Color(0xFF9B7BEA);
  static const green = Color(0xFF43AD72);
  static const lightBlue = Colors.white;
  static const textDark = Color(0xFF29425E);
  static const textGrey = Color(0xFF617587);
  static const borderColor = Color(0xFFE4EEF8);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fromHistory) {
        _loadFromHistoryPayload();
        return;
      }

      setState(() {
        aiTopAbilities = fallbackTopAbilities();
      });
      _loadPremiumRecommendations();
    });
  }

  void _loadFromHistoryPayload() {
    final payload = widget.historyPayload ?? {};
    debugPrint("============= HISTORY PAYLOAD =============");
    debugPrint(payload.toString());
    debugPrint("============= END =============");

    final majors =
        payload['top_majors'] ??
        payload['top_major'] ??
        payload['recommended_majors'] ??
        payload['career_recommendations'] ??
        payload['careers'] ??
        payload['majors'] ??
        payload['recommendations'] ??
        (payload['data'] is Map ? payload['data']['top_majors'] : null) ??
        (payload['data'] is Map ? payload['data']['majors'] : null) ??
        (payload['data'] is Map ? payload['data']['recommendations'] : null);

    if (majors is List) {
      topCareers = majors
          .map(_parseCareer)
          .where((e) => e.name.isNotEmpty)
          .toList();
    }

    aiTopAbilities = fallbackTopAbilities();

    aiCareerAnalysis =
        _cleanText(payload['ai_analysis'] ?? payload['analysis']) ?? '';

    setState(() {});
    debugPrint('HISTORY PAYLOAD KEYS: ${payload.keys.toList()}');
    debugPrint('HISTORY PAYLOAD: $payload');
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

  String cleanHtmlText(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'</h4>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .trim();
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

  Map<String, double> interestPercentages() {
    if (widget.fromHistory && widget.answers.isNotEmpty) {
      return TestScoreCalculator.interestPercentages(widget.answers);
    }

    final saved = widget.historyPayload?['interest_group_scores'];

    if (widget.fromHistory && saved is Map) {
      return {
        'creative': _toDouble(saved['creative']).clamp(0.0, 100.0).toDouble(),
        'analytic': _toDouble(saved['analytic']).clamp(0.0, 100.0).toDouble(),
        'social': _toDouble(saved['social']).clamp(0.0, 100.0).toDouble(),
        'business': _toDouble(saved['business']).clamp(0.0, 100.0).toDouble(),
      };
    }

    return TestScoreCalculator.interestPercentages(widget.answers);
  }

  Map<String, int> interestScores() {
    return TestScoreCalculator.roundedPercentages(interestPercentages());
  }

  Map<String, double> abilityPercentages() {
    if (widget.fromHistory && widget.answers.isNotEmpty) {
      return TestScoreCalculator.abilityPercentages(widget.answers);
    }

    final saved = widget.historyPayload?['ability_scores'];

    if (widget.fromHistory && saved is Map) {
      return {
        for (final key in TestScoreCalculator.abilityKeys)
          key: _toDouble(
            saved[key] ?? saved[key.toLowerCase()],
          ).clamp(0.0, 100.0).toDouble(),
      };
    }

    return TestScoreCalculator.abilityPercentages(widget.answers);
  }

  Map<String, int> abilityScores() {
    return TestScoreCalculator.roundedPercentages(abilityPercentages());
  }

  List<_CombinedDatum> combinedChartData() {
    final interest = interestScores();
    final ability = abilityScores();
    return [
      _CombinedDatum(
        label: 'Sáng tạo',
        interest: interest['creative'] ?? 0,
        ability: ability['CREATIVE'] ?? 0,
      ),
      _CombinedDatum(
        label: 'Phân tích',
        interest: interest['analytic'] ?? 0,
        ability: (((ability['LOGIC'] ?? 0) + (ability['TECH'] ?? 0)) / 2)
            .round(),
      ),
      _CombinedDatum(
        label: 'Giao tiếp',
        interest: interest['social'] ?? 0,
        ability: (((ability['LANGUAGE'] ?? 0) + (ability['TEAMWORK'] ?? 0)) / 2)
            .round(),
      ),
      _CombinedDatum(
        label: 'Lãnh đạo',
        interest: interest['business'] ?? 0,
        ability: ability['LEADERSHIP'] ?? 0,
      ),
      _CombinedDatum(
        label: 'Công nghệ',
        interest: interest['analytic'] ?? 0,
        ability: (((ability['TECH'] ?? 0) + (ability['PRACTICAL'] ?? 0)) / 2)
            .round(),
      ),
      _CombinedDatum(
        label: 'Chiến lược',
        interest: interest['business'] ?? 0,
        ability: (((ability['STRATEGIC'] ?? 0) + (ability['ADAPT'] ?? 0)) / 2)
            .round(),
      ),
    ];
  }

  List<_AbilityDisplayItem> fallbackTopAbilities() {
    const labels = {
      'LANGUAGE': 'Ngôn ngữ',
      'LOGIC': 'Tư duy logic',
      'CREATIVE': 'Sáng tạo',
      'TECH': 'Công nghệ',
      'LEADERSHIP': 'Lãnh đạo',
      'TEAMWORK': 'Làm việc nhóm',
      'DETAIL': 'Chi tiết - Cẩn thận',
      'ADAPT': 'Thích nghi',
      'PRACTICAL': 'Thực hành',
      'STRATEGIC': 'Chiến lược',
    };

    // Thứ tự tương đương localeCompare(..., 'vi') trên Angular
    // khi hai năng lực có cùng tỷ lệ.
    const vietnameseLabelOrder = {
      'DETAIL': 0,
      'STRATEGIC': 1,
      'TECH': 2,
      'TEAMWORK': 3,
      'LEADERSHIP': 4,
      'LANGUAGE': 5,
      'CREATIVE': 6,
      'ADAPT': 7,
      'PRACTICAL': 8,
      'LOGIC': 9,
    };
    const descriptions = {
      'LANGUAGE':
          'Bạn có khả năng diễn đạt ý tưởng, trình bày và truyền tải thông tin khá tốt.',
      'LOGIC':
          'Bạn mạnh về tư duy phân tích, lập luận và nhìn ra cấu trúc của vấn đề.',
      'CREATIVE':
          'Bạn có xu hướng nghĩ ra ý tưởng mới, cách làm mới và góc nhìn khác biệt.',
      'TECH': 'Bạn tiếp cận tốt với công cụ, công nghệ và môi trường kỹ thuật.',
      'LEADERSHIP':
          'Bạn có xu hướng dẫn dắt, định hướng và chủ động ra quyết định.',
      'TEAMWORK':
          'Bạn phối hợp tốt với người khác, kết nối và hỗ trợ nhóm hiệu quả.',
      'DETAIL': 'Bạn chú ý chi tiết, cẩn thận và có xu hướng hạn chế sai sót.',
      'ADAPT': 'Bạn linh hoạt, phản ứng nhanh và thích nghi tốt với thay đổi.',
      'PRACTICAL':
          'Bạn nghiêng về triển khai thực tế, áp dụng nhanh và xử lý tình huống thật.',
      'STRATEGIC':
          'Bạn có xu hướng nhìn dài hạn, định hướng mục tiêu và lên kế hoạch tốt.',
    };
    final entries = abilityPercentages().entries.toList()
      ..sort((a, b) {
        final byScore = b.value.compareTo(a.value);
        if (byScore != 0) return byScore;
        return (vietnameseLabelOrder[a.key] ?? 99).compareTo(
          vietnameseLabelOrder[b.key] ?? 99,
        );
      });
    return entries
        .take(3)
        .map(
          (entry) => _AbilityDisplayItem(
            title: labels[entry.key] ?? entry.key,
            percent: entry.value.round().clamp(0, 100).toInt(),
            description:
                descriptions[entry.key] ??
                'Đây là năng lực nổi bật trong kết quả của bạn.',
          ),
        )
        .toList();
  }

  Future<void> _saveHistory() async {
    if (_saved) return;
    _saved = true;

    final mbti = getMbtiType();

    try {
      await TestHistoryService.storeHistory(
        packageName: 'premium',
        mbtiType: mbti,
        testName: 'Bài test MBTI Premium',
        resultData: {
          'package_name': 'premium',
          'mbti_type': mbti,
          'name': getName(mbti),
          'answers': widget.answers,
          'scores': getScores(),
          'mbti_scores': getScores(),
          'interest_group_scores': interestPercentages(),
          'ability_scores': abilityPercentages(),
          'combined_chart_data': combinedChartData()
              .map(
                (item) => {
                  'label': item.label,
                  'interestRaw': item.interest,
                  'abilityRaw': item.ability,
                },
              )
              .toList(),
          'top_abilities': aiTopAbilities
              .map(
                (item) => {
                  'title': item.title,
                  'percent': item.percent,
                  'description': item.description,
                },
              )
              .toList(),
          'ai_analysis': aiCareerAnalysis,
          'top_majors': topCareers.map((career) {
            return {
              'name': career.name,
              'description': career.description,
              'score': career.score,
              'schools': career.schools.map((school) {
                return {
                  'name': school.name,
                  'school_name': school.name,
                  'image_url': school.imageUrl,
                  'short_description': school.description,
                  'description': school.description,
                  'featured': school.featured,
                };
              }).toList(),
            };
          }).toList(),
        },
      );
    } catch (error) {
      debugPrint('SAVE PREMIUM HISTORY ERROR: $error');
    }
  }

  Future<void> _loadPremiumRecommendations() async {
    if (mounted) {
      setState(() {
        loadingCareers = true;
      });
    }

    final payload = {
      'level': 'premium',
      'mbti_type': getMbtiType(),
      'mbti_scores': getScores(),
      'interest_group_scores': interestPercentages(),
      'ability_scores': abilityPercentages(),
      'limit': 5,
    };

    final endpoint = '${AuthService.baseUrl}/recommendations/majors';

    debugPrint('========== PREMIUM REQUEST ==========');
    debugPrint('ENDPOINT: $endpoint');
    debugPrint('PAYLOAD: ${jsonEncode(payload)}');
    debugPrint('=====================================');

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
          .timeout(const Duration(seconds: 150));

      debugPrint('========== PREMIUM RESPONSE ==========');
      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: ${res.body}');
      debugPrint('======================================');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('API lỗi ${res.statusCode}: ${res.body}');
      }

      final dynamic data = jsonDecode(res.body);

      final majors = _extractMajorList(data);

      dynamic rawAnalysis;

      if (data is Map) {
        rawAnalysis = data['ai_analysis'];

        if (rawAnalysis == null && data['data'] is Map) {
          rawAnalysis = data['data']['ai_analysis'];
        }
      }

      final analysis = _cleanText(rawAnalysis);

      debugPrint(
        'AI ANALYSIS RECEIVED: '
        '${analysis ?? 'NULL'}',
      );

      if (mounted) {
        setState(() {
          topCareers = majors
              .map(_parseCareer)
              .where((item) => item.name.isNotEmpty)
              .toList();

          aiCareerAnalysis = analysis ?? '';
        });
      }

      if (!widget.fromHistory) {
        await _saveHistory();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'LOAD PREMIUM RECOMMENDATION ERROR: '
        '$error',
      );

      debugPrint('STACK TRACE: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          loadingCareers = false;
        });
      }
    }
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

  _CareerItem _parseCareer(dynamic item) {
    if (item is! Map)
      return _CareerItem(name: '', description: '', score: 0, schools: []);
    return _CareerItem(
      name:
          _cleanText(item['name'] ?? item['major_name'] ?? item['title']) ?? '',
      description:
          _cleanText(item['description'] ?? item['short_description']) ??
          'Ngành học này có mức độ phù hợp với tổ hợp MBTI, sở thích và năng lực của bạn.',
      score: _toDouble(item['score'] ?? item['match_score'] ?? item['percent']),
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

  _SchoolItem _parseSchool(dynamic item) {
    if (item is String)
      return _SchoolItem(
        name: item,
        imageUrl: null,
        description: 'Trường có dữ liệu tuyển sinh phù hợp với ngành này.',
        featured: false,
      );
    if (item is! Map)
      return _SchoolItem(
        name: '',
        imageUrl: null,
        description: '',
        featured: false,
      );
    return _SchoolItem(
      name:
          _cleanText(
            item['school_name'] ??
                item['name'] ??
                item['university_name'] ??
                item['title'],
          ) ??
          '',
      imageUrl: _resolveImageUrl(
        item['image_url'] ?? item['logo_url'] ?? item['logo'] ?? item['image'],
      ),
      description:
          _cleanText(
            item['short_description'] ?? item['description'] ?? item['reason'],
          ) ??
          'Trường có dữ liệu tuyển sinh phù hợp với ngành này.',
      featured:
          item['featured'] == true ||
          item['is_featured'] == true ||
          item['featured'] == 1 ||
          item['is_featured'] == 1 ||
          item['featured'] == '1' ||
          item['is_featured'] == '1',
    );
  }

  String? _resolveImageUrl(dynamic value) {
    final raw = _cleanText(value);
    if (raw == null) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final origin = AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (raw.startsWith('/images/') || raw.startsWith('/assets/'))
      return '$origin$raw';
    final cleaned = raw.startsWith('/') ? raw.substring(1) : raw;
    if (cleaned.startsWith('images/') ||
        cleaned.startsWith('assets/') ||
        cleaned.startsWith('storage/'))
      return '$origin/$cleaned';
    return '$origin/storage/$cleaned';
  }

  static String? _cleanText(dynamic value) {
    if (value == null) return null;
    var text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    text = text
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .trim();
    return text.isEmpty ? null : text;
  }

  static int _toInt(dynamic value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _toDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final mbti = getMbtiType();

    final interests = interestScores();
    final abilities = abilityScores();

    final visibleTopAbilities = aiTopAbilities.isNotEmpty
        ? aiTopAbilities
        : fallbackTopAbilities();
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.title(context)),
        title: Text(
          'Kết quả Premium',
          style: TextStyle(
            color: AppColors.title(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 30),
        child: Column(
          children: [
            PremiumOverviewCard(
              mbti: mbti,
              interests: {
                'creative': (interests['creative'] ?? 0).toDouble(),
                'analytic': (interests['analytic'] ?? 0).toDouble(),
                'social': (interests['social'] ?? 0).toDouble(),
                'business': (interests['business'] ?? 0).toDouble(),
              },
              abilities: {
                'LANGUAGE': (abilities['LANGUAGE'] ?? 0).toDouble(),
                'LOGIC': (abilities['LOGIC'] ?? 0).toDouble(),
                'CREATIVE': (abilities['CREATIVE'] ?? 0).toDouble(),
                'TECH': (abilities['TECH'] ?? 0).toDouble(),
                'LEADERSHIP': (abilities['LEADERSHIP'] ?? 0).toDouble(),
                'TEAMWORK': (abilities['TEAMWORK'] ?? 0).toDouble(),
                'DETAIL': (abilities['DETAIL'] ?? 0).toDouble(),
                'ADAPT': (abilities['ADAPT'] ?? 0).toDouble(),
                'PRACTICAL': (abilities['PRACTICAL'] ?? 0).toDouble(),
                'STRATEGIC': (abilities['STRATEGIC'] ?? 0).toDouble(),
              },
            ),

            const SizedBox(height: 16),

            PremiumTopAbilitiesCard(
              loading: false,
              items: visibleTopAbilities
                  .map(
                    (item) => PremiumAbilityItem(
                      title: item.title,
                      percent: item.percent.toDouble(),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 16),
            _PremiumCareerCard(
              loading: loadingCareers,
              aiAnalysis: aiCareerAnalysis,
              careers: topCareers,
            ),
            SizedBox(height: 20),
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

TextStyle _bodyStyle(BuildContext context) {
  return TextStyle(
    fontSize: 14.5,
    height: 1.6,
    color: AppColors.subText(context),
    fontWeight: FontWeight.w600,
  );
}

String _stripHtmlText(String html) {
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</h1>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</h2>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</h3>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</h4>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

void _showSchoolDetailBottomSheet(
  BuildContext context,
  _SchoolItem school,
  _CareerItem career,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        padding: EdgeInsets.fromLTRB(22, 18, 22, 28),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(height: 22),

              Container(
                width: 96,
                height: 96,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softCard(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: school.imageUrl == null
                    ? Center(
                        child: Text(
                          school.name.isNotEmpty ? school.name[0] : 'T',
                          style: TextStyle(
                            color: AppColors.title(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                          ),
                        ),
                      )
                    : Image.network(
                        school.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) {
                          return Center(
                            child: Text(
                              school.name.isNotEmpty ? school.name[0] : 'T',
                              style: TextStyle(
                                color: AppColors.title(context),
                                fontWeight: FontWeight.w900,
                                fontSize: 34,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              SizedBox(height: 16),

              Text(
                school.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  color: AppColors.title(context),
                  fontWeight: FontWeight.w900,
                ),
              ),

              SizedBox(height: 12),

              Text(
                school.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: AppColors.subText(context),
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MainScreen(
                          initialIndex: 3,
                          admissionsScreen: AdmissionsScreen(
                            initialSchool: school.name,
                            initialMajor: career.name,
                            autoOpen: true,
                          ),
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _PremiumResultScreenState.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Xem chi tiết',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _HeroPremiumCard extends StatelessWidget {
  final String mbti, title;
  const _HeroPremiumCard({required this.mbti, required this.title});

  @override
  Widget build(BuildContext context) {
    final origin = AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final robotUrl = '$origin/images/emoji/$mbti.png';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22),
      decoration: _cardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KẾT QUẢ GÓI NĂNG LỰC + SỞ THÍCH',
                  style: TextStyle(
                    fontSize: 12,
                    color: _PremiumResultScreenState.purple,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 31,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    color: AppColors.title(context),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Kết quả này được tổng hợp từ MBTI, sở thích và năng lực để đưa ra định hướng sâu hơn.',
                  style: _bodyStyle(context),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Image.network(
            robotUrl,
            width: 92,
            height: 92,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _PremiumResultScreenState.purple,
                    _PremiumResultScreenState.primaryBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  mbti,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// override incomplete const body by separate build extension style
class _CombinedRadarCard extends StatelessWidget {
  final List<_CombinedDatum> data;
  const _CombinedRadarCard({required this.data});
  @override
  Widget build(BuildContext context) => _ResultCard(
    title: 'Biểu đồ kết hợp sở thích và năng lực',
    subtitle:
        'Hai lớp dữ liệu được đặt trên cùng một hệ trục để thấy rõ vùng nổi trội tổng hợp.',
    child: Column(
      children: [
        Row(
          children: [
            _LegendDot(label: 'Sở thích', color: Color(0xFF77BBE9)),
            SizedBox(width: 12),
            _LegendDot(label: 'Năng lực', color: Color(0xFF8D66AA)),
          ],
        ),
        SizedBox(height: 18),
        SizedBox(
          height: 280,
          child: CustomPaint(
            painter: _RadarPainter(data),
            child: SizedBox.expand(),
          ),
        ),
        SizedBox(height: 18),
        ...data.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _MetricPairRow(item: item),
          ),
        ),
      ],
    ),
  );
}

class _MetricPairRow extends StatelessWidget {
  final _CombinedDatum item;
  const _MetricPairRow({required this.item});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.softCard(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border(context)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: TextStyle(
            color: AppColors.title(context),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        SizedBox(height: 10),
        _MiniBar(
          label: 'Sở thích',
          value: item.interest,
          color: Color(0xFF77BBE9),
        ),
        SizedBox(height: 8),
        _MiniBar(
          label: 'Năng lực',
          value: item.ability,
          color: Color(0xFF8D66AA),
        ),
      ],
    ),
  );
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
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 70,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (value / 50).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.softCard(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      SizedBox(width: 10),
      SizedBox(
        width: 38,
        child: Text(
          '$value%',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.title(context),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    ],
  );
}

class _TopAbilityCard extends StatelessWidget {
  final bool loading;
  final List<_AbilityDisplayItem> items;
  const _TopAbilityCard({required this.loading, required this.items});
  @override
  Widget build(BuildContext context) => _ResultCard(
    title: 'Top năng lực nổi trội',
    child: Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.softCard(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RankBadge(rank: index + 1),
              SizedBox(height: 10),
              Text(
                item.title,
                style: TextStyle(
                  color: AppColors.title(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              _MiniBar(
                label: 'Nổi trội',
                value: item.percent,
                color: _PremiumResultScreenState.purple,
              ),
              SizedBox(height: 10),
              Text(item.description, style: _bodyStyle(context)),
            ],
          ),
        );
      }),
    ),
  );
}

String _normalizeAiContent(String rawText) {
  return rawText
      // Xuống dòng cho các tiêu đề HTML
      .replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n')
      // Giữ dấu nhấn mạnh để xử lý bằng TextSpan
      .replaceAll(RegExp(r'<strong[^>]*>', caseSensitive: false), '**')
      .replaceAll(RegExp(r'</strong>', caseSensitive: false), '**')
      .replaceAll(RegExp(r'<b[^>]*>', caseSensitive: false), '**')
      .replaceAll(RegExp(r'</b>', caseSensitive: false), '**')
      // Danh sách
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '')
      // Đoạn văn và xuống dòng
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
      // Xóa các thẻ HTML còn lại
      .replaceAll(RegExp(r'<[^>]*>'), '')
      // Giải mã HTML
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      // Làm sạch khoảng trắng
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n[ \t]+'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

List<InlineSpan> _buildHighlightedSpans({
  required BuildContext context,
  required String text,
  required TextStyle normalStyle,
  Color? strongColor,
}) {
  final spans = <InlineSpan>[];

  /*
   * Bắt các nội dung dạng:
   * **nội dung quan trọng**
   *
   * Backend có thể trả:
   * <strong>...</strong>
   * <b>...</b>
   * hoặc Markdown **...**
   *
   * Các thẻ HTML đã được đổi thành ** ở hàm
   * _normalizeAiContent().
   */
  final boldPattern = RegExp(r'\*\*(.+?)\*\*', dotAll: true);

  var currentIndex = 0;

  for (final match in boldPattern.allMatches(text)) {
    if (match.start > currentIndex) {
      final normalText = text.substring(currentIndex, match.start);

      spans.addAll(
        _highlightSpecialValues(
          context: context,
          text: normalText,
          normalStyle: normalStyle,
        ),
      );
    }

    final boldText = match.group(1) ?? '';

    spans.add(
      TextSpan(
        text: boldText,
        style: normalStyle.copyWith(
          color: strongColor ?? const Color(0xFF7040D8),
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    currentIndex = match.end;
  }

  if (currentIndex < text.length) {
    spans.addAll(
      _highlightSpecialValues(
        context: context,
        text: text.substring(currentIndex),
        normalStyle: normalStyle,
      ),
    );
  }

  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: normalStyle));
  }

  return spans;
}

List<InlineSpan> _highlightSpecialValues({
  required BuildContext context,
  required String text,
  required TextStyle normalStyle,
}) {
  final spans = <InlineSpan>[];

  /*
   * Tự động nhấn mạnh:
   * - 16 nhóm MBTI
   * - Tỷ lệ phần trăm
   * - Các từ Free, Plus, Premium, MBTI
   */
  final specialPattern = RegExp(
    r'\b(?:'
    r'INTJ|INTP|ENTJ|ENTP|'
    r'INFJ|INFP|ENFJ|ENFP|'
    r'ISTJ|ISFJ|ESTJ|ESFJ|'
    r'ISTP|ISFP|ESTP|ESFP|'
    r'MBTI|Premium|Plus|Free'
    r')\b'
    r'|'
    r'\b\d+(?:[.,]\d+)?%',
    caseSensitive: false,
  );

  var currentIndex = 0;

  for (final match in specialPattern.allMatches(text)) {
    if (match.start > currentIndex) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex, match.start),
          style: normalStyle,
        ),
      );
    }

    final value = match.group(0) ?? '';

    spans.add(
      TextSpan(
        text: value,
        style: normalStyle.copyWith(
          color: const Color(0xFF7040D8),
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    currentIndex = match.end;
  }

  if (currentIndex < text.length) {
    spans.add(TextSpan(text: text.substring(currentIndex), style: normalStyle));
  }

  return spans;
}

class _AiRichAnalysis extends StatelessWidget {
  final String content;

  const _AiRichAnalysis({required this.content});

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeAiContent(content);

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return Text(
        'Chưa nhận được nội dung phân tích từ AI.',
        style: TextStyle(
          color: AppColors.subText(context),
          fontSize: 14.5,
          height: 1.6,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final widgets = <Widget>[];

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];

      final section = _detectAiSection(line);

      if (section != null) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 18, bottom: 8),
            child: _AiSectionTitle(
              title: section.title,
              number: section.number,
              color: section.color,
            ),
          ),
        );

        final remainingContent = _removeSectionTitle(line, section);

        if (remainingContent.isNotEmpty) {
          widgets.add(
            _AiParagraph(text: remainingContent, strongColor: section.color),
          );
        }

        continue;
      }

      if (line.startsWith('•') ||
          line.startsWith('- ') ||
          line.startsWith('– ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _AiBulletLine(
              text: line.replaceFirst(RegExp(r'^[•\-–]\s*'), '').trim(),
            ),
          ),
        );

        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _AiParagraph(text: line),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  _AiSectionData? _detectAiSection(String line) {
    final cleaned = line
        .replaceAll('**', '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    // MỤC 1
    if (RegExp(
      r'^(?:1[\.\)]?\s*)?(?:'
      r'Điểm nổi bật của bạn|'
      r'Điểm nổi bật|'
      r'Điểm mạnh của bạn|'
      r'Điểm mạnh|'
      r'Phân tích điểm nổi bật'
      r')\??\s*:?',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return const _AiSectionData(
        number: '01',
        title: 'Điểm nổi bật của bạn',
        color: Color(0xFF7040D8),
        patterns: [
          r'^(?:1[\.\)]?\s*)?Điểm nổi bật của bạn\??\s*:?\s*',
          r'^(?:1[\.\)]?\s*)?Điểm nổi bật\??\s*:?\s*',
          r'^(?:1[\.\)]?\s*)?Điểm mạnh của bạn\??\s*:?\s*',
          r'^(?:1[\.\)]?\s*)?Điểm mạnh\??\s*:?\s*',
          r'^(?:1[\.\)]?\s*)?Phân tích điểm nổi bật\??\s*:?\s*',
        ],
      );
    }

    // MỤC 2
    if (RegExp(
      r'^(?:2[\.\)]?\s*)?(?:'
      r'Vì sao ngành và trường này phù hợp|'
      r'Vì sao ngành nghề và trường học phù hợp|'
      r'Vì sao ngành này phù hợp|'
      r'Vì sao phù hợp|'
      r'Lý do phù hợp'
      r')\??\s*:?',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return const _AiSectionData(
        number: '02',
        title: 'Vì sao ngành và trường này phù hợp?',
        color: Color(0xFF1686E8),
        patterns: [
          r'^(?:2[\.\)]?\s*)?Vì sao ngành và trường này phù hợp\??\s*:?\s*',
          r'^(?:2[\.\)]?\s*)?Vì sao ngành nghề và trường học phù hợp\??\s*:?\s*',
          r'^(?:2[\.\)]?\s*)?Vì sao ngành này phù hợp\??\s*:?\s*',
          r'^(?:2[\.\)]?\s*)?Vì sao phù hợp\??\s*:?\s*',
          r'^(?:2[\.\)]?\s*)?Lý do phù hợp\??\s*:?\s*',
        ],
      );
    }

    // MỤC 3
    if (RegExp(
      r'^(?:3[\.\)]?\s*)?(?:'
      r'Gợi ý tiếp theo|'
      r'Gợi ý dành cho bạn|'
      r'Định hướng tiếp theo|'
      r'Gợi ý phát triển|'
      r'Bạn nên làm gì tiếp theo'
      r')\??\s*:?',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return const _AiSectionData(
        number: '03',
        title: 'Gợi ý tiếp theo',
        color: Color(0xFFF08A00),
        patterns: [
          r'^(?:3[\.\)]?\s*)?Gợi ý tiếp theo\??\s*:?\s*',
          r'^(?:3[\.\)]?\s*)?Gợi ý dành cho bạn\??\s*:?\s*',
          r'^(?:3[\.\)]?\s*)?Định hướng tiếp theo\??\s*:?\s*',
          r'^(?:3[\.\)]?\s*)?Gợi ý phát triển\??\s*:?\s*',
          r'^(?:3[\.\)]?\s*)?Bạn nên làm gì tiếp theo\??\s*:?\s*',
        ],
      );
    }

    return null;
  }

  String _removeSectionTitle(String line, _AiSectionData section) {
    var result = line.replaceAll('**', '').trim();

    for (final pattern in section.patterns) {
      result = result.replaceFirst(RegExp(pattern, caseSensitive: false), '');
    }

    return result.trim();
  }
}

class _AiSectionData {
  final String number;
  final String title;
  final Color color;
  final List<String> patterns;

  const _AiSectionData({
    required this.number,
    required this.title,
    required this.color,
    required this.patterns,
  });
}

class _AiSectionTitle extends StatelessWidget {
  final String number;
  final String title;
  final Color color;

  const _AiSectionTitle({
    required this.number,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 31,
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 17,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AiParagraph extends StatelessWidget {
  final String text;
  final Color? strongColor;

  const _AiParagraph({required this.text, this.strongColor});

  @override
  Widget build(BuildContext context) {
    final normalStyle = TextStyle(
      color: AppColors.subText(context),
      fontSize: 14.5,
      height: 1.65,
      fontWeight: FontWeight.w600,
    );

    return RichText(
      text: TextSpan(
        children: _buildHighlightedSpans(
          context: context,
          text: text,
          normalStyle: normalStyle,
          strongColor: strongColor,
        ),
      ),
    );
  }
}

class _AiBulletLine extends StatelessWidget {
  final String text;

  const _AiBulletLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final normalStyle = TextStyle(
      color: AppColors.subText(context),
      fontSize: 14.5,
      height: 1.6,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 8, right: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF7040D8),
            shape: BoxShape.circle,
          ),
        ),

        Expanded(
          child: RichText(
            text: TextSpan(
              children: _buildHighlightedSpans(
                context: context,
                text: text,
                normalStyle: normalStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumCareerCard extends StatelessWidget {
  final bool loading;
  final String aiAnalysis;
  final List<_CareerItem> careers;

  const _PremiumCareerCard({
    required this.loading,
    required this.aiAnalysis,
    required this.careers,
  });

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      title: 'Định hướng nghề nghiệp dành cho bạn',
      subtitle:
          'Phân tích cá nhân hóa từ MBTI, sở thích, năng lực và dữ liệu ngành học.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.softCard(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7040D8), Color(0xFF9B63EF)],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI phân tích đề xuất',
                            style: TextStyle(
                              color: AppColors.title(context),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tóm tắt những yếu tố quan trọng trong hồ sơ của bạn',
                            style: TextStyle(
                              color: AppColors.subText(context),
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 17),

                if (loading && aiAnalysis.trim().isEmpty)
                  Row(
                    children: [
                      const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF7040D8),
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Text(
                          'AI đang phân tích MBTI, sở thích và năng lực của bạn...',
                          style: TextStyle(
                            color: AppColors.subText(context),
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (aiAnalysis.trim().isEmpty)
                  Text(
                    'Chưa nhận được nội dung phân tích từ AI.',
                    style: TextStyle(
                      color: AppColors.subText(context),
                      fontSize: 14.5,
                      height: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  _AiRichAnalysis(content: aiAnalysis),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF7040D8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Top ngành phù hợp',
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (loading && careers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF7040D8)),
              ),
            )
          else if (careers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softCard(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Text(
                'Chưa có ngành nghề phù hợp để hiển thị.',
                style: TextStyle(
                  color: AppColors.subText(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...careers.asMap().entries.map(
              (entry) => _CareerCard(index: entry.key, career: entry.value),
            ),
        ],
      ),
    );
  }
}

class _CareerCard extends StatelessWidget {
  final int index;
  final _CareerItem career;
  const _CareerCard({required this.index, required this.career});
  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: 14),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.softCard(context),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border(context)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RankBadge(rank: index + 1),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                career.name,
                style: TextStyle(
                  color: AppColors.title(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(career.description, style: _bodyStyle(context)),
        SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trường gợi ý',
                style: TextStyle(
                  color: _PremiumResultScreenState.purple,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 12),
              if (career.schools.isEmpty)
                Text(
                  'Chưa có trường gợi ý.',
                  style: TextStyle(
                    color: AppColors.subText(context),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: career.schools
                      .take(4)
                      .map(
                        (school) => _SchoolLogo(school: school, career: career),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SchoolLogo extends StatelessWidget {
  final _SchoolItem school;
  final _CareerItem career;

  const _SchoolLogo({required this.school, required this.career});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSchoolDetailBottomSheet(context, school, career),
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: school.featured
                          ? const Color(0xFFFFB323)
                          : AppColors.border(context),
                      width: school.featured ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: school.featured
                            ? const Color(0xFFFFB323).withValues(alpha: .38)
                            : Colors.black.withValues(alpha: .05),
                        blurRadius: school.featured ? 24 : 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: school.imageUrl == null
                      ? Center(
                          child: Text(
                            school.name.isNotEmpty ? school.name[0] : 'T',
                            style: TextStyle(
                              color: AppColors.title(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        )
                      : Image.network(
                          school.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) {
                            return Center(
                              child: Text(
                                school.name.isNotEmpty ? school.name[0] : 'T',
                                style: TextStyle(
                                  color: AppColors.title(context),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB323), Color(0xFFFF7A1A)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF8A00,
                            ).withValues(alpha: .35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
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
            SizedBox(height: school.featured ? 20 : 10),
            Text(
              school.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.subText(context),
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  const _ResultCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(19),
    decoration: _cardDecoration(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  color: AppColors.title(context),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: AppColors.subText(context),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
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

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          _PremiumResultScreenState.purple,
          _PremiumResultScreenState.primaryBlue,
        ],
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Center(
      child: Text(
        '#$rank',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
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
          color: AppColors.softCard(context),
          textColor: AppColors.title(context),
          onTap: onRetry,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _ActionButton(
          text: 'Về trang chủ',
          color: _PremiumResultScreenState.purple,
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

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
  color: AppColors.card(context),
  borderRadius: BorderRadius.circular(26),
  border: Border.all(color: AppColors.border(context)),
  boxShadow: [
    BoxShadow(
      color: AppColors.shadow(context),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ],
);

class _RadarPainter extends CustomPainter {
  final List<_CombinedDatum> data;
  const _RadarPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = math.min(size.width, size.height) * .33;
    final count = data.length;
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Color(0xFFDDEBF5);
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color(0xFFE1ECF4);
    for (int level = 1; level <= 5; level++) {
      final scale = level / 5;
      final path = Path();
      for (int i = 0; i < count; i++) {
        final point = _point(center, radius * scale, i, count);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }
    for (int i = 0; i < count; i++) {
      canvas.drawLine(center, _point(center, radius, i, count), axisPaint);
    }
    _drawArea(
      canvas,
      center,
      radius,
      data.map((e) => (e.interest / 50).clamp(0.0, 1.0)).toList(),
      Color(0xFF77BBE9),
      Color(0xFF77BBE9).withValues(alpha: .28),
    );
    _drawArea(
      canvas,
      center,
      radius,
      data.map((e) => (e.ability / 50).clamp(0.0, 1.0)).toList(),
      Color(0xFF8D66AA),
      Color(0xFF8D66AA).withValues(alpha: .22),
    );
    for (int i = 0; i < count; i++) {
      final p = _point(center, radius * 1.23, i, count);
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: TextStyle(
            color: Color(0xFF48627B),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 80);
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }
  }

  void _drawArea(
    Canvas canvas,
    Offset center,
    double radius,
    List<double> values,
    Color stroke,
    Color fill,
  ) {
    final path = Path();
    final count = values.length;
    for (int i = 0; i < count; i++) {
      final p = _point(center, radius * values[i].clamp(0, 1), i, count);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = stroke,
    );
  }

  Offset _point(Offset center, double radius, int index, int count) {
    final angle = (-90 + (360 / count) * index) * math.pi / 180;
    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.data != data;
}

class _CombinedDatum {
  final String label;
  final int interest;
  final int ability;
  const _CombinedDatum({
    required this.label,
    required this.interest,
    required this.ability,
  });
}

class _AbilityDisplayItem {
  final String title;
  final int percent;
  final String description;
  const _AbilityDisplayItem({
    required this.title,
    required this.percent,
    required this.description,
  });
}

class _CareerItem {
  final String name;
  final String description;
  final double score;
  final List<_SchoolItem> schools;
  const _CareerItem({
    required this.name,
    required this.description,
    required this.score,
    required this.schools,
  });
}

class _SchoolItem {
  final String name;
  final String? imageUrl;
  final String description;
  final bool featured;
  const _SchoolItem({
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.featured,
  });
}
