import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;

  const ProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;
  final TextEditingController currentPasswordCtrl = TextEditingController();
  final TextEditingController newPasswordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();
  final TextEditingController otpCtrl = TextEditingController();

  bool loadingProfile = true;
  bool savingProfile = false;
  bool passwordLoading = false;
  bool profileOpen = true;
  bool passwordOpen = false;
  bool otpSent = false;
  bool hideCurrentPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

  String avatarPath = '';
  String serverAvatarUrl = '';
  String avatarVersion = '';

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bg => AppColors.bg(context);
  Color get card => AppColors.card(context);
  Color get title => AppColors.title(context);
  Color get sub => AppColors.subText(context);
  Color get border => AppColors.border(context);

  String get avatarPathKey => 'user_avatar_path_${widget.currentEmail}';

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.currentName);
    emailCtrl = TextEditingController(text: widget.currentEmail);
    _loadLocalAvatar();
    _loadFreshProfile();
  }

  Future<void> _loadLocalAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final localPath = prefs.getString(avatarPathKey) ?? '';

    if (!mounted) return;

    setState(() {
      avatarPath = File(localPath).existsSync() ? localPath : '';
      serverAvatarUrl = prefs.getString('user_avatar_url') ?? '';
    });
  }

  Future<void> _loadFreshProfile() async {
    try {
      final data = await AuthService.getProfileSummary();
      final user = data['user'];

      if (user is! Map) {
        throw Exception('Không tìm thấy thông tin tài khoản.');
      }

      final freshName = user['name']?.toString() ?? '';
      final freshEmail = user['email']?.toString() ?? '';
      final freshAvatar = AuthService.resolveAvatarUrl(
            user['avatar_url'] ?? user['avatar'] ?? user['profile_photo_url'],
          ) ??
          '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', freshName);
      await prefs.setString('user_email', freshEmail);

      if (freshAvatar.isNotEmpty) {
        await prefs.setString('user_avatar_url', freshAvatar);
        await prefs.remove(avatarPathKey);
      }

      if (!mounted) return;

      setState(() {
        nameCtrl.text = freshName;
        emailCtrl.text = freshEmail;
        serverAvatarUrl = freshAvatar;
        avatarPath = freshAvatar.isNotEmpty ? '' : avatarPath;
        avatarVersion = user['updated_at']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
        loadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadingProfile = false;
      });

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1400,
    );

    if (image == null || !mounted) return;

    final file = File(image.path);
    if (!file.existsSync()) return;

    setState(() {
      avatarPath = image.path;
    });
  }

  Future<void> _saveProfile() async {
    final name = nameCtrl.text.trim();

    if (name.isEmpty) {
      _showMessage('Vui lòng nhập họ và tên.', isError: true);
      return;
    }

    setState(() {
      savingProfile = true;
    });

    try {
      final data = await AuthService.updateProfile(
        name: name,
        avatarPath: avatarPath.isNotEmpty ? avatarPath : null,
      );

      final user = data['user'];
      final latestName = user is Map
          ? (user['name']?.toString() ?? name)
          : name;
      final latestEmail = user is Map
          ? (user['email']?.toString() ?? emailCtrl.text)
          : emailCtrl.text;
      final avatarUrl = AuthService.extractAvatarUrl(data) ?? serverAvatarUrl;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', latestName);
      await prefs.setString('user_email', latestEmail);

      if (avatarUrl.isNotEmpty) {
        await prefs.setString('user_avatar_url', avatarUrl);
        await prefs.remove(avatarPathKey);
      }

      AuthService.notifyAuthChanged();

      if (!mounted) return;

      setState(() {
        nameCtrl.text = latestName;
        emailCtrl.text = latestEmail;
        serverAvatarUrl = avatarUrl;
        avatarPath = avatarUrl.isNotEmpty ? '' : avatarPath;
        avatarVersion = DateTime.now().millisecondsSinceEpoch.toString();
        savingProfile = false;
      });

      _showMessage(data['message']?.toString() ?? 'Cập nhật thông tin thành công.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        savingProfile = false;
      });

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _requestPasswordOtp() async {
    final currentPassword = currentPasswordCtrl.text;
    final newPassword = newPasswordCtrl.text;
    final confirmPassword = confirmPasswordCtrl.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin.', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showMessage('Mật khẩu mới phải có ít nhất 6 ký tự.', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Mật khẩu xác nhận không khớp.', isError: true);
      return;
    }

    setState(() {
      passwordLoading = true;
    });

    try {
      final message = await AuthService.requestPasswordOtp(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (!mounted) return;

      setState(() {
        passwordLoading = false;
        otpSent = true;
        otpCtrl.clear();
      });

      _showMessage(message);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        passwordLoading = false;
      });

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _verifyPasswordOtp() async {
    final otp = otpCtrl.text.trim();

    if (otp.length != 6) {
      _showMessage('Vui lòng nhập mã OTP gồm 6 số.', isError: true);
      return;
    }

    setState(() {
      passwordLoading = true;
    });

    try {
      final message = await AuthService.verifyPasswordOtp(otp: otp);

      if (!mounted) return;

      setState(() {
        passwordLoading = false;
        otpSent = false;
        currentPasswordCtrl.clear();
        newPasswordCtrl.clear();
        confirmPasswordCtrl.clear();
        otpCtrl.clear();
      });

      _showMessage(message);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        passwordLoading = false;
      });

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted || message.trim().isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : const Color(0xFF15965F),
        ),
      );
  }

  ImageProvider? _avatarProvider() {
    if (avatarPath.isNotEmpty && File(avatarPath).existsSync()) {
      return FileImage(File(avatarPath));
    }

    if (serverAvatarUrl.isNotEmpty) {
      final separator = serverAvatarUrl.contains('?') ? '&' : '?';
      return NetworkImage('$serverAvatarUrl${separator}v=$avatarVersion');
    }

    return null;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: title,
        title: Text(
          'Hồ sơ cá nhân',
          style: TextStyle(color: title, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: loadingProfile
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  MediaQuery.of(context).padding.bottom + 30,
                ),
                child: Column(
                  children: [
                    _profileHeader(),
                    const SizedBox(height: 16),
                    _accordionCard(
                      titleText: 'Thay đổi thông tin cá nhân',
                      subtitle: 'Cập nhật họ tên và ảnh đại diện của bạn',
                      isOpen: profileOpen,
                      onTap: () {
                        setState(() {
                          profileOpen = !profileOpen;
                          if (profileOpen) passwordOpen = false;
                        });
                      },
                      child: _profileForm(),
                    ),
                    const SizedBox(height: 14),
                    _accordionCard(
                      titleText: 'Đổi mật khẩu',
                      subtitle: 'Ẩn mặc định, chỉ mở khi cần',
                      isOpen: passwordOpen,
                      onTap: () {
                        setState(() {
                          passwordOpen = !passwordOpen;
                          if (passwordOpen) profileOpen = false;
                        });
                      },
                      child: _passwordForm(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _profileHeader() {
    final avatar = _avatarProvider();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEAF6FF),
                  backgroundImage: avatar,
                  child: avatar == null
                      ? Icon(
                          Icons.person_rounded,
                          color: AppColors.primaryBlue,
                          size: 42,
                        )
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: card, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tài khoản cá nhân',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  nameCtrl.text.trim().isEmpty
                      ? 'Người dùng NAVI'
                      : nameCtrl.text.trim(),
                  style: TextStyle(
                    color: title,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emailCtrl.text,
                  style: TextStyle(
                    color: sub,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accordionCard({
    required String titleText,
    required String subtitle,
    required bool isOpen,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOpen ? AppColors.primaryBlue.withValues(alpha: 0.6) : border,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: TextStyle(
                            color: title,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(color: sub, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: sub),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: border)),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Họ và tên'),
        const SizedBox(height: 8),
        TextField(
          controller: nameCtrl,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: title),
          decoration: _inputDecoration('Nhập họ và tên'),
        ),
        const SizedBox(height: 16),
        _label('Email'),
        const SizedBox(height: 8),
        TextField(
          controller: emailCtrl,
          readOnly: true,
          enableInteractiveSelection: false,
          style: TextStyle(color: sub),
          decoration: _inputDecoration(
            'Email tài khoản',
            locked: true,
            suffixIcon: Icons.lock_outline_rounded,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: savingProfile ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: savingProfile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Lưu thông tin',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _passwordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Mật khẩu hiện tại'),
        const SizedBox(height: 8),
        _passwordField(
          controller: currentPasswordCtrl,
          hint: 'Nhập mật khẩu hiện tại',
          hidden: hideCurrentPassword,
          onToggle: () {
            setState(() {
              hideCurrentPassword = !hideCurrentPassword;
            });
          },
        ),
        const SizedBox(height: 14),
        _label('Mật khẩu mới'),
        const SizedBox(height: 8),
        _passwordField(
          controller: newPasswordCtrl,
          hint: 'Nhập mật khẩu mới',
          hidden: hideNewPassword,
          onToggle: () {
            setState(() {
              hideNewPassword = !hideNewPassword;
            });
          },
        ),
        const SizedBox(height: 14),
        _label('Xác nhận mật khẩu mới'),
        const SizedBox(height: 8),
        _passwordField(
          controller: confirmPasswordCtrl,
          hint: 'Nhập lại mật khẩu mới',
          hidden: hideConfirmPassword,
          onToggle: () {
            setState(() {
              hideConfirmPassword = !hideConfirmPassword;
            });
          },
        ),
        if (otpSent) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã OTP đã được gửi đến email tài khoản của bạn.',
                  style: TextStyle(color: sub, height: 1.45),
                ),
                const SizedBox(height: 12),
                _label('Mã OTP'),
                const SizedBox(height: 8),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: title),
                  decoration: _inputDecoration('Nhập mã OTP 6 số').copyWith(
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: passwordLoading
                ? null
                : otpSent
                    ? _verifyPasswordOtp
                    : _requestPasswordOtp,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: passwordLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    otpSent ? 'Xác nhận đổi mật khẩu' : 'Gửi mã OTP',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ),
        if (otpSent) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: passwordLoading ? null : _requestPasswordOtp,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Gửi lại mã OTP',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: title,
        fontSize: 13.5,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      style: TextStyle(color: title),
      decoration: _inputDecoration(hint).copyWith(
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: sub,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    bool locked = false,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: locked
          ? (isDark ? const Color(0xFF172033) : const Color(0xFFF1F5F9))
          : (isDark ? const Color(0xFF101827) : Colors.white),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: sub, fontSize: 13.5),
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, color: sub),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    );
  }
}
