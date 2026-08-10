import 'dart:async';
import 'package:flutter/material.dart';
import 'mbti_result_screen.dart';
import '../../core/constants/app_colors.dart';

class AdVideoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> answers;

  AdVideoScreen({super.key, required this.answers});

  @override
  State<AdVideoScreen> createState() => _AdVideoScreenState();
}

class _AdVideoScreenState extends State<AdVideoScreen> {
  int seconds = 5;
  Timer? timer;

  static const darkBg = Color(0xFF000000);
  static const darkCard = Color(0xFF111111);
  static const primaryBlue = Color(0xFF7DBEFF);
  static const textLight = Color(0xFFEAF6FF);
  static const textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (seconds <= 1) {
        timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MbtiResultScreen(answers: widget.answers),
          ),
        );
      } else {
        setState(() => seconds--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: darkBg,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Đang hiển thị quảng cáo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textLight, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Bạn đang dùng gói Free. Vui lòng chờ quảng cáo kết thúc để xem kết quả cơ bản.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textMuted, height: 1.5, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 26),
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: seconds / 5,
                            strokeWidth: 9,
                            backgroundColor: Colors.white.withValues(alpha: .08),
                            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                          ),
                          Center(
                            child: Text(
                              '$seconds',
                              style: TextStyle(color: textLight, fontSize: 34, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Kết quả sẽ tự động mở sau khi hết thời gian.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
