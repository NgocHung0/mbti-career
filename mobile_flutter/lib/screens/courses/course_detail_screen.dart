import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import 'lesson_detail_screen.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;

  CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool loading = true;
  String error = '';

  Course? course;
  List<CourseLesson> lessons = [];

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      final c = await CourseService.getCourseDetail(widget.courseId);
      final l = await CourseService.getLessons(widget.courseId);

      if (!mounted) return;

      setState(() {
        course = c;
        lessons = l;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  void openLesson(CourseLesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Color(0xFF000000) : AppColors.lightBlue;
    final card = isDark ? Color(0xFF111111) : Colors.white;
    final title = isDark ? Color(0xFFEAF6FF) : AppColors.textDark;
    final sub = isDark ? Color(0xFF94A3B8) : AppColors.textGrey;
    final border = isDark ? Color(0xFF2A2A2A) : AppColors.borderColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: title),
        title: Text(
          'Chi tiết khóa học',
          style: TextStyle(color: title, fontWeight: FontWeight.w900),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
              child: Text(error, style: TextStyle(color: title)),
            )
          : course == null
          ? Center(
              child: Text('Không có dữ liệu.', style: TextStyle(color: title)),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: course!.thumbnail.isEmpty
                      ? Container(
                          height: 210,
                          color: border,
                          child: Icon(Icons.school_rounded, size: 72),
                        )
                      : Image.network(
                          course!.thumbnail,
                          height: 210,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                SizedBox(height: 18),
                Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course!.name,
                        style: TextStyle(
                          color: title,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        course!.description.isNotEmpty
                            ? course!.description
                            : course!.shortDescription,
                        style: TextStyle(color: sub, height: 1.5),
                      ),
                      SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              course!.courseMajor.isEmpty
                                  ? 'Khóa học'
                                  : course!.courseMajor,
                              style: TextStyle(
                                color: title,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Danh sách bài học',
                  style: TextStyle(
                    color: title,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12),
                if (lessons.isEmpty)
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      'Chưa có bài học.',
                      style: TextStyle(color: sub),
                    ),
                  )
                else
                  ...lessons.map((lesson) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => openLesson(lesson),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.play_lesson_rounded,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    style: TextStyle(
                                      color: title,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    lesson.duration.isEmpty
                                        ? lesson.contentType
                                        : '${lesson.contentType} • ${lesson.duration}',
                                    style: TextStyle(
                                      color: sub,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: sub),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
