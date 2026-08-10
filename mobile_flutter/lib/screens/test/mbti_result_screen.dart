import 'package:flutter/material.dart';
import '../../services/test_history_service.dart';
import '../../core/constants/app_colors.dart';

class MbtiResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> answers;
  final bool fromHistory;

  MbtiResultScreen({
    super.key,
    required this.answers,
    this.fromHistory = false,
  });

  @override
  State<MbtiResultScreen> createState() => _MbtiResultScreenState();
}

class _MbtiResultScreenState extends State<MbtiResultScreen> {
  bool _saved = false;

  static const primaryBlue = Color(0xFF8EC5FC);
  static const purple = Color(0xFF9B7BEA);
  static const textDark = Color(0xFF29425E);
  static const textGrey = Color(0xFF617587);
  static const borderColor = Color(0xFFE4EEF8);

  @override
  void initState() {
    super.initState();

    if (!widget.fromHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _saveHistory());
    }
  }

  Map<String, int> getScores() {
    final scores = {
      'E': 0,
      'I': 0,
      'S': 0,
      'N': 0,
      'T': 0,
      'F': 0,
      'J': 0,
      'P': 0,
    };
    for (final answer in widget.answers) {
      final choice = answer['choice']?.toString().toUpperCase().trim();
      if (choice != null && scores.containsKey(choice)) {
        scores[choice] = (scores[choice] ?? 0) + 1;
      }
    }
    return scores;
  }

  String getMbtiType() {
    final s = getScores();
    return '${s['E']! >= s['I']! ? 'E' : 'I'}'
        '${s['S']! >= s['N']! ? 'S' : 'N'}'
        '${s['T']! >= s['F']! ? 'T' : 'F'}'
        '${s['J']! >= s['P']! ? 'J' : 'P'}';
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
    const desc = {
      'INTJ':
          'Bạn có tư duy chiến lược, thích lập kế hoạch và thường nhìn vấn đề theo hướng dài hạn.',
      'INTP':
          'Bạn tò mò, thích phân tích và thường muốn hiểu bản chất sâu xa của vấn đề.',
      'ENTJ':
          'Bạn quyết đoán, có xu hướng lãnh đạo và thích hướng mọi việc về mục tiêu rõ ràng.',
      'ENTP':
          'Bạn linh hoạt, nhanh ý và thường thích khám phá những ý tưởng mới.',
      'INFJ':
          'Bạn sâu sắc, có trực giác tốt và thường quan tâm đến ý nghĩa phía sau mỗi lựa chọn.',
      'INFP': 'Bạn giàu cảm xúc, sáng tạo và thường sống theo giá trị cá nhân.',
      'ENFJ':
          'Bạn giao tiếp tốt, biết truyền cảm hứng và thường quan tâm đến sự phát triển của người xung quanh.',
      'ENFP':
          'Bạn nhiệt tình, sáng tạo và có khả năng kết nối tốt với mọi người.',
      'ISTJ':
          'Bạn thực tế, trách nhiệm và thường thích sự rõ ràng, ổn định trong cách làm việc.',
      'ISFJ': 'Bạn chu đáo, tận tâm và thường âm thầm hỗ trợ người khác.',
      'ESTJ':
          'Bạn rõ ràng, có tổ chức và thường thích điều hành công việc theo mục tiêu cụ thể.',
      'ESFJ':
          'Bạn thân thiện, quan tâm đến tập thể và thường tạo cảm giác gần gũi cho người khác.',
      'ISTP':
          'Bạn thực tế, linh hoạt và thường giỏi xử lý tình huống bằng hành động.',
      'ISFP':
          'Bạn tinh tế, yêu tự do và thường thể hiện bản thân qua hành động hơn lời nói.',
      'ESTP':
          'Bạn năng động, nhanh nhạy và thường tự tin trong môi trường mới.',
      'ESFP':
          'Bạn vui vẻ, giàu năng lượng và thường tạo không khí tích cực xung quanh.',
    };
    return desc[type] ??
        'Kết quả này giúp bạn nhìn lại điểm mạnh, phong cách học tập và hướng phát triển phù hợp hơn.';
  }

  Future<void> _saveHistory() async {
    if (_saved) return;
    _saved = true;
    final mbti = getMbtiType();
    try {
      await TestHistoryService.storeHistory(
        packageName: 'free',
        mbtiType: mbti,
        testName: 'Bài test MBTI Free',
        resultData: {
          'mbti_type': mbti,
          'name': getName(mbti),
          'description': getDescription(mbti),
          'answers': widget.answers,
          'scores': getScores(),
        },
      );
    } catch (_) {}
  }

  List<String> _strengthsFor(String type) {
    if (type.startsWith('E')) {
      return [
        'Giao tiếp tốt và dễ kết nối với môi trường xung quanh.',
        'Có xu hướng chủ động khi làm việc cùng người khác.',
        'Phù hợp với các hoạt động cần tương tác và phối hợp.',
      ];
    }
    return [
      'Có khả năng quan sát và suy nghĩ độc lập.',
      'Tập trung tốt khi làm việc trong môi trường phù hợp.',
      'Có xu hướng phân tích kỹ trước khi đưa ra lựa chọn.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final mbti = getMbtiType();
    final name = getName(mbti);
    final desc = getDescription(mbti);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.title(context)),
        title: Text(
          'Kết quả Free',
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
            _HeroCard(
              kicker: 'KẾT QUẢ MBTI CƠ BẢN',
              badge: 'Free',
              title: '$name ($mbti)',
              description: desc,
              mbti: mbti,
            ),
            SizedBox(height: 16),
            _ResultCard(
              title: 'Phân tích tính cách',
              child: Text(desc, style: bodyStyle(context)),
            ),
            SizedBox(height: 16),
            _ResultCard(
              title: 'Điểm mạnh nổi bật',
              child: Column(
                children: _strengthsFor(mbti).map((e) => _ItemBox(e)).toList(),
              ),
            ),
            SizedBox(height: 16),
            _ResultCard(
              title: 'Mở rộng kết quả',
              background: AppColors.softCard(context),
              borderColor: AppColors.border(context),
              child: Text(
                'Bạn đang dùng gói Free nên hiện chỉ xem được thông tin cơ bản. Hãy nâng cấp Plus hoặc Premium để mở khóa biểu đồ sở thích, năng lực, AI phân tích và gợi ý ngành học phù hợp.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.subText(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
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

TextStyle bodyStyle(BuildContext context) {
  return TextStyle(
    fontSize: 14.5,
    height: 1.6,
    color: AppColors.subText(context),
    fontWeight: FontWeight.w600,
  );
}

class _HeroCard extends StatelessWidget {
  final String kicker;
  final String badge;
  final String title;
  final String description;
  final String mbti;
  const _HeroCard({
    required this.kicker,
    required this.badge,
    required this.title,
    required this.description,
    required this.mbti,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22),
      decoration: _cardDecoration(context),
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
                    color: _MbtiResultScreenState.purple,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
              _Pill(label: badge, color: _MbtiResultScreenState.purple),
            ],
          ),
          SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w900,
              color: AppColors.title(context),
            ),
          ),
          SizedBox(height: 14),
          Text(description, style: bodyStyle(context)),
          SizedBox(height: 22),
          Center(child: _MbtiBox(mbti: mbti)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? background;
  final Color? borderColor;
  const _ResultCard({
    required this.title,
    required this.child,
    this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(19),
      decoration: _cardDecoration(
        context,
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
              color: AppColors.title(context),
            ),
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ItemBox extends StatelessWidget {
  final String text;
  const _ItemBox(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.45,
          color: AppColors.subText(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MbtiBox extends StatelessWidget {
  final String mbti;
  const _MbtiBox({required this.mbti});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _MbtiResultScreenState.purple,
            _MbtiResultScreenState.primaryBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _MbtiResultScreenState.primaryBlue.withValues(alpha: .22),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Text(
          mbti,
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BottomButtons extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onHome;
  const _BottomButtons({required this.onRetry, required this.onHome});
  @override
  Widget build(BuildContext context) {
    return Row(
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
            color: _MbtiResultScreenState.purple,
            textColor: Colors.white,
            onTap: onHome,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _ActionButton({
    required this.text,
    required this.color,
    required this.textColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

BoxDecoration _cardDecoration(
  BuildContext context, {
  Color? background,
  Color? borderColor,
}) {
  return BoxDecoration(
    color: background ?? AppColors.card(context),
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: borderColor ?? AppColors.border(context)),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow(context),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
