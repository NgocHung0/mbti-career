import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../services/test_history_service.dart';
import '../test/mbti_result_screen.dart';
import '../test/plus_result_screen.dart';
import '../test/premium_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool loading = true;
  String error = '';
  List<dynamic> histories = [];

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bg => AppColors.bg(context);
  Color get card => AppColors.card(context);
  Color get title => AppColors.title(context);
  Color get sub => AppColors.subText(context);
  Color get border => AppColors.border(context);

  @override
  void initState() {
    super.initState();
    loadHistories();
  }

  List<Map<String, dynamic>> _extractAnswers(Map<String, dynamic> detail) {
    final payload = detail['result_payload'];

    dynamic rawAnswers;

    if (payload is Map) {
      rawAnswers = payload['answers'];
    }

    rawAnswers ??= detail['answers'];

    if (rawAnswers is List) {
      return rawAnswers
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  String _extractPackage(Map<String, dynamic> detail) {
    final payload = detail['result_payload'];

    final candidates = [
      if (payload is Map) payload['package_name'],
      if (payload is Map) payload['package'],
      if (payload is Map) payload['level'],
      detail['package_name'],
      detail['package'],
      detail['test_package'],
      detail['level'],
      detail['test_name'],
    ];

    final text = candidates
        .where((e) => e != null)
        .map((e) => e.toString().toLowerCase())
        .join(' ');

    if (text.contains('premium')) return 'premium';
    if (text.contains('plus')) return 'plus';
    return 'free';
  }

  Future<void> _openHistoryResult(dynamic item) async {
    final id = getId(item);
    if (id == null) return;

    try {
      final data = await TestHistoryService.getHistoryDetail(id);
      final detail = Map<String, dynamic>.from(data['history'] ?? data);

      final package = _extractPackage(detail);
      final answers = _extractAnswers(detail);
      final payload = detail['result_payload'];

      final historyPayload = payload is Map
          ? Map<String, dynamic>.from(payload)
          : <String, dynamic>{};

      final historyMbti =
          detail['result_code']?.toString() ??
          historyPayload['mbti_type']?.toString();

      if (!mounted) return;

      if (package == 'premium') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PremiumResultScreen(
              answers: answers,
              fromHistory: true,
              historyMbti: historyMbti,
              historyPayload: historyPayload,
            ),
          ),
        );
        return;
      }

      if (package == 'plus') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlusResultScreen(
              answers: answers,
              fromHistory: true,
              historyMbti: historyMbti,
              historyPayload: historyPayload,
            ),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MbtiResultScreen(answers: answers, fromHistory: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> loadHistories() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await TestHistoryService.getHistories();

      if (!mounted) return;

      setState(() {
        histories = data;
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

  String getMbti(dynamic item) {
    return item['result_code']?.toString() ??
        item['mbti_type']?.toString() ??
        item['type']?.toString() ??
        item['result']?.toString() ??
        item['mbti']?.toString() ??
        'MBTI';
  }

  String getTestName(dynamic item) {
    return item['test_name']?.toString() ??
        item['title']?.toString() ??
        item['name']?.toString() ??
        'Bài test MBTI';
  }

  String formatLocalDateTime(String raw) {
    if (raw.isEmpty) return 'Không rõ thời gian';

    try {
      final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
      final date = DateTime.parse(normalized).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String getCreatedAt(dynamic item) {
    final raw =
        item['created_at']?.toString() ??
        item['date']?.toString() ??
        item['completed_at']?.toString();

    if (raw == null || raw.isEmpty) return 'Không rõ thời gian';

    return formatLocalDateTime(raw);
  }

  int? getId(dynamic item) {
    final id = item['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: title),
        title: Text(
          'Lịch sử làm bài',
          style: TextStyle(color: title, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: loadHistories,
          color: AppColors.primaryBlue,
          child: loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                )
              : error.isNotEmpty
              ? errorView()
              : histories.isEmpty
              ? emptyView()
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 30),
                  itemCount: histories.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = histories[index];
                    return historyCard(item);
                  },
                ),
        ),
      ),
    );
  }

  Widget emptyView() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        SizedBox(height: 120),
        Icon(Icons.history_rounded, size: 72, color: AppColors.primaryBlue),
        SizedBox(height: 16),
        Text(
          'Chưa có lịch sử làm bài',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: title,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Sau khi hoàn thành bài test, kết quả sẽ được lưu tại đây.',
          textAlign: TextAlign.center,
          style: TextStyle(color: sub, fontSize: 14, height: 1.45),
        ),
      ],
    );
  }

  Widget errorView() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        SizedBox(height: 120),
        Icon(Icons.error_outline_rounded, size: 72, color: Colors.redAccent),
        SizedBox(height: 16),
        Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyle(color: title, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 18),
        ElevatedButton(
          onPressed: loadHistories,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: Text('Thử lại'),
        ),
      ],
    );
  }

  Widget historyCard(dynamic item) {
    final id = getId(item);
    final mbti = getMbti(item);
    final name = getTestName(item);
    final time = getCreatedAt(item);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: id == null ? null : () => _openHistoryResult(item),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Image.network(
                '${AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '')}/images/emoji2/${mbti.toUpperCase()}.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        mbti.length <= 4 ? mbti : 'MBTI',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: title,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Kết quả: $mbti',
                    style: TextStyle(color: sub, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 5),
                  Text(time, style: TextStyle(color: sub, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: sub),
          ],
        ),
      ),
    );
  }
}

class HistoryDetailScreen extends StatefulWidget {
  final int historyId;

  const HistoryDetailScreen({super.key, required this.historyId});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  bool loading = true;
  String error = '';
  Map<String, dynamic> detail = {};

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bg => isDark ? Color(0xFF000000) : AppColors.lightBlue;
  Color get card => isDark ? Color(0xFF111111) : Colors.white;
  Color get title => isDark ? Color(0xFFEAF6FF) : AppColors.textDark;
  Color get sub => isDark ? Color(0xFF94A3B8) : AppColors.textGrey;
  Color get border => isDark ? Color(0xFF2A2A2A) : AppColors.borderColor;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      final data = await TestHistoryService.getHistoryDetail(widget.historyId);

      if (!mounted) return;

      setState(() {
        detail = data['history'] ?? data;
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

  String valueOf(List<String> keys, {String fallback = 'Chưa có'}) {
    for (final key in keys) {
      final value = detail[key];

      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  dynamic payloadOf(String key) {
    final payload = detail['result_payload'];

    if (payload is Map) {
      return payload[key];
    }

    return null;
  }

  String payloadText(List<String> keys, {String fallback = 'Chưa có'}) {
    final payload = detail['result_payload'];

    if (payload is Map) {
      for (final key in keys) {
        final value = payload[key];

        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return fallback;
  }

  String formatDateText(String raw) {
    if (raw.isEmpty || raw == 'Chưa có') return 'Chưa có';

    try {
      final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
      final d = DateTime.parse(normalized).toLocal();

      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic> getScores() {
    final raw = detail['scores'];

    if (raw is Map<String, dynamic>) return raw;

    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }

    return {};
  }

  List<dynamic> getAnswers() {
    final raw = detail['answers'];

    if (raw is List) return raw;

    return [];
  }

  int scoreOf(String key) {
    final scores = getScores();
    final value = scores[key];

    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final mbti = valueOf([
      'result_code',
      'mbti_type',
      'type',
      'result',
      'mbti',
    ]);

    final resultName = payloadText(['name'], fallback: 'Kết quả MBTI của bạn');

    final description = payloadText(
      ['description'],
      fallback:
          'Kết quả này giúp bạn hiểu rõ hơn về điểm mạnh, phong cách giao tiếp và định hướng phù hợp.',
    );

    final timeText = formatDateText(
      valueOf(['created_at', 'date', 'completed_at']),
    );

    final answers = getAnswers();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: title),
        title: Text(
          'Chi tiết lịch sử',
          style: TextStyle(color: title, fontWeight: FontWeight.w900),
        ),
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : error.isNotEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: title),
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                resultHeaderCard(mbti, resultName, description),
                SizedBox(height: 14),
                detailTile(Icons.psychology_rounded, 'Nhóm MBTI', mbti),
                detailTile(Icons.calendar_month_rounded, 'Thời gian', timeText),
                detailTile(
                  Icons.description_rounded,
                  'Loại bài test',
                  'Bài test MBTI',
                ),
                SizedBox(height: 14),
                scoreCard(),
                SizedBox(height: 14),
                answersCard(answers),
              ],
            ),
    );
  }

  Widget resultHeaderCard(String mbti, String resultName, String description) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9B7BEA), AppColors.primaryBlue],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: Text(
                mbti,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            resultName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: title,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: sub, height: 1.5, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  Widget scoreCard() {
    return Container(
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
            'Điểm tính cách',
            style: TextStyle(
              color: title,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          scorePair('Hướng ngoại', 'E', 'I', 'Hướng nội'),
          scorePair('Giác quan', 'S', 'N', 'Trực giác'),
          scorePair('Lý trí', 'T', 'F', 'Cảm xúc'),
          scorePair('Nguyên tắc', 'J', 'P', 'Linh hoạt'),
        ],
      ),
    );
  }

  Widget scorePair(
    String leftLabel,
    String leftKey,
    String rightKey,
    String rightLabel,
  ) {
    final left = scoreOf(leftKey);
    final right = scoreOf(rightKey);
    final total = left + right;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$leftLabel ($leftKey)',
                  style: TextStyle(
                    color: sub,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$left - $right',
                style: TextStyle(color: title, fontWeight: FontWeight.w900),
              ),
              Expanded(
                child: Text(
                  '$rightLabel ($rightKey)',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: sub,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 9),
          Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF60A5FA), // E/S/T/J
                  Color(0xFFA78BFA), // I/N/F/P
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final markerPosition = total == 0
                    ? constraints.maxWidth / 2
                    : constraints.maxWidth * (left / total);

                return Stack(
                  children: [
                    Positioned(
                      left: markerPosition - 9,
                      top: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget answersCard(List<dynamic> answers) {
    return Container(
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
            'Chi tiết câu trả lời',
            style: TextStyle(
              color: title,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          if (answers.isEmpty)
            Text('Chưa có dữ liệu đáp án.', style: TextStyle(color: sub))
          else
            ...answers.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final item = entry.value;

              final question = item is Map
                  ? item['question']?.toString() ?? 'Câu hỏi #$index'
                  : 'Câu hỏi #$index';

              final optionA = item is Map
                  ? item['option_a']?.toString() ?? ''
                  : '';

              final optionB = item is Map
                  ? item['option_b']?.toString() ?? ''
                  : '';

              final selected = item is Map
                  ? item['selected_answer']?.toString() ??
                        item['selected']?.toString() ??
                        item['choice']?.toString() ??
                        ''
                  : '';

              final section = item is Map
                  ? item['section']?.toString() ?? 'Nâng cao'
                  : 'Nâng cao';

              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF000000) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Câu $index: $question',
                      style: TextStyle(
                        color: title,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: sub,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                        children: [
                          TextSpan(
                            text: 'Phần: ',
                            style: TextStyle(
                              color: title,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: section),
                        ],
                      ),
                    ),
                    if (optionA.isNotEmpty) ...[
                      SizedBox(height: 10),
                      Text(
                        'A. $optionA',
                        style: TextStyle(
                          color: sub,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (optionB.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'B. $optionB',
                        style: TextStyle(
                          color: sub,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                    SizedBox(height: 10),
                    Text(
                      'Đáp án đã chọn: $selected',
                      style: TextStyle(
                        color: title,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget summaryCard(String mbti, String timeText) {
    final scores = getScores();

    return Container(
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
            'Tóm tắt kết quả',
            style: TextStyle(
              color: title,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          summaryRow('Kết quả MBTI', mbti),
          summaryRow('Thời gian làm bài', timeText),
          summaryRow('Tổng câu đã trả lời', '${getAnswers().length} câu'),
          summaryRow(
            'Điểm nổi bật',
            scores.isEmpty
                ? 'Chưa có'
                : scores.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('  •  '),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF000000) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: sub, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: title, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget detailTile(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: sub, fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: title, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
