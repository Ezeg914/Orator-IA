import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// URL base del backend (IP de la PC en la red local)
const String apiBaseUrl = 'http://192.168.1.45:5000/api';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _usernameKey = 'username';

  static String? _token;
  static String? _username;

  static bool get isLoggedIn => _token != null;
  static String get username => _username ?? '';

  static Map<String, String> get authHeaders => {'Authorization': 'Bearer $_token'};

  // Cargar la sesión guardada al iniciar la app
  static Future<void> init() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      _username = await _storage.read(key: _usernameKey);
    } catch (e) {
      print("Error reading saved session: ${e}");
      _token = null;
      _username = null;
    }
  }

  static Future<void> login(String email, String password) async {
    await _authenticate('/auth/login', {'email': email, 'password': password});
  }

  static Future<void> register(String username, String email, String password) async {
    await _authenticate('/auth/register', {'username': username, 'email': email, 'password': password});
  }

  static Future<void> logout() async {
    _token = null;
    _username = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }

  static Future<void> _authenticate(String path, Map<String, String> body) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$apiBaseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AuthException('Could not connect to the server');
    }

    final dynamic data;
    try {
      data = json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw AuthException('Unexpected server response (${response.statusCode})');
    }

    if (response.statusCode != 200) {
      throw AuthException(_errorMessage(data, response.statusCode));
    }

    _token = data['access_token'];
    _username = data['user']['username'];
    await _storage.write(key: _tokenKey, value: _token);
    await _storage.write(key: _usernameKey, value: _username);
  }

  // FastAPI devuelve "detail" como texto o como lista de errores de validación
  static String _errorMessage(dynamic data, int statusCode) {
    final detail = data is Map ? data['detail'] : null;
    if (detail is String) {
      return detail;
    }
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final field = (detail.first['loc'] as List?)?.last;
      final msg = detail.first['msg'];
      return field != null ? '$field: $msg' : '$msg';
    }
    return 'Request failed ($statusCode)';
  }
}
