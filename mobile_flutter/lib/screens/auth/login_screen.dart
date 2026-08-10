import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../../core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool hidePassword = true;
  bool loading = false;
  bool remember = true;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadRememberedAccount();
  }

  Future<void> loadRememberedAccount() async {
    final saved = await AuthService.getRememberedAccount();

    if (!mounted) return;

    setState(() {
      remember = saved['remember'] == true;
      emailCtrl.text = saved['email'] ?? '';
      passwordCtrl.text = saved['password'] ?? '';
    });
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bg => isDark ? Color(0xFF000000) : Colors.white;
  Color get card => isDark ? Color(0xFF111111) : Colors.white;
  Color get title => isDark ? Color(0xFFEAF6FF) : Color(0xFF1F3D5A);
  Color get sub => isDark ? Color(0xFF94A3B8) : Color(0xFF8A9AAD);
  Color get border =>
      isDark ? Color(0xFF2A2A2A) : Color(0xFFD7E4F2);

  Future<void> login() async {
    if (emailCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await AuthService.login(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        remember: remember,
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
                icon: Icon(Icons.arrow_back_rounded, color: title, size: 30),
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NAVI',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Color(0xFF2F80ED),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Chào mừng trở lại 👋',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: sub,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: title,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Nhập thông tin tài khoản để tiếp tục sử dụng NAVI',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: sub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Image.asset(
                    'assets/logo/logonavi.png',
                    width: 108,
                    height: 108,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(15, 16, 15, 16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.24)
                          : Color(0xFF8EC5FC).withValues(alpha: 0.13),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldLabel(Icons.email_rounded, 'Email'),
                    SizedBox(height: 7),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: title),
                      decoration: inputDecoration(
                        'you@gmail.com',
                        suffix: Icon(Icons.mail_outline_rounded, color: sub),
                      ),
                    ),
                    SizedBox(height: 13),
                    fieldLabel(Icons.lock_rounded, 'Mật khẩu'),
                    SizedBox(height: 7),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: hidePassword,
                      style: TextStyle(color: title),
                      decoration: inputDecoration(
                        'Nhập mật khẩu',
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
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
                    SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Checkbox(
                            value: remember,
                            activeColor: Color(0xFF2F80ED),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            onChanged: (value) {
                              setState(() {
                                remember = value ?? false;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ghi nhớ',
                            style: TextStyle(
                              color: sub,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tính năng quên mật khẩu sẽ làm sau.',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              color: Color(0xFF2F80ED),
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: loading ? null : login,
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    );

                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 13.5, color: sub),
                      children: [
                        TextSpan(text: 'Chưa có tài khoản? '),
                        TextSpan(
                          text: 'Đăng ký ngay',
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
        Icon(Icons.circle, color: Colors.transparent, size: 0),
        Icon(icon, color: Color(0xFF2F80ED), size: 19),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: title,
            fontSize: 13.5,
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
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(
        color: isDark ? Color(0xFF64748B) : Color(0xFFB8C6D3),
        fontSize: 13.5,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Color(0xFF2F80ED), width: 1.5),
      ),
    );
  }
}
