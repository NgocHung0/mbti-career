import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/package_service.dart';
import 'course_learning_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationEnabled = true;
  bool darkModeEnabled = false;
  String avatarPath = '';
  String avatarUrl = '';
  String avatarVersion = '';
  bool isLoggedIn = false;
  String userName = 'Khách';
  String userEmail = 'Bạn đang sử dụng chế độ miễn phí';
  String currentPackageName = 'Free';
  Map<String, dynamic>? currentPackage;

  final ScrollController _scrollController = ScrollController();

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor => isDark ? Color(0xFF0F172A) : AppColors.lightBlue;
  Color get cardColor => isDark ? Color(0xFF1E293B) : Colors.white;
  Color get titleColor => isDark ? Color(0xFFEAF6FF) : AppColors.textDark;
  Color get subTextColor =>
      isDark ? Color(0xFF94A3B8) : AppColors.textGrey;
  Color get borderColor =>
      isDark ? Color(0xFF334155) : AppColors.borderColor;

  @override
  void initState() {
    super.initState();
    loadUser();
    loadTheme();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadTheme() async {
    final isDarkMode = await ThemeController.isDarkMode();

    if (!mounted) return;

    setState(() {
      darkModeEnabled = isDarkMode;
    });
  }

  Future<void> loadUser() async {
    final logged = await AuthService.isLoggedIn();
    final prefs = await SharedPreferences.getInstance();

    Map<String, String> user = await AuthService.getUser();
    Map<String, dynamic>? package;
    String freshAvatarUrl = user['avatar_url'] ?? '';
    String freshAvatarVersion = DateTime.now().millisecondsSinceEpoch.toString();

    if (logged) {
      try {
        final summary = await AuthService.getProfileSummary();
        final freshUser = summary['user'];

        if (freshUser is Map) {
          user = {
            'name': freshUser['name']?.toString() ?? user['name'] ?? 'Khách',
            'email': freshUser['email']?.toString() ?? user['email'] ?? '',
            'avatar_url': AuthService.resolveAvatarUrl(
                  freshUser['avatar_url'] ??
                      freshUser['avatar'] ??
                      freshUser['profile_photo_url'],
                ) ??
                freshAvatarUrl,
          };

          freshAvatarUrl = user['avatar_url'] ?? '';
          freshAvatarVersion = freshUser['updated_at']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString();
        }

        package = summary['package'];
      } catch (_) {
        package = await PackageService.getCurrentPackage();
        freshAvatarUrl = prefs.getString('user_avatar_url') ?? freshAvatarUrl;
      }
    }

    final email = user['email'] ?? '';
    final localAvatarPath = logged
        ? prefs.getString('user_avatar_path_$email') ?? ''
        : '';

    if (!mounted) return;

    setState(() {
      isLoggedIn = logged;
      userName = logged ? (user['name'] ?? 'Khách') : 'Khách';
      userEmail = logged
          ? (user['email'] ?? '')
          : 'Bạn đang sử dụng chế độ miễn phí';

      avatarPath = logged && File(localAvatarPath).existsSync()
          ? localAvatarPath
          : '';
      avatarUrl = logged ? freshAvatarUrl : '';
      avatarVersion = freshAvatarVersion;

      currentPackage = package;
      currentPackageName = logged
          ? PackageService.packageLabel(package)
          : 'Free';
    });
  }

  Future<void> openLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LoginScreen(),
      ),
    );

    if (result == true) {
      await loadUser();
    }
  }

  void requireLogin() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Cần đăng nhập',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Bạn cần đăng nhập hoặc tạo tài khoản để sử dụng chức năng này.',
          style: TextStyle(color: subTextColor, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Để sau', style: TextStyle(color: subTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    await AuthService.logout();
    await loadUser();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void openLearningHistory() {
    if (!isLoggedIn) {
      requireLogin();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseLearningHistoryScreen(),
      ),
    );
  }

  void openTestHistory() {
    if (!isLoggedIn) {
      requireLogin();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(),
      ),
    );
  }

  Future<void> openProfile() async {
    if (!isLoggedIn) {
      requireLogin();
      return;
    }

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          currentName: userName,
          currentEmail: userEmail,
        ),
      ),
    );

    await loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).padding.bottom + 90,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header(),
              SizedBox(height: 22),
              profileCard(),
              SizedBox(height: 18),

              SettingItem(
                title: 'Hồ sơ',
                icon: Icons.person_rounded,
                onTap: openProfile,
                cardColor: cardColor,
                titleColor: titleColor,
                subTextColor: subTextColor,
                borderColor: borderColor,
              ),

              SettingItem(
                title: 'Lịch sử làm bài',
                icon: Icons.history_rounded,
                onTap: openTestHistory,
                cardColor: cardColor,
                titleColor: titleColor,
                subTextColor: subTextColor,
                borderColor: borderColor,
              ),

              SettingItem(
                title: 'Lịch sử học tập',
                icon: Icons.history_edu_rounded,
                onTap: openLearningHistory,
                cardColor: cardColor,
                titleColor: titleColor,
                subTextColor: subTextColor,
                borderColor: borderColor,
              ),

              SettingSwitchItem(
                title: 'Giao diện tối',
                icon: Icons.dark_mode_rounded,
                value: darkModeEnabled,
                onChanged: (value) async {
                  setState(() {
                    darkModeEnabled = value;
                  });

                  await ThemeController.setDarkMode(value);
                },
                cardColor: cardColor,
                titleColor: titleColor,
                borderColor: borderColor,
              ),

              SettingItem(
                title: 'Điều khoản',
                icon: Icons.description_rounded,
                onTap: () {
                  showInfoDialog(
                    title: 'Điều khoản sử dụng',
                    content:
                        'Ứng dụng NAVI hỗ trợ định hướng nghề nghiệp dựa trên MBTI. Kết quả chỉ mang tính tham khảo.',
                  );
                },
                cardColor: cardColor,
                titleColor: titleColor,
                subTextColor: subTextColor,
                borderColor: borderColor,
              ),

              SettingItem(
                title: 'Liên hệ hỗ trợ',
                icon: Icons.support_agent_rounded,
                onTap: () {
                  showInfoDialog(
                    title: 'Liên hệ hỗ trợ',
                    content:
                        'Nếu gặp lỗi hoặc cần hỗ trợ, bạn có thể liên hệ nhóm phát triển NAVI.',
                  );
                },
                cardColor: cardColor,
                titleColor: titleColor,
                subTextColor: subTextColor,
                borderColor: borderColor,
              ),

              if (isLoggedIn)
                SettingItem(
                  title: 'Đăng xuất',
                  icon: Icons.logout_rounded,
                  onTap: logout,
                  danger: true,
                  cardColor: cardColor,
                  titleColor: titleColor,
                  subTextColor: subTextColor,
                  borderColor: borderColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cài đặt',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Quản lý trải nghiệm sử dụng ứng dụng NAVI.',
                style: TextStyle(fontSize: 14.5, color: subTextColor),
              ),
            ],
          ),
        ),
        if (!isLoggedIn)
          TextButton(
            onPressed: openLogin,
            style: TextButton.styleFrom(
              backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
              foregroundColor: AppColors.primaryBlue,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
            ),
            child: Text(
              'Đăng nhập',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }

  ImageProvider? get profileAvatarImage {
    if (isLoggedIn && avatarPath.isNotEmpty && File(avatarPath).existsSync()) {
      return FileImage(File(avatarPath));
    }

    if (isLoggedIn && avatarUrl.isNotEmpty) {
      final separator = avatarUrl.contains('?') ? '&' : '?';
      return NetworkImage('$avatarUrl${separator}v=$avatarVersion');
    }

    return null;
  }

  Widget profileCard() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isDark
                ? Color(0xFF1A1A1A)
                : Color(0xFFEAF6FF),
            backgroundImage: profileAvatarImage,
            child: profileAvatarImage == null
                ? Icon(
                    Icons.person_rounded,
                    color: AppColors.primaryBlue,
                    size: 30,
                  )
                : null,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(fontSize: 13.5, color: subTextColor),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: PackageService.isPremium(currentPackage)
                        ? Color(0xFF9B7BEA).withValues(alpha: 0.18)
                        : PackageService.isPlus(currentPackage)
                            ? Color(0xFF45C58A).withValues(alpha: 0.18)
                            : AppColors.primaryBlue.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Gói hiện tại: $currentPackageName',
                    style: TextStyle(
                      color: PackageService.isPremium(currentPackage)
                          ? Color(0xFFBFA7FF)
                          : PackageService.isPlus(currentPackage)
                              ? Color(0xFF45C58A)
                              : AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showInfoDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          title,
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w900),
        ),
        content: Text(
          content,
          style: TextStyle(color: subTextColor, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class SettingItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  final Color cardColor;
  final Color titleColor;
  final Color subTextColor;
  final Color borderColor;

  SettingItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.cardColor,
    required this.titleColor,
    required this.subTextColor,
    required this.borderColor,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : AppColors.primaryBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: danger ? Colors.redAccent : titleColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subTextColor),
          ],
        ),
      ),
    );
  }
}

class SettingSwitchItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color cardColor;
  final Color titleColor;
  final Color borderColor;

  SettingSwitchItem({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.cardColor,
    required this.titleColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}