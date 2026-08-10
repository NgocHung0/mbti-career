import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool loading = false;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bg => isDark ? Color(0xFF000000) : Colors.white;
  Color get card => isDark ? Color(0xFF111111) : Colors.white;
  Color get title => isDark ? Color(0xFFEAF6FF) : Color(0xFF1F3D5A);
  Color get sub => isDark ? Color(0xFF94A3B8) : Color(0xFF8A9AAD);
  Color get border => isDark ? Color(0xFF2A2A2A) : Color(0xFFD7E4F2);

  Future<void> register() async {
    if (nameCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passwordCtrl.text.isEmpty ||
        confirmCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    if (passwordCtrl.text != confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await AuthService.register(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        passwordConfirmation: confirmCtrl.text,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, 10, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: title,
                  size: 30,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: title,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Đăng ký để lưu lịch sử làm bài và kết quả MBTI',
                          style: TextStyle(
                            fontSize: 11.8,
                            height: 1.35,
                            color: sub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/logo/logonavi.png',
                    width: 86,
                    height: 86,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.24)
                          : Color(0xFF8EC5FC).withValues(alpha: 0.13),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldLabel(Icons.person_rounded, 'Họ tên'),
                    SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: title),
                      decoration: inputDecoration('Nhập họ tên'),
                    ),
                    SizedBox(height: 10),
                    fieldLabel(Icons.email_rounded, 'Email'),
                    SizedBox(height: 6),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: title),
                      decoration: inputDecoration('you@gmail.com'),
                    ),
                    SizedBox(height: 10),
                    fieldLabel(Icons.lock_rounded, 'Mật khẩu'),
                    SizedBox(height: 6),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: hidePassword,
                      style: TextStyle(color: title),
                      decoration: inputDecoration(
                        'Nhập mật khẩu',
                        suffix: IconButton(
                          onPressed: () {
                            setState(() => hidePassword = !hidePassword);
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: sub,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    fieldLabel(Icons.lock_reset_rounded, 'Xác nhận mật khẩu'),
                    SizedBox(height: 6),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: hideConfirmPassword,
                      style: TextStyle(color: title),
                      decoration: inputDecoration(
                        'Nhập lại mật khẩu',
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              hideConfirmPassword = !hideConfirmPassword;
                            });
                          },
                          icon: Icon(
                            hideConfirmPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: sub,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mật khẩu nên có ít nhất 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: sub,
                      ),
                    ),
                    SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: loading ? null : register,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Color(0xFF2F80ED),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Color(0xFFE1EDF7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: loading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Đăng ký',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 13.2,
                        color: sub,
                      ),
                      children: [
                        TextSpan(text: 'Đã có tài khoản? '),
                        TextSpan(
                          text: 'Đăng nhập',
                          style: TextStyle(
                            color: Color(0xFF2F80ED),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget fieldLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF2F80ED), size: 18),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: title,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  InputDecoration inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? Color(0xFF000000) : Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      hintStyle: TextStyle(
        color: isDark ? Color(0xFF64748B) : Color(0xFFB8C6D3),
        fontSize: 13,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: border,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Color(0xFF2F80ED),
          width: 1.5,
        ),
      ),
    );
  }
}
