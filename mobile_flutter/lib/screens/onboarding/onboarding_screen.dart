import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../main/main_screen.dart';
import '../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  final pages = [
    OnboardData(
      icon: Icons.psychology_alt_rounded,
      colors: [Color(0xFF58AFFF), Color(0xFF8ED8FF)],
      bgColors: [Color(0xFFEAF6FF), Color(0xFFFDFEFF)],
      title: 'Hiểu bản thân\nchọn đúng tương lai',
      desc:
          'Hành trình khám phá bản thân bắt đầu từ việc hiểu tính cách MBTI, nhận biết điểm mạnh và phong cách giao tiếp để phát triển theo cách riêng của bạn.',
      chips: ['16 tính cách', 'Gợi ý ngành nghề', 'Trường học phù hợp'],
    ),
    OnboardData(
      icon: Icons.spa_rounded,
      colors: [Color(0xFF42D6A4), Color(0xFFA6F4D0)],
      bgColors: [Color(0xFFE9FFF4), Color(0xFFFDFEFF)],
      title: 'Phát triển mỗi ngày',
      desc:
          'Hành trình phát triển bản thân không cần hoàn hảo. Mỗi ngày tiến một chút, thấu hiểu cảm xúc và trở thành phiên bản tốt hơn của chính mình.',
      chips: ['Khám phá', 'Cảm xúc', 'Hiểu bản thân'],
    ),
    OnboardData(
      icon: Icons.auto_awesome_rounded,
      colors: [Color(0xFF9B8CFF), Color(0xFFD8C8FF)],
      bgColors: [Color(0xFFF2EAFE), Color(0xFFFFFBFF)],
      title: 'Bạn rất tuyệt\ntheo cách riêng',
      desc:
          'Bạn không cần phải trở thành ai khác để thật tuyệt vời. MBTI sẽ giúp bạn hiểu rõ bản thân hơn, tự tin với cá tính riêng và tỏa sáng theo cách của chính mình.',
      chips: ['Tự tin', 'Khác biệt', 'Tỏa sáng'],
    ),
  ];

  void nextPage() {
    if (currentPage < pages.length - 1) {
      _controller.nextPage(
        duration: Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      goToMain();
    }
  }

    void goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = pages[currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(milliseconds: 450),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.bgColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(26, 18, 26, 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: goToMain,
                    child: Text(
                      'Bỏ qua',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: .42),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() => currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return OnboardPage(
                        key: ValueKey(index),
                        data: pages[index],
                      );
                    },
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOutExpo,
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      width: currentPage == index ? 30 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: currentPage == index
                            ? LinearGradient(colors: page.colors)
                            : null,
                        color: currentPage == index
                            ? null
                            : page.colors.first.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: page.colors),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border(context)),
                      boxShadow: [
                        BoxShadow(
                          color: page.colors.first.withValues(alpha: .28),
                          blurRadius: 30,
                          spreadRadius: 1,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        currentPage == pages.length - 1
                            ? 'Bắt đầu khám phá'
                            : 'Tiếp theo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardData {
  final IconData icon;
  final List<Color> colors;
  final List<Color> bgColors;
  final String title;
  final String desc;
  final List<String> chips;

  OnboardData({
    required this.icon,
    required this.colors,
    required this.bgColors,
    required this.title,
    required this.desc,
    required this.chips,
  });
}

class OnboardPage extends StatelessWidget {
  final OnboardData data;

  const OnboardPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Spacer(),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: .92, end: 1),
          duration: Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.colors.first.withValues(alpha: .30),
                  blurRadius: 38,
                  spreadRadius: 2,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Icon(
              data.icon,
              color: Colors.white,
              size: 68,
            ),
          ),
        ),

        SizedBox(height: 56),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 33,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                  color: Color(0xFF202335),
                ),
              ),

              SizedBox(height: 20),

              Text(
                data.desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.5,
                  height: 1.72,
                  fontWeight: FontWeight.w400,
                  letterSpacing: .1,
                  color: Color(0xFF6F6B80),
                ),
              ),

              SizedBox(height: 34),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: data.chips.map((chip) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card(context).withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.border(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .035),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        color: data.colors.first,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        Spacer(),
      ],
    );
  }
}