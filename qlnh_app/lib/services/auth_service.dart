import 'dart:convert';

import 'package:http/http.dart' as http;
import '../constants/api.dart';

class AuthService {
  AuthService._privateConstructor();

  static final AuthService instance = AuthService._privateConstructor();

  bool _isLoggedIn = false;
  String? _accessToken;

  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;

  Map<String, String> get authHeaders => {
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  /// Attempt login with username (or email/phone) and password.
  /// Returns a map {'ok': bool, 'message': String} describing the result.
  Future<Map<String, dynamic>> loginWithApi({required String username, required String password}) async {
        print('username: $username, password: $password');
        try {
          final uri = Uri.parse(ApiEndpoints.login);

          final body = jsonEncode({
            'client_id': 'EcWinP3m6Qlf6NlRv5ISsVu87uYCxGPAOoT4dQrY',
            'client_secret': 'QYpTVUTIlGOO2S58fDyKWhPMkI2zCKEFmX4smjDx6y0CRN3zH7u9vfPmufvKMOLrvColVDeYYK0a7lTrQHffef8PtVCbXsAIN4bMw62A2oVl6sUn7vIZkCqNJRaULvvm',
            'grant_type': 'password',
            'username': username,
            'password': password,
          });

          final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          );

          print('Response status code: ${response.statusCode}');
          print('Response body: ${response.body}');

          final Map<String, dynamic> data = response.body.isNotEmpty
              ? (json.decode(response.body) as Map<String, dynamic>)
              : <String, dynamic>{};

          if (response.statusCode == 200) {
            // Expecting access_token in OAuth token response
            final token = data['access_token'] ?? data['token'] ?? data['accessToken'];
            if (token != null && token is String && token.isNotEmpty) {
              _accessToken = token;
              _isLoggedIn = true;
              return {'ok': true, 'message': 'OK'};
            }
            return {'ok': false, 'message': 'No access token in response'};
          }

          // If server returned JSON error, include it
          final errorMsg = data['error_description'] ?? data['error'] ?? response.body;
          return {'ok': false, 'message': errorMsg ?? 'Login failed (status ${response.statusCode})'};
        } catch (e) {
          return {'ok': false, 'message': e.toString()};
        }
  }

  /// Register a new user with required fields.
  /// Returns {'ok': bool, 'message': String, 'data': Map?}
  Future<Map<String, dynamic>> registerWithApi({
    required String username,
    required String password,
    required String soDienThoai,
    required String hoTen,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.register);

      final body = jsonEncode({
        'username': username,
        'password': password,
        'so_dien_thoai': soDienThoai,
        'ho_ten': hoTen,
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final Map<String, dynamic> data = response.body.isNotEmpty
          ? (json.decode(response.body) as Map<String, dynamic>)
          : <String, dynamic>{};

      if (response.statusCode == 201) {
        return {'ok': true, 'message': 'Đăng ký thành công', 'data': data};
      }

      final err = data['detail'] ?? data['error'] ?? data['message'] ?? response.body;
      return {'ok': false, 'message': err ?? 'Đăng ký thất bại (${response.statusCode})'};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  void logout() {
    _isLoggedIn = false;
    _accessToken = null;
  }
}
