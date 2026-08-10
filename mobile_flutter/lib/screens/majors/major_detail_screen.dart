import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/major.dart';
import '../main/main_screen.dart';

class MajorDetailScreen extends StatelessWidget {
  final Major major;

  const MajorDetailScreen({super.key, required this.major});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Color(0xFF000000) : AppColors.lightBlue;
    final card = isDark ? Color(0xFF111111) : Colors.white;
    final titleColor = isDark ? Color(0xFFEAF6FF) : AppColors.textDark;
    final subColor = isDark ? Color(0xFF94A3B8) : AppColors.textGrey;
    final softBlue = isDark ? Color(0xFF1A1A1A) : Color(0xFFEAF6FF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        foregroundColor: AppColors.title(context),
        elevation: 0,
        iconTheme: IconThemeData(color: titleColor),
        title: Text(
          major.title,
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).padding.bottom + 75,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: major.image.isNotEmpty
                      ? Image.network(
                          major.image,
                          width: double.infinity,
                          height: 210,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => imageFallback(softBlue),
                        )
                      : imageFallback(softBlue),
                ),
                SizedBox(height: 22),
                Text(
                  major.title,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  major.desc,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.65,
                    color: subColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (major.careerProspects.trim().isNotEmpty) ...[
                  SizedBox(height: 14),
                  Text(
                    major.careerProspects,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.65,
                      color: subColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (major.skills.trim().isNotEmpty) ...[
                  SizedBox(height: 18),
                  sectionTitle(
                    icon: Icons.psychology_rounded,
                    title: 'Kỹ năng cần có',
                    titleColor: titleColor,
                  ),
                  SizedBox(height: 8),
                  Text(
                    major.skills,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: subColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (major.tags.isNotEmpty) ...[
                  SizedBox(height: 18),
                  sectionTitle(
                    icon: Icons.auto_awesome_rounded,
                    title: 'MBTI phù hợp',
                    titleColor: titleColor,
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: major.tags
                        .map((tag) => tagChip(tag, softBlue, titleColor))
                        .toList(),
                  ),
                ],
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MainScreen(initialIndex: 2),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Làm bài test ngay',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
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

  Widget sectionTitle({
    required IconData icon,
    required String title,
    required Color titleColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 22),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget tagChip(String text, Color bg, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget imageFallback(Color color) {
    return Container(
      width: double.infinity,
      height: 210,
      color: color,
      child: Icon(
        Icons.image_rounded,
        color: AppColors.primaryBlue,
        size: 50,
      ),
    );
  }
}
