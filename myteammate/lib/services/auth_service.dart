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

  static Future<AuthResult> updateProfile(Map<String, dynamic> data) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return const AuthResult(success: false, error: 'Oturum bulunamadı.');

    final response = await http.put(
      Uri.parse('$_baseUrl/api/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) return const AuthResult(success: true);

    if (response.statusCode == 400) {
      final errors = (body['errors'] as List).join('\n');
      return AuthResult(success: false, error: errors);
    }

    return AuthResult(success: false, error: body['error'] as String? ?? 'Bir hata oluştu.');
  }

  static Future<AuthResult> createMatch(Map<String, dynamic> data) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return const AuthResult(success: false, error: 'Oturum bulunamadı.');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/match'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
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

  static Future<List<Map<String, dynamic>>> getFields({
    required String city,
    required String district,
  }) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return [];

    final uri = Uri.parse('$_baseUrl/api/field').replace(
      queryParameters: {'city': city, 'district': district},
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
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

  static Future<AuthResult> joinMatch(int matchId) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return const AuthResult(success: false, error: 'Oturum bulunamadı.');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/match/$matchId/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return const AuthResult(success: true);
    return AuthResult(success: false, error: body['error'] as String? ?? 'Bir hata oluştu.');
  }

  static Future<Map<String, dynamic>?> getMatchDetail(int matchId) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$_baseUrl/api/match/$matchId'),
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

  static Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_surname');
    await _storage.delete(key: 'user_id');
  }

  static Future<({List<Map<String, dynamic>> matches, String? error})> getMatches({
    String? city,
    String? district,
  }) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return (matches: <Map<String, dynamic>>[], error: 'Oturum bulunamadı.');

    final queryParams = <String, String>{};
    if (city != null) queryParams['city'] = city;
    if (district != null) queryParams['district'] = district;

    final uri = Uri.parse('$_baseUrl/api/match').replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return (matches: list.cast<Map<String, dynamic>>(), error: null);
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        matches: <Map<String, dynamic>>[],
        error: '[${response.statusCode}] ${body['error'] ?? response.body}',
      );
    } catch (e) {
      return (matches: <Map<String, dynamic>>[], error: 'Sunucuya bağlanılamadı: $e');
    }
  }
}
