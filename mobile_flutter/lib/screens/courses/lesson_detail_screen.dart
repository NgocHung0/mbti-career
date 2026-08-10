import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/course.dart';
import '../../models/course_learning_history.dart';
import '../../services/course_progress_service.dart';
import '../../services/course_quiz_history_service.dart';
import 'youtube_fullscreen_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final CourseLesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  YoutubePlayerController? youtubeController;

  bool videoFinished = false;
  int savedProgress = 0;
  bool loadingProgress = true;
  bool submitted = false;
  bool submitting = false;

  final Map<int, String> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    initPreviewVideo();
    loadProgress();
    restoreSavedAnswers();
  }

  String questionKey(dynamic item, int index) {
    final id = read(item, 'id');
    if (id.trim().isNotEmpty) return id.trim();
    return 'question_$index';
  }

  List<Map<String, dynamic>> getOptions(dynamic q) {
    if (q is Map && q['options'] is List) {
      return List<Map<String, dynamic>>.from(
        (q['options'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
    }

    return [];
  }

  int answeredCount() {
    return selectedAnswers.length;
  }

  bool canSubmit() {
    final total = widget.lesson.questions.length;
    return total > 0 &&
        selectedAnswers.length == total &&
        !submitted &&
        !submitting;
  }

  Future<void> confirmSubmitQuiz() async {
    final total = widget.lesson.questions.length;

    if (total <= 0) return;

    if (selectedAnswers.length < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bạn đã chọn ${selectedAnswers.length}/$total câu. Vui lòng chọn đủ đáp án trước khi nộp bài.',
          ),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Xác nhận nộp bài',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Sau khi nộp bài, bạn sẽ không thể thay đổi đáp án. Bạn có chắc chắn muốn nộp không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Nộp bài'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await submitQuiz();
  }

  Future<void> submitQuiz() async {
    final questions = widget.lesson.questions;

    setState(() {
      submitting = true;
    });

    try {
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final selectedLabel = selectedAnswers[i];

        if (selectedLabel == null) continue;

        final options = getOptions(q);
        final optionIndex = ['A', 'B', 'C', 'D'].indexOf(selectedLabel);

        if (optionIndex < 0 || optionIndex >= options.length) continue;

        final selectedOption = options[optionIndex];
        final correct = selectedOption['is_correct'] == true;

        await CourseQuizHistoryService.saveAnswer(
          lessonId: widget.lesson.id,
          lessonTitle: widget.lesson.title,
          totalQuestions: questions.length,
          questionId: questionKey(q, i),
          question: read(q, 'question').trim().isEmpty
              ? 'Chưa có nội dung câu hỏi.'
              : read(q, 'question'),
          selectedLabel: selectedLabel,
          selectedOptionIndex: optionIndex,
          selectedOptionContent: selectedOption['content']?.toString() ?? '',
          isCorrect: correct,
          options: options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;

            return CourseLearningOptionHistory(
              label: ['A', 'B', 'C', 'D'][index],
              content: option['content']?.toString() ?? '',
              isCorrect: option['is_correct'] == true,
            );
          }).toList(),
        );
      }

      if (!mounted) return;

      setState(() {
        submitted = true;
        submitting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nộp bài thành công.')));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void initPreviewVideo() {
    final videoId = YoutubePlayer.convertUrlToId(widget.lesson.videoUrl);

    if (videoId != null && videoId.isNotEmpty) {
      youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: true,
        ),
      );
    }
  }

  Future<void> loadProgress() async {
    try {
      final data = await CourseProgressService.getProgress(widget.lesson.id);

      if (!mounted) return;

      setState(() {
        savedProgress =
            int.tryParse(data['video_progress']?.toString() ?? '0') ?? 0;
        videoFinished = data['completed'] == true || data['completed'] == 1;
        loadingProgress = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loadingProgress = false;
      });
    }
  }

  Future<void> restoreSavedAnswers() async {
    final history = await CourseQuizHistoryService.getHistoryByLessonId(
      widget.lesson.id,
    );

    if (history == null) return;

    final questions = widget.lesson.questions;

    for (int i = 0; i < questions.length; i++) {
      final key = questionKey(questions[i], i);

      final matched = history.questions.where((item) {
        return item.questionId == key;
      }).toList();

      if (matched.isNotEmpty) {
        selectedAnswers[i] = matched.first.selectedLabel;
      }
    }

    if (!mounted) return;

    setState(() {});
  }

  Future<void> saveAnswerToHistory({
    required dynamic questionData,
    required int questionIndex,
    required int optionIndex,
    required String label,
    required String text,
    required bool correct,
  }) async {
    try {
      final options = getOptions(questionData);

      await CourseQuizHistoryService.saveAnswer(
        lessonId: widget.lesson.id,
        lessonTitle: widget.lesson.title,
        totalQuestions: widget.lesson.questions.length,
        questionId: questionKey(questionData, questionIndex),
        question: read(questionData, 'question').trim().isEmpty
            ? 'Chưa có nội dung câu hỏi.'
            : read(questionData, 'question'),
        selectedLabel: label,
        selectedOptionIndex: optionIndex,
        selectedOptionContent: text,
        isCorrect: correct,
        options: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;

          return CourseLearningOptionHistory(
            label: ['A', 'B', 'C', 'D'][index],
            content: option['content']?.toString() ?? '',
            isCorrect: option['is_correct'] == true,
          );
        }).toList(),
      );
    } catch (e) {
      debugPrint('saveAnswerToHistory error: $e');
    }
  }

  @override
  void dispose() {
    youtubeController?.dispose();
    super.dispose();
  }

  Future<void> openFullscreenVideo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YoutubeFullscreenScreen(
          videoUrl: widget.lesson.videoUrl,
          lessonId: widget.lesson.id,
          startAtSeconds: savedProgress,
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map) {
      final progress = int.tryParse(result['progress']?.toString() ?? '0') ?? 0;
      final completed = result['completed'] == true;

      setState(() {
        savedProgress = progress;
        videoFinished = videoFinished || completed;
      });
    }
  }

  String read(dynamic item, String key) {
    if (item is Map) return item[key]?.toString() ?? '';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.lesson.questions;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.title(context)),
        title: Text(
          'Bài học',
          style: TextStyle(
            color: AppColors.title(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border(context)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.softCard(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF9B7BEA),
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lesson.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.title(context),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            widget.lesson.description.isEmpty
                                ? 'Chưa có mô tả bài học.'
                                : widget.lesson.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: AppColors.subText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    chip(
                      Icons.play_circle_rounded,
                      'Video',
                      AppColors.primaryBlue,
                    ),
                    if (widget.lesson.duration.isNotEmpty)
                      chip(
                        Icons.access_time_rounded,
                        widget.lesson.duration,
                        Colors.green,
                      ),
                    if (savedProgress > 0 && !videoFinished)
                      chip(
                        Icons.history_rounded,
                        'Tiếp tục từ ${formatTime(savedProgress)}',
                        Colors.orange,
                      ),
                    if (videoFinished)
                      chip(
                        Icons.check_circle_rounded,
                        'Đã hoàn thành',
                        Colors.green,
                      ),
                  ],
                ),
                SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: youtubeController != null
                      ? GestureDetector(
                          onTap: openFullscreenVideo,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AbsorbPointer(
                                child: YoutubePlayer(
                                  controller: youtubeController!,
                                  showVideoProgressIndicator: true,
                                  progressIndicatorColor: AppColors.primaryBlue,
                                ),
                              ),
                              Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.50),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          height: 190,
                          width: double.infinity,
                          color: AppColors.softCard(context),
                          child: Center(
                            child: Text(
                              'Chưa có video hợp lệ.',
                              style: TextStyle(
                                color: AppColors.subText(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          if (loadingProgress)
            Center(child: CircularProgressIndicator())
          else if (!videoFinished)
            lockedQuestion()
          else ...[
            questionHeader(),
            SizedBox(height: 14),
            if (questions.isEmpty)
              emptyQuestion()
            else
              ...questions.asMap().entries.map((entry) {
                final index = entry.key;
                final q = entry.value;

                final question = read(q, 'question');
                final options = getOptions(q);

                return questionCard(
                  index: index,
                  question: question,
                  answers: options.asMap().entries.map((optionEntry) {
                    final optionIndex = optionEntry.key;
                    final option = optionEntry.value;

                    final label = ['A', 'B', 'C', 'D'][optionIndex];
                    final text = option['content']?.toString() ?? '';
                    final correct = option['is_correct'] == true;

                    return answerTile(
                      questionData: q,
                      questionIndex: index,
                      optionIndex: optionIndex,
                      label: label,
                      text: text,
                      correct: correct,
                    );
                  }).toList(),
                );
              }),
          ],
        ],
      ),
    );
  }

  String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget lockedQuestion() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline_rounded, size: 42, color: Color(0xFF9B7BEA)),
          SizedBox(height: 14),
          Text(
            'Câu hỏi bài học đang bị khóa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.title(context),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vui lòng xem hết video để mở khóa câu hỏi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subText(context), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget questionHeader() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.softCard(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.quiz_rounded, color: Color(0xFF9B7BEA)),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Câu hỏi bài học',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.title(context),
                ),
              ),
              Text(
                'Chỉ được chọn đáp án một lần',
                style: TextStyle(color: AppColors.subText(context), fontSize: 13.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget chip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget questionCard({
    required int index,
    required String question,
    required List<Widget> answers,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF9B7BEA),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.isEmpty ? 'Chưa có nội dung câu hỏi.' : question,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                    color: AppColors.title(context),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          ...answers,
        ],
      ),
    );
  }

  Widget answerTile({
    required dynamic questionData,
    required int questionIndex,
    required int optionIndex,
    required String label,
    required String text,
    required bool correct,
  }) {
    final selected = selectedAnswers[questionIndex];
    final hasSelected = selected != null;
    final isSelected = selected == label;

    Color bg = AppColors.softCard(context);
    Color border = AppColors.border(context);
    Color badgeBg = AppColors.softCard(context);
    Color badgeText = AppColors.title(context);

    if (hasSelected) {
      if (isSelected && correct) {
        bg = Color(0xFFEAFBF1);
        border = Colors.green.shade200;
        badgeBg = Colors.green;
        badgeText = Colors.white;
      } else if (isSelected && !correct) {
        bg = Color(0xFFFFF1F2);
        border = Colors.red.shade200;
        badgeBg = Colors.red;
        badgeText = Colors.white;
      } else if (correct) {
        bg = Color(0xFFEAFBF1);
        border = Colors.green.shade200;
        badgeBg = Colors.green;
        badgeText = Colors.white;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: hasSelected
          ? null
          : () async {
              setState(() {
                selectedAnswers[questionIndex] = label;
              });

              await saveAnswerToHistory(
                questionData: questionData,
                questionIndex: questionIndex,
                optionIndex: optionIndex,
                label: label,
                text: text,
                correct: correct,
              );
            },
      child: Container(
        margin: EdgeInsets.only(bottom: 9),
        padding: EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: badgeBg,
              child: Text(
                label,
                style: TextStyle(color: badgeText, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: AppColors.title(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hasSelected && isSelected)
              Text(
                correct ? 'Đúng' : 'Sai',
                style: TextStyle(
                  color: correct ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w900,
                ),
              )
            else if (hasSelected && correct)
              Icon(Icons.check_circle_rounded, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget emptyQuestion() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text(
        'Chưa có câu hỏi cho bài học này.',
        style: TextStyle(color: AppColors.subText(context)),
      ),
    );
  }
}
