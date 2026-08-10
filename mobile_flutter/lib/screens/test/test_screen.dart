import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/package_service.dart';
import 'mbti_question_screen.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import '../../core/widgets/top_header.dart';

class TestScreen extends StatefulWidget {
  final int refreshKey;

  const TestScreen({super.key, this.refreshKey = 0});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late Future<dynamic> _packageFuture;

  static const primaryBlue = Color(0xFF7DBEFF);
  static const purple = Color(0xFF9B7BEA);
  static const green = Color(0xFF45C58A);

  @override
  void initState() {
    super.initState();
    _packageFuture = _loadPackage();
  }

  @override
  void didUpdateWidget(covariant TestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey != widget.refreshKey) {
      setState(() {
        _packageFuture = _loadPackage();
      });
    }
  }

  Future<dynamic> _loadPackage() async {
    final logged = await AuthService.isLoggedIn();
    if (!logged) return null;

    try {
      return await PackageService.getCurrentPackage();
    } catch (_) {
      return null;
    }
  }

  String _modeFromPackage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return PackageService.getMode(data);
    }

    if (data is Map) {
      return PackageService.getMode(Map<String, dynamic>.from(data));
    }

    return 'free';
  }

  String _packageLabel(String mode) {
    if (mode == 'premium') return 'Premium';
    if (mode == 'plus') return 'Plus';
    return 'Free';
  }

  int _questionCount(String mode) {
    if (mode == 'premium') return 86;
    if (mode == 'plus') return 56;
    return 36;
  }

  Color _modeColor(String mode) {
    if (mode == 'premium') return purple;
    if (mode == 'plus') return green;
    return primaryBlue;
  }

  String _modeTitle(String mode) {
    if (mode == 'premium') return 'Bài test Premium';
    if (mode == 'plus') return 'Bài test Plus';
    return 'Bài test MBTI cơ bản';
  }

  String _modeDescription(String mode) {
    if (mode == 'premium') {
      return 'Kết hợp MBTI, sở thích và năng lực để đưa ra kết quả định hướng chuyên sâu hơn.';
    }

    if (mode == 'plus') {
      return 'Kết hợp MBTI và sở thích cá nhân để phân tích tính cách rõ hơn.';
    }

    return 'Khám phá nhóm tính cách MBTI và điểm mạnh cơ bản của bạn.';
  }

  List<String> _benefits(String mode) {
    if (mode == 'premium') {
      return [
        'Làm đầy đủ bài test MBTI, sở thích và năng lực.',
        'Xem biểu đồ kết hợp sở thích và năng lực.',
        'Nhận top năng lực nổi trội.',
        'AI gợi ý ngành học và trường phù hợp.',
        'Lưu lịch sử kết quả để xem lại sau.',
      ];
    }

    if (mode == 'plus') {
      return [
        'Làm bài test MBTI và sở thích.',
        'Xem phân tích tính cách chi tiết hơn.',
        'Xem tỉ lệ các nhóm tính cách.',
        'Lưu lịch sử kết quả để theo dõi.',
      ];
    }

    return [
      'Làm bài test MBTI cơ bản.',
      'Biết nhóm tính cách của bản thân.',
      'Xem mô tả và điểm mạnh nổi bật.',
      'Có thể nâng cấp để xem phân tích sâu hơn.',
    ];
  }

  Future<void> _startTest() async {
    final package = await _loadPackage();
    final mode = _modeFromPackage(package);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MbtiQuestionScreen(testMode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.bg(context);
    final card = AppColors.card(context);
    final softCard = AppColors.softCard(context);
    final title = AppColors.title(context);
    final sub = AppColors.subText(context);
    final border = AppColors.border(context);

    return FutureBuilder<dynamic>(
      future: _packageFuture,
      builder: (context, snapshot) {
        final mode = _modeFromPackage(snapshot.data);
        final modeColor = _modeColor(mode);
        final questionCount = _questionCount(mode);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.of(context).padding.bottom + 108,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopHeader(
                    title: 'Kiểm tra định hướng',
                    subtitle:
                        'Trước khi làm bài, hãy đọc nhanh hướng dẫn để chọn đáp án chính xác hơn.',
                    image:
                        '${AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '')}/images/emoji2/Test.png',
                  ),
                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [softCard, card],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: modeColor.withValues(alpha: .15),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: modeColor.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: modeColor.withValues(alpha: .22),
                            ),
                          ),
                          child: Text(
                            '${_packageLabel(mode).toUpperCase()} · $questionCount CÂU',
                            style: TextStyle(
                              color: modeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _modeTitle(mode),
                          style: TextStyle(
                            color: title,
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _modeDescription(mode),
                          style: TextStyle(
                            color: sub,
                            fontSize: 15,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoMiniCard(
                                title: '$questionCount',
                                subtitle: 'Câu hỏi',
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: _InfoMiniCard(
                                title: '5–10',
                                subtitle: 'Phút làm bài',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? null
                                : () => _startTest(),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: modeColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.border(
                                context,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Đang kiểm tra gói...'
                                  : 'Bắt đầu làm bài',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Hướng dẫn trước khi làm',
                    style: TextStyle(
                      color: title,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...[
                    'Chọn đáp án đúng với bản thân nhất, không cần suy nghĩ quá lâu.',
                    'Không có đáp án đúng hoặc sai, mỗi lựa chọn đều phản ánh một xu hướng cá nhân.',
                    'Nên làm bài trong trạng thái thoải mái để kết quả chính xác hơn.',
                  ].map((text) => _GuideTile(text: text)),

                  const SizedBox(height: 22),
                  Text(
                    'Bạn sẽ nhận được',
                    style: TextStyle(
                      color: title,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._benefits(
                    mode,
                  ).map((text) => _BenefitTile(text: text, color: modeColor)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool loading;

  const _ModeBadge({
    required this.label,
    required this.color,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Text(
        loading ? 'Đang tải' : label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoMiniCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoMiniCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.bg(context).withValues(alpha: .55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.title(context),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.subText(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  final String text;

  const _GuideTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.subText(context),
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final String text;
  final Color color;

  const _BenefitTile({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.title(context),
          height: 1.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
