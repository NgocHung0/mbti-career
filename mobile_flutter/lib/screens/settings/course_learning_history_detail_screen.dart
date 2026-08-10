import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/course_learning_history.dart';

class CourseLearningHistoryDetailScreen extends StatelessWidget {
  final CourseLearningHistory item;

  const CourseLearningHistoryDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Color(0xFF000000) : AppColors.lightBlue;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(isDark: isDark),
              SizedBox(height: 16),
              _SummaryCard(item: item, isDark: isDark),
              SizedBox(height: 16),
              Text(
                'Chi tiết câu trả lời',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 12),
              ...item.questions.asMap().entries.map(
                (entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: _AnswerCard(
                      index: entry.key + 1,
                      question: entry.value,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isDark;

  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: isDark ? Color(0xFF111111) : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Chi tiết bài làm',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CourseLearningHistory item;
  final bool isDark;

  const _SummaryCard({
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? Color(0xFF111111) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textDark;
    final subColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.assignment_turned_in_rounded,
              color: AppColors.primaryBlue,
              size: 40,
            ),
          ),
          SizedBox(height: 14),
          Text(
            item.courseName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            item.lessonTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 24,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfo(
                icon: Icons.quiz_rounded,
                text: item.scoreLabel,
                isDark: isDark,
              ),
              _MiniInfo(
                icon: Icons.access_time_rounded,
                text: item.updatedAtLabel,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final int index;
  final CourseLearningQuestionHistory question;
  final bool isDark;

  const _AnswerCard({
    required this.index,
    required this.question,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? Color(0xFF111111) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textDark;

    final statusColor =
        question.isCorrect ? Color(0xFF16A34A) : Color(0xFFEF4444);

    final statusBg =
        question.isCorrect ? Color(0xFFE8F8EF) : Color(0xFFFFEAEA);

    final correctIndex = question.options.indexWhere((item) => item.isCorrect);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.14),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.isCorrect ? 'Trả lời đúng' : 'Trả lời sai',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  question.isCorrect ? 'Đúng' : 'Sai',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            question.question,
            style: TextStyle(
              color: titleColor,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          ...question.options.map(
            (option) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _OptionRow(
                  label: option.label,
                  content: option.content,
                  isSelected: option.label == question.selectedLabel,
                  isCorrect: option.isCorrect,
                  isDark: isDark,
                ),
              );
            },
          ),
          SizedBox(height: 8),
          _ResultRow(
            label: 'Bạn chọn',
            value: '${question.selectedLabel}. ${question.selectedOptionContent}',
            color: question.isCorrect
                ? Color(0xFF16A34A)
                : Color(0xFFEF4444),
          ),
          SizedBox(height: 6),
          if (correctIndex >= 0)
            _ResultRow(
              label: 'Đáp án đúng',
              value:
                  '${question.options[correctIndex].label}. ${question.options[correctIndex].content}',
              color: Color(0xFF16A34A),
            ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final String content;
  final bool isSelected;
  final bool isCorrect;
  final bool isDark;

  const _OptionRow({
    required this.label,
    required this.content,
    required this.isSelected,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = isDark ? Color(0xFF000000) : Colors.white;
    Color textColor = isDark ? Colors.white70 : Colors.black87;
    IconData? icon;
    Color? iconColor;

    if (isCorrect) {
      bgColor = Color(0xFFE8F8EF);
      textColor = Color(0xFF166534);
      icon = Icons.check_circle_rounded;
      iconColor = Color(0xFF16A34A);
    }

    if (isSelected && !isCorrect) {
      bgColor = Color(0xFFFFEAEA);
      textColor = Color(0xFF991B1B);
      icon = Icons.cancel_rounded;
      iconColor = Color(0xFFEF4444);
    }

    return Container(
      padding: EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Text(
            '$label.',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (icon != null) ...[
            SizedBox(width: 8),
            Icon(icon, color: iconColor, size: 18),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _MiniInfo({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 6, 9, 6),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF000000) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryBlue),
          SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}