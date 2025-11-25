import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';
import 'chat_service.dart';
import 'user_service.dart';

class AuthService {
  AuthService._privateConstructor();

  static final AuthService instance = AuthService._privateConstructor();

  static const String _keyAccessToken = 'access_token';
  static const String _keyIsLoggedIn = 'is_logged_in';

  bool _isLoggedIn = false;
  String? _accessToken;
  bool _initialized = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get accessToken => _accessToken;

  Map<String, String> get authHeaders => {
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  /// Initialize and load saved session
  Future<void> initialize() async {
    if (_initialized) return;
    
    print('[AuthService] 🔄 Initializing...');
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_keyAccessToken);
      _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      
      if (_isLoggedIn && _accessToken != null) {
        print('[AuthService] ✅ Session restored - User is logged in');
        print('[AuthService] 🔑 Token: ${_accessToken!.substring(0, 20)}...');
      } else {
        print('[AuthService] ℹ️ No saved session found');
      }
      
      _initialized = true;
    } catch (e) {
      print('[AuthService] ❌ Error loading session: $e');
      _initialized = true;
    }
  }

  /// Save session to persistent storage
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString(_keyAccessToken, _accessToken!);
        await prefs.setBool(_keyIsLoggedIn, _isLoggedIn);
        print('[AuthService] 💾 Session saved');
      }
    } catch (e) {
      print('[AuthService] ❌ Error saving session: $e');
    }
  }

  /// Clear saved session
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyIsLoggedIn);
      print('[AuthService] 🗑️ Session cleared');
    } catch (e) {
      print('[AuthService] ❌ Error clearing session: $e');
    }
  }

  /// Call backend to cleanup socket sessions (CRITICAL for logout)
  Future<void> _cleanupSocketSessions() async {
    if (_accessToken == null) {
      print('[AuthService] No token, skipping socket cleanup');
      return;
    }

    try {
      print('[AuthService] 🧹 Calling backend to cleanup socket sessions...');
      final uri = Uri.parse(ApiEndpoints.cleanupSocket);
      final response = await http.post(
        uri,
        headers: authHeaders,
      );

      print('[AuthService] Socket cleanup response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('[AuthService] ✅ Backend cleaned up socket sessions');
      } else {
        print('[AuthService] ⚠️ Backend cleanup returned: ${response.statusCode}');
      }
    } catch (e) {
      print('[AuthService] ⚠️ Error cleaning socket sessions: $e');
      // Don't fail logout if this fails
    }
  }

  /// Attempt login with username (or email/phone) and password.
  /// Returns a map {'ok': bool, 'message': String} describing the result.
  Future<Map<String, dynamic>> loginWithApi(
      {required String username, required String password}) async {
    print('[AuthService] 🔐 Login attempt for: $username');
    
    // CRITICAL 1: Cleanup backend socket sessions (if any old sessions exist)
    await _cleanupSocketSessions();
    
    // CRITICAL 2: Clear any existing session
    _accessToken = null;
    _isLoggedIn = false;
    
    // CRITICAL 3: Disconnect old socket connection BEFORE logging in
    // This ensures clean state and prevents user_id mixup
    print('[AuthService] 🧹 Cleaning up old socket connection...');
    await ChatService.instance.disconnect();
    
    // CRITICAL 4: Wait a bit longer for complete cleanup
    await Future.delayed(const Duration(milliseconds: 800));
    print('[AuthService] ✅ Old connection cleaned, proceeding with login...');

    print('username: $username, password: $password');
    try {
      final uri = Uri.parse(ApiEndpoints.login);

      final body = jsonEncode({
        'client_id': 'EcWinP3m6Qlf6NlRv5ISsVu87uYCxGPAOoT4dQrY',
        'client_secret':
            'QYpTVUTIlGOO2S58fDyKWhPMkI2zCKEFmX4smjDx6y0CRN3zH7u9vfPmufvKMOLrvColVDeYYK0a7lTrQHffef8PtVCbXsAIN4bMw62A2oVl6sUn7vIZkCqNJRaULvvm',
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
        final token =
            data['access_token'] ?? data['token'] ?? data['accessToken'];
        if (token != null && token is String && token.isNotEmpty) {
          print('[AuthService] ✅ Login successful, access token: ${token.substring(0, 20)}...');
          _accessToken = token;
          _isLoggedIn = true;
          // Save session to persistent storage
          await _saveSession();
          // Register FCM token after successful login
          registerFcmToken();
          
          // ⭐ CRITICAL: Connect socket after successful login
          print('[AuthService] 🔌 Connecting chat socket after login...');
          try {
            // Get user info to get user ID
            final user = await UserService.instance.getCurrentUser();
            if (user != null) {
              print('[AuthService] 📞 Connecting socket for user ${user.id}');
              await ChatService.instance.connect(user.id);
              print('[AuthService] ✅ Socket connected successfully');
            } else {
              print('[AuthService] ⚠️ Could not get user info, socket not connected');
            }
          } catch (e) {
            print('[AuthService] ⚠️ Error connecting socket: $e');
            // Don\'t fail login if socket connection fails
          }
          
          return {'ok': true, 'message': 'OK'};
        }
        // Login failed - ensure state is cleared
        _accessToken = null;
        _isLoggedIn = false;
        return {'ok': false, 'message': 'No access token in response'};
      }

      // If server returned JSON error, include it
      // Ensure state is cleared on failure
      _accessToken = null;
      _isLoggedIn = false;
      final errorMsg = data['error_description'] ?? data['error'] ?? response.body;
      if (errorMsg != null && errorMsg.contains("Invalid credentials given")) {
        return {'ok': false, 'message': 'Sai tên đăng nhập hoặc mật khẩu'};
      }
      return {
        'ok': false,
        'message': errorMsg ?? 'Login failed (status ${response.statusCode})'
      };
    } catch (e) {
      // Ensure state is cleared on error
      _accessToken = null;
      _isLoggedIn = false;
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
    required String email,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.register);

      final body = jsonEncode({
        'username': username,
        'password': password,
        'so_dien_thoai': soDienThoai,
        'ho_ten': hoTen,
        'email': email,
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

      final err =
          data['detail'] ?? data['error'] ?? data['message'] ?? response.body;
      return {
        'ok': false,
        'message': err ?? 'Đăng ký thất bại (${response.statusCode})'
      };
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    print('[AuthService] 🚪 Logging out...');
    
    // CRITICAL 1: Call backend to cleanup socket sessions FIRST
    await _cleanupSocketSessions();
    
    // CRITICAL 2: Disconnect socket and WAIT for it
    print('[AuthService] 🧹 Disconnecting socket...');
    await ChatService.instance.disconnect();
    print('[AuthService] ✅ Socket disconnected');
    
    // CRITICAL 3: Clear auth state
    _isLoggedIn = false;
    _accessToken = null;
    
    // CRITICAL 4: Clear saved session
    await _clearSession();
    
    // CRITICAL 5: Wait a bit to ensure backend processed cleanup
    await Future.delayed(const Duration(milliseconds: 500));
    
    print('[AuthService] ✅ Logout complete');
  }

  /// Register FCM token to backend
  Future<void> registerFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print('FCM token is null, cannot register');
        return;
      }

      if (_accessToken == null) {
        print('Access token is null, cannot register FCM token');
        return;
      }

      print('Registering FCM token with access token: $_accessToken');
      print('FCM Token: $fcmToken');

      final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/fcm-token/');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      };

      final body = jsonEncode({
        'token': fcmToken,
      });

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      print('FCM token registration response status: ${response.statusCode}');
      print('FCM token registration response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('FCM token registered successfully');
      } else {
        print(
            'Failed to register FCM token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }
}
