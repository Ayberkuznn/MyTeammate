import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String? error;

  const AuthResult({required this.success, this.error});
}

class AuthService {
  static const String _baseUrl = 'http://10.0.2.2:3000';
  static const _storage = FlutterSecureStorage();

  static Future<AuthResult> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final user = body['user'] as Map<String, dynamic>;
      await _storage.write(key: 'access_token',  value: body['accessToken'] as String);
      await _storage.write(key: 'refresh_token', value: body['refreshToken'] as String);
      await _storage.write(key: 'user_email',    value: user['email'] as String);
      await _storage.write(key: 'user_name',     value: user['name'] as String);
      await _storage.write(key: 'user_surname',  value: user['surname'] as String);
      await _storage.write(key: 'user_id',       value: user['userId'].toString());
      return const AuthResult(success: true);
    }

    return AuthResult(success: false, error: body['error'] as String? ?? 'Giriş başarısız.');
  }

  static Future<AuthResult> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) return const AuthResult(success: true);

    if (response.statusCode == 400) {
      final errors = (body['errors'] as List).join('\n');
      return AuthResult(success: false, error: errors);
    }

    return AuthResult(success: false, error: body['error'] as String? ?? 'Bir hata oluştu.');
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$_baseUrl/api/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<AuthResult> verifyEmail(String email, String code) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) return const AuthResult(success: true);

    return AuthResult(success: false, error: body['error'] as String? ?? 'Doğrulama başarısız.');
  }
}
