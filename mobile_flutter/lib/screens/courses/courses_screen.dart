import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/top_header.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import '../../services/course_service.dart';
import '../../services/package_service.dart';
import '../courses/course_detail_screen.dart';
import '../packages/payment_qr_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool loading = true;
  String error = '';

  List<Course> courses = [];
  Map<String, dynamic>? currentPackage;

  final TextEditingController searchController = TextEditingController();
  String searchKeyword = '';

  bool get isPremium => PackageService.isPremium(currentPackage);

  List<Course> get filteredCourses {
    final keyword = searchKeyword.trim().toLowerCase();

    if (keyword.isEmpty) {
      return courses;
    }

    return courses.where((course) {
      return course.name.toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final package = await PackageService.getCurrentPackage();
      final data = await CourseService.getCourses();

      if (!mounted) return;

      setState(() {
        currentPackage = package;
        courses = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void openCourse(Course course) {
    if (isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(courseId: course.id),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Yêu cầu gói Premium'),
        content: const Text(
          'Khóa học chỉ dành cho tài khoản Premium. Vui lòng nâng cấp để mở khóa nội dung học.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();

              await Future.delayed(const Duration(milliseconds: 200));

              if (!mounted) return;

              final upgraded = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaymentQrScreen(
                    packageId: 2,
                    packageName: 'Premium',
                    amount: 39000,
                  ),
                ),
              );

              if (upgraded == true) {
                fetchData();
              }
            },
            child: const Text('Nâng cấp'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget buildSearchBox({
    required bool dark,
    required Color card,
    required Color title,
    required Color sub,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: dark
                ? Colors.black.withValues(alpha: 0.18)
                : AppColors.primaryBlue.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchKeyword = value;
          });
        },
        style: TextStyle(
          color: title,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm khóa học theo tên...',
          hintStyle: TextStyle(
            color: sub,
            fontSize: 14,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primaryBlue,
          ),
          suffixIcon: searchKeyword.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: sub,
                  ),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchKeyword = '';
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget buildEmptySearchResult({
    required Color title,
    required Color sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 54,
            color: AppColors.primaryBlue.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy khóa học',
            style: TextStyle(
              color: title,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thử nhập tên khóa học khác để tìm kiếm.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sub,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF000000) : AppColors.lightBlue;
    final card = dark ? const Color(0xFF111111) : Colors.white;
    final title = dark ? const Color(0xFFEAF6FF) : AppColors.textDark;
    final sub = dark ? const Color(0xFF94A3B8) : AppColors.textGrey;
    final border = dark ? const Color(0xFF2A2A2A) : AppColors.borderColor;

    final shownCourses = filteredCourses;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchData,
          color: AppColors.primaryBlue,
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SizedBox(height: 140),
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 70,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: title),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                      children: [
                        TopHeader(
                          title: 'Khóa học',
                          subtitle: isPremium
                              ? 'Bạn đang dùng Premium, có thể học toàn bộ khóa học.'
                              : 'Nâng cấp Premium để mở khóa các khóa học định hướng.',
                          image:
                              '${AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '')}/images/emoji2/Courses.png',
                        ),

                        const SizedBox(height: 18),

                        buildSearchBox(
                          dark: dark,
                          card: card,
                          title: title,
                          sub: sub,
                        ),

                        if (shownCourses.isEmpty)
                          buildEmptySearchResult(
                            title: title,
                            sub: sub,
                          )
                        else
                          ...shownCourses.map((c) {
                            final locked = !isPremium;

                            return InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap: () => openCourse(c),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 18),
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: AppColors.border(context),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                      color: dark
                                          ? Colors.black.withValues(alpha: 0.22)
                                          : AppColors.primaryBlue.withValues(
                                              alpha: 0.10,
                                            ),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(26),
                                          ),
                                          child: c.thumbnail.isEmpty
                                              ? Container(
                                                  height: 190,
                                                  width: double.infinity,
                                                  color: border,
                                                  child: const Icon(
                                                    Icons.school_rounded,
                                                    size: 72,
                                                  ),
                                                )
                                              : Image.network(
                                                  c.thumbnail,
                                                  height: 190,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        if (locked)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.45,
                                                ),
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(26),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.lock_rounded,
                                                  color: Colors.white,
                                                  size: 52,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  c.name,
                                                  style: TextStyle(
                                                    color: title,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: locked
                                                      ? Colors.orange
                                                          .withValues(
                                                              alpha: 0.18)
                                                      : Colors.green.withValues(
                                                          alpha: 0.16,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                  locked ? 'Premium' : 'Đã mở',
                                                  style: TextStyle(
                                                    color: locked
                                                        ? Colors.orange.shade700
                                                        : Colors.green.shade700,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            c.shortDescription.isEmpty
                                                ? 'Khóa học hỗ trợ định hướng và phát triển kỹ năng nghề nghiệp.'
                                                : c.shortDescription,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: sub,
                                              height: 1.45,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.category_rounded,
                                                size: 18,
                                                color: AppColors.primaryBlue,
                                              ),
                                              const SizedBox(width: 7),
                                              Expanded(
                                                child: Text(
                                                  c.courseMajor.isEmpty
                                                      ? 'Định hướng nghề nghiệp'
                                                      : c.courseMajor,
                                                  style: TextStyle(
                                                    color: sub,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                locked
                                                    ? Icons.lock_rounded
                                                    : Icons.play_circle_fill,
                                                color: locked
                                                    ? Colors.orange
                                                    : AppColors.primaryBlue,
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
                          }),
                      ],
                    ),
        ),
      ),
    );
  }
}