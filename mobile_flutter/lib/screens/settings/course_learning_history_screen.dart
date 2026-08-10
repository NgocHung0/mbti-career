import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/course_learning_history.dart';
import '../../services/course_quiz_history_service.dart';
import 'course_learning_history_detail_screen.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';

class CourseLearningHistoryScreen extends StatefulWidget {
  CourseLearningHistoryScreen({super.key});

  @override
  State<CourseLearningHistoryScreen> createState() =>
      _CourseLearningHistoryScreenState();
}

class _CourseLearningHistoryScreenState
    extends State<CourseLearningHistoryScreen> {
  late Future<List<CourseLearningHistory>> _future;

  @override
  void initState() {
    super.initState();
    _future = CourseQuizHistoryService.getHistories();
  }

  Future<void> _reload() async {
    setState(() {
      _future = CourseQuizHistoryService.getHistories();
    });

    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Color(0xFF000000) : AppColors.lightBlue;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: _Header(isDark: isDark),
                ),
              ),
              FutureBuilder<List<CourseLearningHistory>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _StateMessage(
                        icon: Icons.quiz_rounded,
                        title: 'Chưa có bài làm nào',
                        message:
                            'Khi bạn làm câu hỏi sau video, bài làm sẽ được lưu và hiển thị tại đây.',
                      ),
                    );
                  }

                  final totalLessons = items.length;
                  final totalQuestions = items.fold<int>(
                    0,
                    (sum, item) => sum + item.questions.length,
                  );
                  final totalCorrect = items.fold<int>(
                    0,
                    (sum, item) => sum + item.correctCount,
                  );

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
                        child: _StatsRow(
                          totalLessons: totalLessons,
                          totalQuestions: totalQuestions,
                          totalCorrect: totalCorrect,
                          isDark: isDark,
                        ),
                      ),
                      ...items.map(
                        (item) => Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: _HistoryCard(
                            item: item,
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CourseLearningHistoryDetailScreen(
                                    item: item,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ]),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lịch sử học tập',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Xem lại bài làm câu hỏi sau video bài học.',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalLessons;
  final int totalQuestions;
  final int totalCorrect;
  final bool isDark;

  const _StatsRow({
    required this.totalLessons,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Bài đã làm',
            value: totalLessons.toString(),
            icon: Icons.menu_book_rounded,
            isDark: isDark,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Câu đã làm',
            value: totalQuestions.toString(),
            icon: Icons.quiz_rounded,
            isDark: isDark,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Câu đúng',
            value: totalCorrect.toString(),
            icon: Icons.check_circle_rounded,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 13, 12, 13),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 22),
          SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textDark,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final CourseLearningHistory item;
  final bool isDark;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final good = item.wrongCount == 0;
    final statusBg = good ? Color(0xFFE8F8EF) : Color(0xFFFFF4D6);
    final statusFg = good ? Color(0xFF16A34A) : Color(0xFFE59F00);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.assignment_turned_in_rounded,
                color: AppColors.primaryBlue,
                size: 30,
              ),
            ),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.courseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.lessonTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textDark,
                      fontSize: 16,
                      height: 1.22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
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
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          good ? 'Hoàn thành tốt' : '${item.wrongCount} câu sai',
                          style: TextStyle(
                            color: statusFg,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white38 : Colors.black26,
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

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF111111) : Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.primaryBlue),
              SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}