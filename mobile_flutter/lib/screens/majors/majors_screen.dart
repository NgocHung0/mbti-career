import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/major.dart';
import '../../services/major_service.dart';
import 'major_detail_screen.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/top_header.dart';

class MajorsScreen extends StatefulWidget {
  const MajorsScreen({super.key});

  @override
  State<MajorsScreen> createState() => _MajorsScreenState();
}

class _MajorsScreenState extends State<MajorsScreen> {
  late Future<List<Major>> futureMajors;
  String keyword = '';

  @override
  void initState() {
    super.initState();
    futureMajors = MajorService().getMajors();
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bg => isDark ? Color(0xFF000000) : AppColors.lightBlue;
  Color get card => isDark ? Color(0xFF111111) : Colors.white;
  Color get titleColor => isDark ? Color(0xFFEAF6FF) : AppColors.textDark;
  Color get subColor => isDark ? Color(0xFF94A3B8) : AppColors.textGrey;
  Color get borderColor => isDark ? Color(0xFF2A2A2A) : AppColors.borderColor;
  Color get softBlue => isDark ? Color(0xFF1A1A1A) : Color(0xFFEAF6FF);

  List<Major> filterMajors(List<Major> majors) {
    return majors.where((major) {
      final keywordLower = keyword.trim().toLowerCase();

      return keywordLower.isEmpty ||
          major.title.toLowerCase().contains(keywordLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopHeader(
                title: 'Ngành nghề',
                subtitle: 'Khám phá các ngành nghề phù hợp với tính cách MBTI.',
                image:
                    '${AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '')}/images/emoji2/Major.png',
              ),
              SizedBox(height: 18),
              searchAndFilter(context),
              SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Major>>(
                  future: futureMajors,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Không thể tải ngành nghề.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }
                    final majors = filterMajors(snapshot.data ?? []);
                    if (majors.isEmpty) {
                      return Center(
                        child: Text(
                          'Không tìm thấy ngành phù hợp',
                          style: TextStyle(color: subColor),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 75,
                      ),
                      itemCount: majors.length,
                      itemBuilder: (context, index) {
                        final major = majors[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MajorDetailScreen(major: major),
                              ),
                            );
                          },
                          child: MajorCard(major: major),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget searchAndFilter(BuildContext context) {
    return TextField(
      onChanged: (value) => setState(() => keyword = value),
      style: TextStyle(color: titleColor),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm ngành nghề...',
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryBlue),
        filled: true,
        fillColor: AppColors.card(context),
        hintStyle: TextStyle(color: subColor),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: AppColors.border(context)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
    );
  }

  Widget title(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: titleColor,
    ),
  );
  Widget subtitle(String text) => Text(
    text,
    style: TextStyle(fontSize: 14.5, height: 1.45, color: subColor),
  );
}

class MajorCard extends StatelessWidget {
  final Major major;
  const MajorCard({super.key, required this.major});

  Color colorFromName(String name) {
    final colors = [
      const Color(0xFF2EA7FF),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFFFF8A3D),
      const Color(0xFFEF5DA8),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = colorFromName(major.title);
    final fallback = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEAF6FF);

    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: major.image.isNotEmpty
                  ? Image.network(
                      major.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => imageFallback(fallback),
                    )
                  : imageFallback(fallback),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    major.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 14,
              top: 14,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF111111).withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.88),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget imageFallback(Color color) => Container(
    height: 220,
    width: double.infinity,
    color: color,
    child: Icon(Icons.image_rounded, color: AppColors.primaryBlue, size: 42),
  );
}
