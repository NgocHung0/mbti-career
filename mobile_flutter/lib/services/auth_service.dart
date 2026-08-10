import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
  static const String _hasLoggedInBeforeKey = 'has_logged_in_before';

  static final ValueNotifier<int> authVersion = ValueNotifier<int>(0);

  static void notifyAuthChanged() {
    authVersion.value++;
  }

  static String? resolveAvatarUrl(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();

    if (raw.isEmpty || raw == 'null') return null;

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final origin = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    if (raw.startsWith('/storage/')) {
      return '$origin$raw';
    }

    if (raw.startsWith('storage/')) {
      return '$origin/$raw';
    }

    if (raw.startsWith('/')) {
      return '$origin$raw';
    }

    if (raw.startsWith('avatars/')) {
      return '$origin/storage/$raw';
    }

    return '$origin/storage/$raw';
  }

  static String? extractAvatarUrl(Map<String, dynamic>? data) {
    if (data == null) return null;

    final user = data['user'];

    final raw = data['avatar_url'] ??
        data['avatar'] ??
        (user is Map ? user['avatar_url'] : null) ??
        (user is Map ? user['avatar'] : null) ??
        (user is Map ? user['profile_photo_url'] : null);

    return resolveAvatarUrl(raw);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {'Accept': 'application/json'},
          body: {'email': email, 'password': password},
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Đăng nhập thất bại');
    }

    await saveAuthData(data);

    if (remember) {
      await saveRememberedAccount(email: email, password: password);
    } else {
      await clearRememberedAccount();
    }

    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/register'),
          headers: {'Accept': 'application/json'},
          body: {
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': passwordConfirmation,
          },
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Đăng ký thất bại');
    }

    await saveAuthData(data);

    return data;
  }

  static Future<void> saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final user = data['user'];

    await prefs.setString('token', data['token'] ?? '');
    await prefs.setString(
      'user_name',
      user is Map ? (user['name']?.toString() ?? '') : '',
    );
    await prefs.setString(
      'user_email',
      user is Map ? (user['email']?.toString() ?? '') : '',
    );

    final avatarUrl = extractAvatarUrl(data);
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await prefs.setString('user_avatar_url', avatarUrl);
    } else {
      await prefs.remove('user_avatar_url');
    }

    await prefs.setBool(_hasLoggedInBeforeKey, true);
    notifyAuthChanged();
  }

  static Future<bool> hasLoggedInBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasLoggedInBeforeKey) ?? false;
  }

  static Future<bool> shouldSkipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    final hasLoggedInBefore = prefs.getBool(_hasLoggedInBeforeKey) ?? false;
    final token = prefs.getString('token') ?? '';
    final remember = prefs.getBool('remember_account') ?? false;
    final savedEmail = prefs.getString('saved_email') ?? '';

    final shouldSkip =
        hasLoggedInBefore || token.isNotEmpty || (remember && savedEmail.isNotEmpty);

    if (shouldSkip && !hasLoggedInBefore) {
      await prefs.setBool(_hasLoggedInBeforeKey, true);
    }

    return shouldSkip;
  }

  static Future<void> resetLoggedInBeforeForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasLoggedInBeforeKey);
  }

  static Future<void> saveRememberedAccount({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('remember_account', true);
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }

  static Future<Map<String, dynamic>> getRememberedAccount() async {
    final prefs = await SharedPreferences.getInstance();

    final remember = prefs.getBool('remember_account') ?? false;

    return {
      'remember': remember,
      'email': remember ? (prefs.getString('saved_email') ?? '') : '',
      'password': remember ? (prefs.getString('saved_password') ?? '') : '',
    };
  }

  static Future<void> clearRememberedAccount() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('remember_account');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, String>> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'name': prefs.getString('user_name') ?? 'Khách',
      'email': prefs.getString('user_email') ?? 'Bạn chưa đăng nhập',
      'avatar_url': prefs.getString('user_avatar_url') ?? '',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_avatar_url');

    notifyAuthChanged();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập lại.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/change-password'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: {
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': confirmPassword,
          },
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Đổi mật khẩu thất bại');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? avatarPath,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập lại.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/update'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['name'] = name;

    if (avatarPath != null && avatarPath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('avatar', avatarPath),
      );
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 15),
    );

    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Cập nhật hồ sơ thất bại');
    }

    final prefs = await SharedPreferences.getInstance();

    final user = data['user'];

    await prefs.setString(
      'user_name',
      user is Map ? (user['name']?.toString() ?? '') : '',
    );
    await prefs.setString(
      'user_email',
      user is Map ? (user['email']?.toString() ?? '') : '',
    );

    final avatarUrl = extractAvatarUrl(data);
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await prefs.setString('user_avatar_url', avatarUrl);
    } else {
      await prefs.remove('user_avatar_url');
    }

    return data;
  }


  static Future<String> requestPasswordOtp({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập lại.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/change-password/request-otp'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
            'new_password_confirmation': confirmPassword,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeJsonMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message'] ??
            _firstValidationMessage(data) ??
            'Không gửi được mã OTP.',
      );
    }

    return data['message']?.toString() ??
        'Mã OTP đã được gửi về email của bạn.';
  }

  static Future<String> verifyPasswordOtp({
    required String otp,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập lại.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/change-password/verify-otp'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'otp': otp}),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeJsonMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message'] ??
            _firstValidationMessage(data) ??
            'Xác nhận OTP thất bại.',
      );
    }

    return data['message']?.toString() ?? 'Đổi mật khẩu thành công.';
  }

  static Map<String, dynamic> _decodeJsonMap(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String? _firstValidationMessage(Map<String, dynamic> data) {
    final errors = data['errors'];

    if (errors is! Map) return null;

    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }

      if (value != null) {
        return value.toString();
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>> getProfileSummary() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Bạn cần đăng nhập lại.');
    }

    final meResponse = await http
        .get(
          Uri.parse('$baseUrl/me'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    final meData = jsonDecode(meResponse.body);

    if (meResponse.statusCode != 200) {
      throw Exception(meData['message'] ?? 'Không thể tải hồ sơ.');
    }

    Map<String, dynamic>? mbtiData;

    try {
      final mbtiResponse = await http
          .get(
            Uri.parse('$baseUrl/mbti-results/latest'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (mbtiResponse.statusCode == 200) {
        mbtiData = jsonDecode(mbtiResponse.body);
      }
    } catch (_) {
      mbtiData = null;
    }

    final prefs = await SharedPreferences.getInstance();
    final user = meData['user'];

    if (user is Map) {
      await prefs.setString('user_name', user['name']?.toString() ?? '');
      await prefs.setString('user_email', user['email']?.toString() ?? '');

      final avatarUrl = extractAvatarUrl(meData);
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await prefs.setString('user_avatar_url', avatarUrl);
      } else {
        await prefs.remove('user_avatar_url');
      }
    }

    return {
      'user': meData['user'],
      'package': meData['package'],
      'mbti': mbtiData,
    };
  }
}
