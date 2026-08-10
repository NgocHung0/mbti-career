import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_flutter/core/constants/app_colors.dart';

import '../../models/admission.dart';
import '../../models/course.dart';
import '../../models/major.dart';
import '../../services/admission_service.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/major_service.dart';
import '../../services/test_history_service.dart';
import '../admissions/admissions_screen.dart';
import '../majors/majors_screen.dart';
import '../test/test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const blue = Color(0xFF8EC5FC);
  static const purple = Color(0xFF9B7BEA);
  static const green = Color(0xFF45C58A);
  static const orange = Color(0xFFFFB86B);
  static const pink = Color(0xFFFF8FB3);
  static const teal = Color(0xFF4DD6C7);
  static const darkBlue = Color(0xFF4A89DC);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  late Future<_HomeData> _homeFuture;

  static const _mbtiTypes = [
    'INTJ',
    'INTP',
    'ENTJ',
    'ENTP',
    'INFJ',
    'INFP',
    'ENFJ',
    'ENFP',
    'ISTJ',
    'ISFJ',
    'ESTJ',
    'ESFJ',
    'ISTP',
    'ISFP',
    'ESTP',
    'ESFP',
  ];

  @override
  void initState() {
    super.initState();
    _homeFuture = _loadHomeData();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -7, end: 7).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<_HomeData> _loadHomeData() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    final user = isLoggedIn
        ? await AuthService.getUser()
        : {'name': 'Khách', 'email': ''};

    List<dynamic> histories = [];
    List<Major> majors = [];
    List<Admission> admissions = [];
    List<Course> courses = [];

    if (isLoggedIn) {
      try {
        histories = await TestHistoryService.getHistories();
      } catch (_) {}
    }

    final latest = histories.isNotEmpty ? histories.first : null;
    final hasTestHistory = latest != null;
    final latestMbti = _extractMbti(latest);

    try {
      final allMajors = await MajorService().getMajors();
      final historyMajorNames = hasTestHistory
          ? _extractMajorNamesFromHistory(latest)
          : <String>[];

      if (historyMajorNames.isNotEmpty) {
        majors = _prioritizeMajorsByNames(allMajors, historyMajorNames).where((
          major,
        ) {
          final title = major.title.toLowerCase().trim();

          return historyMajorNames.any((name) {
            final q = name.toLowerCase().trim();
            return title == q || title.contains(q) || q.contains(title);
          });
        }).toList();
      }
    } catch (_) {}

    if (hasTestHistory && majors.isEmpty) {
      majors = _fallbackMajors();
    }

    admissions = await AdmissionService.getAdmissions();

    admissions = admissions.where((e) => e.featured).toList();

    try {
      courses = await CourseService.getCourses();
    } catch (_) {}

    courses = _sortCoursesByMajor(courses, majors);

    return _HomeData(
      name: user['name'] ?? 'Khách',
      email: user['email'] ?? '',
      latestMbti: latestMbti,
      majors: majors.take(6).toList(),
      admissions: admissions.take(8).toList(),
      courses: courses.take(4).toList(),
      showRecommendedMajors: isLoggedIn && hasTestHistory && majors.isNotEmpty,
    );
  }

  static List<Course> _sortCoursesByMajor(
    List<Course> courses,
    List<Major> majors,
  ) {
    if (courses.isEmpty || majors.isEmpty) return courses;

    int score(Course course) {
      final text =
          '${course.name} ${course.courseMajor} ${course.shortDescription} ${course.description}'
              .toLowerCase();

      int point = 0;

      for (final major in majors) {
        final m = major.title.toLowerCase();

        if (text.contains(m)) {
          point += 100;
        }

        for (final word in m.split(RegExp(r'\s+'))) {
          if (word.length > 3 && text.contains(word)) {
            point += 10;
          }
        }
      }

      if (course.isFeatured) point += 2;

      return point;
    }

    final result = [...courses]..sort((a, b) => score(b).compareTo(score(a)));

    return result;
  }

  static String _extractMbti(dynamic item) {
    if (item is! Map) return 'ENFP';

    final payload = item['result_payload'];
    final payloadMbti = payload is Map ? payload['mbti_type'] : null;
    final raw = item['result_code'] ?? item['mbti_type'] ?? payloadMbti;

    if (raw == null || raw.toString().trim().isEmpty) return 'ENFP';
    return raw.toString().trim().toUpperCase();
  }

  static Future<List<dynamic>> _loadAiRecommendedMajorItems({
    required dynamic latest,
    required String mbti,
  }) async {
    final payload = _buildRecommendationPayload(latest, mbti);

    final endpoints = [
      '${AuthService.baseUrl}/recommendations/majors',
      '${AuthService.baseUrl}/major-recommendations',
      '${AuthService.baseUrl}/majors/recommendations',
      '${AuthService.baseUrl}/recommendations',
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
            .timeout(const Duration(seconds: 10));

        if (res.statusCode < 200 || res.statusCode >= 300) continue;

        final data = jsonDecode(res.body);
        final list = _extractMajorListFromAi(data);

        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    return _extractMajorListFromHistory(latest);
  }

  static Map<String, dynamic> _buildRecommendationPayload(
    dynamic latest,
    String mbti,
  ) {
    final payload = latest is Map ? latest['result_payload'] : null;
    final result = payload is Map ? payload : <String, dynamic>{};

    return {
      'level': 'premium',
      'mbti_type': mbti,
      'interest_group_scores': result['interest_group_scores'] ?? {},
      'ability_scores': result['ability_scores'] ?? {},
      'limit': 6,
    };
  }

  static List<dynamic> _extractMajorListFromAi(dynamic data) {
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

      for (final item in candidates) {
        if (item is List) return item;
      }
    }

    return [];
  }

  static List<dynamic> _extractMajorListFromHistory(dynamic latest) {
    if (latest is! Map) return [];

    final payload = latest['result_payload'];
    if (payload is! Map) return [];

    return _extractMajorListFromAi(payload);
  }

  static List<Major> _mapAiItemsToMajors({
    required List<dynamic> aiItems,
    required List<Major> dbMajors,
  }) {
    final result = <Major>[];

    for (final item in aiItems) {
      final name = _extractAiMajorName(item);
      if (name.isEmpty) continue;

      final matched = _findMajorByName(dbMajors, name);

      if (matched != null) {
        result.add(matched);
      } else {
        result.add(
          Major(
            id: 0,
            title: name,
            code: '',
            group: 'AI gợi ý',
            desc: _extractAiMajorDescription(item),
            image: '',
            careerProspects: '',
            skills: '',
            tags: const [],
            topSchools: const [],
          ),
        );
      }
    }

    return result;
  }

  static String _extractAiMajorName(dynamic item) {
    if (item is String) return item.trim();

    if (item is Map) {
      final value =
          item['name'] ??
          item['title'] ??
          item['major_name'] ??
          item['career_name'];

      return value?.toString().trim() ?? '';
    }

    return '';
  }

  static String _extractAiMajorDescription(dynamic item) {
    if (item is Map) {
      final value =
          item['description'] ?? item['short_description'] ?? item['reason'];

      return value?.toString().trim() ??
          'Ngành học được AI gợi ý dựa trên kết quả test gần nhất.';
    }

    return 'Ngành học được AI gợi ý dựa trên kết quả test gần nhất.';
  }

  static Major? _findMajorByName(List<Major> majors, String name) {
    final q = name.toLowerCase().trim();

    for (final major in majors) {
      final title = major.title.toLowerCase().trim();

      if (title == q) return major;
      if (title.contains(q) || q.contains(title)) return major;
    }

    return null;
  }

  static List<String> _extractMajorNamesFromHistory(dynamic item) {
    if (item is! Map) return [];

    final payload = item['result_payload'];
    if (payload is! Map) return [];

    final candidates = [
      payload['top_majors'],
      payload['majors'],
      payload['recommendations'],
      payload['recommended_majors'],
      payload['career_recommendations'],
    ];

    final names = <String>[];

    for (final candidate in candidates) {
      if (candidate is List) {
        for (final value in candidate) {
          if (value is String) {
            names.add(value);
          } else if (value is Map) {
            final name =
                value['name'] ??
                value['title'] ??
                value['major_name'] ??
                value['career_name'];

            if (name != null && name.toString().trim().isNotEmpty) {
              names.add(name.toString());
            }
          }
        }
      }
    }

    return names.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static List<Major> _prioritizeMajorsByNames(
    List<Major> majors,
    List<String> names,
  ) {
    int score(Major major) {
      final title = major.title.toLowerCase().trim();

      for (int i = 0; i < names.length; i++) {
        final name = names[i].toLowerCase().trim();

        if (title == name) return 1000 - i;
        if (title.contains(name) || name.contains(title)) return 800 - i;
      }

      return 0;
    }

    final sorted = [...majors]..sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  static List<Course> _sortCoursesForMbti(List<Course> list, String mbti) {
    if (list.isEmpty) return [];

    int score(Course c) {
      final text =
          '${c.name} ${c.shortDescription} ${c.description} ${c.courseMajor}'
              .toLowerCase();

      var point = 0;

      if (mbti.contains('T') &&
          (text.contains('logic') ||
              text.contains('data') ||
              text.contains('ai') ||
              text.contains('công nghệ'))) {
        point += 4;
      }

      if (mbti.contains('F') &&
          (text.contains('giao tiếp') ||
              text.contains('tâm lý') ||
              text.contains('xã hội') ||
              text.contains('giáo dục'))) {
        point += 4;
      }

      if (mbti.contains('N') &&
          (text.contains('sáng tạo') ||
              text.contains('thiết kế') ||
              text.contains('ý tưởng') ||
              text.contains('marketing'))) {
        point += 3;
      }

      if (c.isFeatured) point += 2;
      return point;
    }

    final sorted = [...list]..sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  Future<void> _refresh() async {
    setState(() => _homeFuture = _loadHomeData());
    await _homeFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _homeFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final data = snapshot.data ?? _HomeData.empty();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedIn(
                      delay: 0,
                      child: _Header(name: loading ? 'Đang tải...' : data.name),
                    ),
                    const SizedBox(height: 18),
                    _AnimatedIn(
                      delay: 80,
                      child: _HeroBanner(
                        floatAnimation: _floatAnimation,
                        onStart: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TestScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    if (data.showRecommendedMajors) ...[
                      const SizedBox(height: 24),
                      _AnimatedIn(
                        delay: 160,
                        child: _SectionHeader(
                          title: 'Ngành phù hợp',
                          subtitle:
                              'Gợi ý theo kết quả MBTI gần nhất: ${data.latestMbti}',
                          color: HomeScreen.orange,
                          actionText: 'Xem thêm',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MajorsScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedIn(
                        delay: 220,
                        child: SizedBox(
                          height: 238,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: data.majors
                                .map((item) => _MajorWebCard(major: item))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _AnimatedIn(
                      delay: 300,
                      child: _SectionHeader(
                        title: 'Tuyển sinh nổi bật',
                        subtitle:
                            'Các chương trình tuyển sinh được cập nhật trong hệ thống.',
                        color: HomeScreen.pink,
                        actionText: 'Xem thêm',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdmissionsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AnimatedIn(
                      delay: 360,
                      child: SizedBox(
                        height: 190,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: data.admissions.isEmpty
                              ? const [
                                  _AdmissionFallbackCard(
                                    color: HomeScreen.pink,
                                  ),
                                ]
                              : data.admissions
                                    .map(
                                      (item) =>
                                          _AdmissionWebCard(admission: item),
                                    )
                                    .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AnimatedIn(
                      delay: 580,
                      child: _SectionHeader(
                        title: 'Khám phá 16 nhóm MBTI',
                        subtitle:
                            'Chạm vào card để lật và xem thông tin tính cách.',
                        color: HomeScreen.purple,
                        actionText: '',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AnimatedIn(
                      delay: 640,
                      child: SizedBox(
                        height: 202,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: _mbtiTypes
                              .map((type) => _MbtiFlipCard(type: type))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeData {
  final String name;
  final String email;
  final String latestMbti;
  final List<Major> majors;
  final List<Admission> admissions;
  final List<Course> courses;
  final bool showRecommendedMajors;

  const _HomeData({
    required this.name,
    required this.email,
    required this.latestMbti,
    required this.majors,
    required this.admissions,
    required this.courses,
    required this.showRecommendedMajors,
  });

  factory _HomeData.empty() {
    return _HomeData(
      name: 'Khách',
      email: '',
      latestMbti: 'ENFP',
      majors: _fallbackMajors(),
      admissions: const [],
      courses: const [],
      showRecommendedMajors: false,
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  final int delay;
  final Widget child;

  const _AnimatedIn({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 22),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  final String name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chào mừng trở lại',
          style: TextStyle(
            color: AppColors.subText(context),
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.title(context),
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final Animation<double> floatAnimation;
  final VoidCallback onStart;

  const _HeroBanner({required this.floatAnimation, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final origin = AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final enfpUrl = '$origin/images/emoji/ENFP.png';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HomeScreen.blue.withValues(alpha: .34),
            HomeScreen.purple.withValues(alpha: .20),
            HomeScreen.pink.withValues(alpha: .12),
            AppColors.card(context),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: HomeScreen.purple.withValues(alpha: .24)),
        boxShadow: [
          BoxShadow(
            color: HomeScreen.purple.withValues(alpha: .18),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khám phá bản thân cùng NAVI',
                      style: TextStyle(
                        color: AppColors.title(context),
                        fontSize: 25,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Làm bài test để nhận phân tích tính cách và gợi ý ngành nghề phù hợp.',
                      style: TextStyle(
                        color: AppColors.subText(context),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                flex: 48,
                child: SizedBox(
                  height: 168,
                  child: Image.network(
                    enfpUrl,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) {
                      return Center(
                        child: Text(
                          'ENFP',
                          style: TextStyle(
                            color: HomeScreen.purple,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.96, end: 1.04),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            onEnd: () {
              // TweenAnimationBuilder không tự lặp khi StatelessWidget.
              // Nếu muốn pulse liên tục chuẩn hơn, dùng widget _PulseButton bên dưới.
            },
            child: _PulseStartButton(onStart: onStart),
          ),
        ],
      ),
    );
  }
}

class _PulseStartButton extends StatefulWidget {
  final VoidCallback onStart;

  const _PulseStartButton({required this.onStart});

  @override
  State<_PulseStartButton> createState() => _PulseStartButtonState();
}

class _PulseStartButtonState extends State<_PulseStartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.98,
      end: 1.035,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: HomeScreen.purple.withValues(alpha: .42),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: HomeScreen.pink.withValues(alpha: .22),
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onStart,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: HomeScreen.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, size: 26),
              SizedBox(width: 9),
              Text(
                'Bắt đầu trắc nghiệm',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final Color color;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.title(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
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
        if (actionText.isNotEmpty)
          TextButton(
            onPressed: onTap,
            child: Text(
              actionText,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }
}

class _MajorWebCard extends StatelessWidget {
  final Major major;

  const _MajorWebCard({required this.major});

  @override
  Widget build(BuildContext context) {
    final color = _colorByText(major.title);
    final image = _resolveImageUrl(major.image);

    return Container(
      width: 232,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: image == null
                ? _ColorImagePlaceholder(color: color, icon: Icons.work)
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) {
                      return _ColorImagePlaceholder(
                        color: color,
                        icon: Icons.work,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Text(
              major.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.title(context),
                fontSize: 18,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdmissionWebCard extends StatelessWidget {
  final Admission admission;

  const _AdmissionWebCard({required this.admission});

  @override
  Widget build(BuildContext context) {
    final color = _colorByText(admission.schoolName);
    final image = AdmissionService.resolveImageUrl(admission.imageUrl);

    return Container(
      width: 232,
      constraints: const BoxConstraints(minHeight: 170),
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SchoolLogoBox(
                imageUrl: image,
                name: admission.schoolName,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  admission.schoolName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontSize: 14.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            admission.majorName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          _InfoLine(
            icon: Icons.location_on_rounded,
            text: admission.city ?? 'Đang cập nhật',
            color: color,
          ),
          const SizedBox(height: 7),
          _InfoLine(
            icon: Icons.payments_rounded,
            text: admission.tuitionFee ?? 'Học phí cập nhật sau',
            color: color,
          ),
          const SizedBox(height: 7),
          _InfoLine(
            icon: Icons.schedule_rounded,
            text: admission.duration ?? 'Thời gian cập nhật sau',
            color: color,
          ),
        ],
      ),
    );
  }
}

class _AdmissionFallbackCard extends StatelessWidget {
  final Color color;

  const _AdmissionFallbackCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: _softDecoration(context, color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColorIcon(icon: Icons.apartment_rounded, color: color),
          const Spacer(),
          Text(
            'Chưa tải được tuyển sinh',
            style: TextStyle(
              color: AppColors.title(context),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kiểm tra kết nối API hoặc đăng nhập lại để tải dữ liệu.',
            style: TextStyle(
              color: AppColors.subText(context),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MbtiFlipCard extends StatefulWidget {
  final String type;

  const _MbtiFlipCard({required this.type});

  @override
  State<_MbtiFlipCard> createState() => _MbtiFlipCardState();
}

class _MbtiFlipCardState extends State<_MbtiFlipCard> {
  bool _back = false;

  @override
  Widget build(BuildContext context) {
    final color = _colorByText(widget.type);
    final name = _mbtiName(widget.type);
    final desc = _mbtiDescription(widget.type);
    final image = _mbtiImage(widget.type);

    return GestureDetector(
      onTap: () => setState(() => _back = !_back),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _back ? math.pi : 0),
        duration: const Duration(milliseconds: 430),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final showBack = value > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateY(value),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _MbtiBackCard(
                      type: widget.type,
                      name: name,
                      desc: desc,
                      color: color,
                    ),
                  )
                : _MbtiFrontCard(
                    type: widget.type,
                    name: name,
                    imageUrl: image,
                    color: color,
                  ),
          );
        },
      ),
    );
  }
}

class _MbtiFrontCard extends StatelessWidget {
  final String type;
  final String name;
  final String imageUrl;
  final Color color;

  const _MbtiFrontCard({
    required this.type,
    required this.name,
    required this.imageUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(14),
      decoration: _softDecoration(context, color),
      child: Column(
        children: [
          Expanded(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .13),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type,
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.title(context),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MbtiBackCard extends StatelessWidget {
  final String type;
  final String name;
  final String desc;
  final Color color;

  const _MbtiBackCard({
    required this.type,
    required this.name,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(14),
      decoration: _softDecoration(context, color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              desc,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.subText(context),
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Chạm để lật lại',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolLogoBox extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final Color color;

  const _SchoolLogoBox({
    required this.imageUrl,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.softCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                name.isEmpty ? 'T' : name.characters.first,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl!,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Center(
                    child: Text(
                      name.isEmpty ? 'T' : name.characters.first,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.subText(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorImagePlaceholder extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _ColorImagePlaceholder({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .24), color.withValues(alpha: .08)],
        ),
      ),
      child: Icon(icon, color: color, size: 36),
    );
  }
}

class _ColorIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ColorIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

BoxDecoration _softDecoration(BuildContext context, Color color) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [color.withValues(alpha: .12), AppColors.card(context)],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: color.withValues(alpha: .22)),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: .08),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Color _colorByText(String text) {
  final colors = [
    HomeScreen.blue,
    HomeScreen.purple,
    HomeScreen.green,
    HomeScreen.orange,
    HomeScreen.pink,
    HomeScreen.teal,
  ];

  if (text.trim().isEmpty) return colors.first;
  return colors[text.hashCode.abs() % colors.length];
}

String? _resolveImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.trim().isEmpty) return null;

  final raw = imageUrl.trim();

  if (raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.startsWith('data:')) {
    return raw;
  }

  final origin = AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  if (raw.startsWith('/')) return '$origin$raw';

  if (raw.startsWith('images/') ||
      raw.startsWith('assets/') ||
      raw.startsWith('storage/')) {
    return '$origin/$raw';
  }

  return '$origin/storage/$raw';
}

String _mbtiImage(String type) {
  final origin = AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  return '$origin/images/emoji2/$type.png';
}

String _mbtiName(String type) {
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

String _mbtiDescription(String type) {
  const desc = {
    'INTJ': 'Tư duy chiến lược, độc lập, thích lập kế hoạch dài hạn.',
    'INTP': 'Tò mò, phân tích tốt, thích tìm hiểu bản chất vấn đề.',
    'ENTJ': 'Quyết đoán, định hướng mục tiêu và có tố chất lãnh đạo.',
    'ENTP': 'Nhanh ý, sáng tạo, thích tranh luận và khám phá ý tưởng mới.',
    'INFJ': 'Sâu sắc, có trực giác tốt và quan tâm đến ý nghĩa lâu dài.',
    'INFP': 'Giàu cảm xúc, sáng tạo và sống theo giá trị cá nhân.',
    'ENFJ': 'Truyền cảm hứng, giao tiếp tốt và quan tâm đến người khác.',
    'ENFP': 'Nhiệt tình, giàu ý tưởng và thích kết nối với mọi người.',
    'ISTJ': 'Thực tế, trách nhiệm và thích sự rõ ràng, ổn định.',
    'ISFJ': 'Chu đáo, tận tâm và âm thầm hỗ trợ người xung quanh.',
    'ESTJ': 'Có tổ chức, rõ ràng và thích điều hành theo mục tiêu.',
    'ESFJ': 'Thân thiện, quan tâm tập thể và tạo cảm giác gần gũi.',
    'ISTP': 'Thực tế, linh hoạt và giỏi xử lý tình huống bằng hành động.',
    'ISFP': 'Tinh tế, yêu tự do và thể hiện bản thân qua hành động.',
    'ESTP': 'Năng động, nhanh nhạy và tự tin trong môi trường mới.',
    'ESFP': 'Vui vẻ, giàu năng lượng và tạo không khí tích cực.',
  };

  return desc[type] ?? 'Một nhóm tính cách có phong cách riêng biệt.';
}

List<Major> _fallbackMajors() {
  return [
    Major(
      id: 0,
      title: 'Công nghệ thông tin',
      code: 'CNTT',
      group: 'Công nghệ',
      desc: 'Tư duy logic, phân tích và giải quyết vấn đề.',
      image: '',
      careerProspects: '',
      skills: '',
      tags: const ['IT', 'AI', 'Data'],
      topSchools: const [],
    ),
    Major(
      id: 0,
      title: 'Truyền thông đa phương tiện',
      code: 'TTDPT',
      group: 'Sáng tạo',
      desc: 'Phù hợp người thích sáng tạo, nội dung và hình ảnh.',
      image: '',
      careerProspects: '',
      skills: '',
      tags: const ['Marketing', 'Media'],
      topSchools: const [],
    ),
    Major(
      id: 0,
      title: 'Quản trị kinh doanh',
      code: 'QTKD',
      group: 'Kinh doanh',
      desc: 'Phù hợp người thích tổ chức, lãnh đạo và chiến lược.',
      image: '',
      careerProspects: '',
      skills: '',
      tags: const ['Business'],
      topSchools: const [],
    ),
  ];
}
