import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final pages = [
    IntroPageData(
      icon: Icons.psychology_rounded,
      title: "Khám phá con người\nthật của bạn",
      description:
          "Làm bài đánh giá 80 câu hỏi được thiết kế khoa học để khám phá loại tính cách MBTI độc đáo của bạn. Mỗi câu hỏi được xây dựng cẩn thận để bộc lộ con người thật của bạn.",
      highlight: "16 loại tính cách độc đáo đang chờ bạn",
      features: [
        IntroFeature(Icons.quiz_rounded, "80 câu hỏi được thiết kế cẩn thận"),
        IntroFeature(Icons.trending_up_rounded,
            "Phân tích chi tiết điểm mạnh và đặc điểm của bạn"),
        IntroFeature(Icons.auto_awesome_rounded,
            "Phân tích tính cách đầy đủ với tỷ lệ phần trăm"),
      ],
    ),
    IntroPageData(
      icon: Icons.show_chart_rounded,
      title: "Phát triển mỗi ngày",
      description:
          "Tính cách của bạn thay đổi theo thời gian. Làm lại bài test định kỳ, theo dõi sự phát triển và nhận được những hiểu biết sâu sắc hơn mỗi lần truy cập.",
      highlight: "",
      features: [
        IntroFeature(Icons.play_arrow_rounded,
            "Theo dõi thay đổi tính cách theo thời gian"),
        IntroFeature(Icons.manage_search_rounded, "Thử thách thám tử hằng ngày"),
        IntroFeature(Icons.auto_awesome_rounded, "Hiểu biết mới mỗi lần truy cập"),
      ],
    ),
    IntroPageData(
      icon: Icons.school_rounded,
      title: "Định hướng ngành nghề\nphù hợp",
      description:
          "Dựa trên kết quả MBTI, hệ thống gợi ý ngành học, nghề nghiệp và lộ trình phát triển phù hợp với tính cách cá nhân của bạn.",
      highlight: "Tìm ngành học phù hợp với chính bạn",
      features: [
        IntroFeature(Icons.work_rounded, "Gợi ý ngành nghề theo tính cách"),
        IntroFeature(Icons.account_balance_rounded, "Khám phá trường học phù hợp"),
        IntroFeature(Icons.history_rounded, "Lưu và xem lại lịch sử bài test"),
      ],
    ),
  ];

  void _goHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _next() {
    if (_currentPage < pages.length - 1) {
      _controller.nextPage(
        duration: Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goHome();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF2E4),
      body: SafeArea(
        child: Stack(
          children: [
            const _SoftDotsBackground(),
            Padding(
              padding: EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentPage == 0 ? null : _back,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _currentPage == 0
                              ? Colors.transparent
                              : Color(0xFF374151),
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: _goHome,
                        child: Text(
                          "Bỏ Qua",
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF8A817C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        return _IntroPage(data: pages[index]);
                      },
                    ),
                  ),
                  Row(
                    children: [
                      _PageDots(
                        count: pages.length,
                        activeIndex: _currentPage,
                      ),
                      Spacer(),
                      SizedBox(
                        width: 178,
                        height: 62,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF7C3AED),
                                Color(0xFFA78BFA),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF7C3AED).withValues(alpha: .28),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: Text(
                              _currentPage == pages.length - 1
                                  ? "Bắt Đầu"
                                  : "Tiếp Theo  →",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final IntroPageData data;

  const _IntroPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 30),
          _HeroIcon(icon: data.icon),
          SizedBox(height: 42),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF202020),
            ),
          ),
          SizedBox(height: 24),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              height: 1.55,
              color: Color(0xFF7A706B),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 34),
          if (data.highlight.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                data.highlight,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
          _FeatureCard(features: data.features),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;

  const _HeroIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFFF472B6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7C3AED).withValues(alpha: .25),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 70,
        color: Colors.white,
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final List<IntroFeature> features;

  const _FeatureCard({required this.features});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.card(context).withValues(alpha: .82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.card(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: features
            .map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Color(0xFFF0E7FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item.icon,
                        color: Color(0xFF7C3AED),
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 19,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList()
          ..last = Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Color(0xFFF0E7FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    features.last.icon,
                    color: Color(0xFF7C3AED),
                    size: 28,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    features.last.title,
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _PageDots({
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 250),
          margin: EdgeInsets.only(right: 8),
          width: index == activeIndex ? 38 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? Color(0xFF7C3AED)
                : Color(0xFFE5D4F7),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _SoftDotsBackground extends StatelessWidget {
  const _SoftDotsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 80,
          left: 18,
          child: _dot(16),
        ),
        Positioned(
          top: 180,
          right: 42,
          child: _dot(8),
        ),
        Positioned(
          top: 310,
          right: 80,
          child: _dot(20),
        ),
        Positioned(
          bottom: 120,
          left: 54,
          child: _dot(10),
        ),
      ],
    );
  }

  Widget _dot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(0xFFD8B4FE).withValues(alpha: .35),
        shape: BoxShape.circle,
      ),
    );
  }
}

class IntroPageData {
  final IconData icon;
  final String title;
  final String description;
  final String highlight;
  final List<IntroFeature> features;

  IntroPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.highlight,
    required this.features,
  });
}

class IntroFeature {
  final IconData icon;
  final String title;

  IntroFeature(this.icon, this.title);
}