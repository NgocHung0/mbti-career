import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/mbti_question.dart';
import '../../services/mbti_service.dart';
import '../packages/payment_qr_screen.dart';
import 'ad_video_screen.dart';
import 'mbti_result_screen.dart';
import 'plus_result_screen.dart';
import 'premium_result_screen.dart';

class MbtiQuestionScreen extends StatefulWidget {
  final String testMode;

  const MbtiQuestionScreen({
    super.key,
    this.testMode = 'free',
  });

  @override
  State<MbtiQuestionScreen> createState() => _MbtiQuestionScreenState();
}

class _MbtiQuestionScreenState extends State<MbtiQuestionScreen> {
  int currentQuestion = 0;
  late Future<List<MbtiQuestion>> futureQuestions;

  final List<Map<String, dynamic>> answers = [];

  static const primaryBlue = Color(0xFF4C8DFF);
  static const purple = Color(0xFF8357E8);
  static const green = Color(0xFF2DBB7F);
  static const darkCard = Color(0xFF111111);
  static const textLight = Color(0xFFEAF6FF);
  static const textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    futureQuestions = loadQuestionsByMode();
  }

  Future<List<MbtiQuestion>> loadQuestionsByMode() {
    return MbtiService().getQuestions(level: widget.testMode);
  }

  String modeLabel() {
    switch (widget.testMode.toLowerCase()) {
      case 'premium':
        return 'Premium';
      case 'plus':
        return 'Plus';
      default:
        return 'Free';
    }
  }

  Color modeColor() {
    switch (widget.testMode.toLowerCase()) {
      case 'premium':
        return purple;
      case 'plus':
        return green;
      default:
        return primaryBlue;
    }
  }

  void selectAnswer({
    required MbtiQuestion question,
    required String choice,
  }) {
    answers.removeWhere(
      (item) => item['question_id'] == question.id,
    );

    answers.add({
      'question_id': question.id,
      'order': question.order,
      'question': question.question,
      'option_a': question.optionA,
      'option_b': question.optionB,
      'selected_answer': choice == question.dirA ? 'A' : 'B',
      'choice': choice,
      'axis': question.axis,
      'axis_label': question.axisLabel,
      'dir_a': question.dirA,
      'dir_b': question.dirB,
      'package_type': question.packageType,
      'section': question.packageType,
    });

    setState(() {});
  }

  String? selectedChoiceFor(MbtiQuestion question) {
    final result = answers.where(
      (item) => item['question_id'] == question.id,
    );

    if (result.isEmpty) return null;
    return result.first['choice'] as String?;
  }

  void previousQuestion() {
    if (currentQuestion <= 0) return;

    setState(() {
      currentQuestion--;
    });
  }

  Future<void> nextQuestion(
    List<MbtiQuestion> questions,
  ) async {
    final current = questions[currentQuestion];
    final hasAnswered = answers.any(
      (item) => item['question_id'] == current.id,
    );

    if (!hasAnswered) {
      await _showMissingAnswerDialog();
      return;
    }

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
      return;
    }

    final confirm = await _showSubmitSheet(
      questions.length,
    );

    if (confirm != true || !mounted) return;

    if (widget.testMode == 'free') {
      showPackageChoiceSheet();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (widget.testMode == 'premium') {
            return PremiumResultScreen(
              answers: answers,
            );
          }

          if (widget.testMode == 'plus') {
            return PlusResultScreen(
              answers: answers,
            );
          }

          return MbtiResultScreen(
            answers: answers,
          );
        },
      ),
    );
  }

  Future<void> _showMissingAnswerDialog() {
    final accent = modeColor();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.card(dialogContext),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.border(dialogContext),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .16),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bạn chưa chọn đáp án',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.title(dialogContext),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Hãy chọn một trong hai đáp án trước khi tiếp tục.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.subText(dialogContext),
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Đã hiểu',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
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

  Future<bool?> _showSubmitSheet(int total) {
    final accent = modeColor();

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          decoration: const BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bạn đã hoàn thành bài test',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textLight,
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bạn đã trả lời đủ $total/$total câu hỏi. Hãy nộp bài để xem kết quả phân tích.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textLight,
                          side: const BorderSide(
                            color: Colors.white24,
                          ),
                          minimumSize: const Size(
                            double.infinity,
                            52,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Kiểm tra lại',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(
                            double.infinity,
                            52,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Nộp bài',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showPackageChoiceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String selected = 'premium';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EEFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'GÓI NÂNG CAO',
                            style: TextStyle(
                              color: purple,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn gói test nâng cao',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.title(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chọn một gói để hệ thống phân tích sâu hơn trước khi xem kết quả.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.subText(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: packageMiniCard(
                            context: context,
                            selected: selected == 'premium',
                            title: 'Premium',
                            price: '39.000đ',
                            color: purple,
                            desc:
                                'Full test tính cách, sở thích, năng lực, không quảng cáo.',
                            badge: 'Full quyền lợi',
                            onTap: () {
                              setModalState(() {
                                selected = 'premium';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: packageMiniCard(
                            context: context,
                            selected: selected == 'plus',
                            title: 'Plus',
                            price: '19.000đ',
                            color: green,
                            desc:
                                'Test tính cách và sở thích, không cần xem quảng cáo.',
                            badge: 'Cơ bản',
                            onTap: () {
                              setModalState(() {
                                selected = 'plus';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdVideoScreen(
                                    answers: answers,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Bỏ qua, xem quảng cáo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);

                              final isPremium = selected == 'premium';

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentQrScreen(
                                    packageId: isPremium ? 2 : 1,
                                    packageName:
                                        isPremium ? 'Premium' : 'Plus',
                                    amount: isPremium ? 39000 : 19000,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  selected == 'premium' ? purple : green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Tiếp tục',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget packageMiniCard({
    required BuildContext context,
    required bool selected,
    required String title,
    required String price,
    required String desc,
    required String badge,
    required Color color,
    required VoidCallback onTap,
  }) {
    final card = AppColors.card(context);
    final soft = AppColors.softCard(context);
    final titleColor = AppColors.title(context);
    final sub = AppColors.subText(context);
    final border = AppColors.border(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? soft : card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? color.withValues(alpha: .18)
                  : AppColors.shadow(context),
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? color : Colors.transparent,
                    border: Border.all(
                      color: selected ? color : border,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              desc,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: sub,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.bg(context);
    final accent = modeColor();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FutureBuilder<List<MbtiQuestion>>(
          future: futureQuestions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: accent,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không thể tải câu hỏi.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.title(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }

            final questions = snapshot.data ?? [];

            if (questions.isEmpty) {
              return Center(
                child: Text(
                  'Chưa có câu hỏi nào',
                  style: TextStyle(
                    color: AppColors.title(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }

            final question = questions[currentQuestion];
            final progress = (currentQuestion + 1) / questions.length;
            final selected = selectedChoiceFor(question);
            final percent = (progress * 100).round();

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(
                children: [
                  _TopHeader(
                    mode: modeLabel(),
                    current: currentQuestion + 1,
                    total: questions.length,
                    accentColor: accent,
                  ),
                  const SizedBox(height: 14),
                  _ProgressHeader(
                    current: currentQuestion + 1,
                    total: questions.length,
                    progress: progress,
                    percent: percent,
                    accentColor: accent,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: _QuestionStage(
                                key: ValueKey(currentQuestion),
                                question: question,
                                questionNumber: currentQuestion + 1,
                                selectedChoice: selected,
                                accentColor: accent,
                                onSelectA: () {
                                  selectAnswer(
                                    question: question,
                                    choice: question.dirA,
                                  );
                                },
                                onSelectB: () {
                                  selectAnswer(
                                    question: question,
                                    choice: question.dirB,
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BottomActions(
                    canBack: currentQuestion > 0,
                    isLast: currentQuestion == questions.length - 1,
                    accentColor: accent,
                    onBack: previousQuestion,
                    onNext: () => nextQuestion(questions),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String mode;
  final int current;
  final int total;
  final Color accentColor;

  const _TopHeader({
    required this.mode,
    required this.current,
    required this.total,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final title = AppColors.title(context);
    final border = AppColors.border(context);
    final card = AppColors.card(context);

    return Row(
      children: [
        Material(
          color: card,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: title,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trắc nghiệm MBTI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: title,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$current / $total câu',
                style: TextStyle(
                  color: AppColors.subText(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: accentColor.withValues(alpha: .25),
            ),
          ),
          child: Text(
            mode,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final double progress;
  final int percent;
  final Color accentColor;

  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.progress,
    required this.percent,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Tiến độ hoàn thành',
                style: TextStyle(
                  color: AppColors.subText(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$current / $total',
                style: TextStyle(
                  color: AppColors.title(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 9,
                        backgroundColor: AppColors.border(context),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          accentColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 44,
                child: Text(
                  '$percent%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionStage extends StatelessWidget {
  final MbtiQuestion question;
  final int questionNumber;
  final String? selectedChoice;
  final Color accentColor;
  final VoidCallback onSelectA;
  final VoidCallback onSelectB;

  const _QuestionStage({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.selectedChoice,
    required this.accentColor,
    required this.onSelectA,
    required this.onSelectB,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuestionCard(
          question: question.question,
          index: questionNumber,
          accentColor: accentColor,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _AnswerCard(
                label: 'A',
                text: question.optionA,
                isSelected: selectedChoice == question.dirA,
                accentColor: accentColor,
                onTap: onSelectA,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnswerCard(
                label: 'B',
                text: question.optionB,
                isSelected: selectedChoice == question.dirB,
                accentColor: accentColor,
                onTap: onSelectB,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String question;
  final int index;
  final Color accentColor;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.card(context);
    final soft = AppColors.softCard(context);
    final title = AppColors.title(context);

    return Container(
      width: double.infinity,
      height: 218,
      padding: const EdgeInsets.fromLTRB(22, 21, 22, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            soft,
            card,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: accentColor.withValues(alpha: .15),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: .09),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'CÂU ${index.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: Text(
                question,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: title,
                  fontSize: 22,
                  height: 1.28,
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

class _AnswerCard extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _AnswerCard({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.card(context);
    final soft = AppColors.softCard(context);
    final title = AppColors.title(context);
    final sub = AppColors.subText(context);
    final border = AppColors.border(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(27),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 210),
          curve: Curves.easeOutCubic,
          height: 188,
          padding: const EdgeInsets.fromLTRB(14, 15, 14, 16),
          decoration: BoxDecoration(
            color: isSelected ? soft : card,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: isSelected ? accentColor : border,
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accentColor.withValues(alpha: .16)
                    : AppColors.shadow(context),
                blurRadius: isSelected ? 24 : 13,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 210),
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : accentColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : accentColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 21,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Center(
                  child: Text(
                    text,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? title : sub,
                      fontSize: 15.5,
                      height: 1.28,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              AnimatedContainer(
                duration: const Duration(milliseconds: 210),
                width: isSelected ? 30 : 20,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : border.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final bool canBack;
  final bool isLast;
  final Color accentColor;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomActions({
    required this.canBack,
    required this.isLast,
    required this.accentColor,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.border(context);
    final title = AppColors.title(context);
    final sub = AppColors.subText(context);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 55,
            child: OutlinedButton(
              onPressed: canBack ? onBack : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: title,
                disabledForegroundColor: sub.withValues(alpha: .45),
                side: BorderSide(
                  color: canBack
                      ? border
                      : border.withValues(alpha: .45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Quay lại',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                isLast ? 'Hoàn thành' : 'Tiếp theo',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
