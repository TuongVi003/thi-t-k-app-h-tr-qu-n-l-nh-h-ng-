import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';
import '../models/auth.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const int timeout = 10;
  
  // Memory cache fallback for SharedPreferences issues
  static AuthToken? _cachedToken;
  static User? _cachedUser;

  // Đăng nhập với username/password
  static Future<AuthToken> login(String username, String password) async {
    try {
      final loginRequest = LoginRequest(
        username: username,
        password: password,
        clientId: OAuth2Config.clientId,
        clientSecret: OAuth2Config.clientSecret,
      );

      print('Sending login request to: ${ApiEndpoints.login}');
      print('Login data: ${jsonEncode(loginRequest.toFormData())}');
      
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(loginRequest.toFormData()),
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Get: $data');
        final token = AuthToken.fromJson(data);
        print('Token: ${token.accessToken}');;
        
        // Lưu token vào storage
        await _saveToken(token);
        
        // Fetch user profile sau khi login thành công
        try {
          await _fetchAndSaveUserProfile(token);
        } catch (e) {
          print('Warning: Could not fetch user profile: $e');
          // Không throw lỗi ở đây, vì login đã thành công
        }
        
        return token;
      } else {
        final errorData = json.decode(response.body);
        print('Error during login: $errorData');
        throw Exception('Sai thông tin đăng nhập');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Kết nối timeout. Vui lòng thử lại.');
      }
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  // Refresh token
  static Future<AuthToken> refreshAccessToken() async {
    try {
      final currentToken = await getStoredToken();
      if (currentToken == null) {
        throw Exception('Không có refresh token');
      }

      final refreshRequest = RefreshTokenRequest(
        refreshToken: currentToken.refreshToken,
        clientId: OAuth2Config.clientId,
        clientSecret: OAuth2Config.clientSecret,
      );

      final response = await http.post(
        Uri.parse(ApiEndpoints.refreshToken),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: refreshRequest.toFormData(),
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = AuthToken.fromJson(data);
        
        // Lưu token mới
        await _saveToken(newToken);
        
        return newToken;
      } else {
        // Refresh token hết hạn, cần login lại
        await logout();
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }
    } catch (e) {
      throw Exception('Lỗi refresh token: $e');
    }
  }

  // Đăng xuất
  static Future<void> logout() async {
    try {
      final token = await getStoredToken();
      if (token != null) {
        // Revoke token trên server
        await http.post(
          Uri.parse(ApiEndpoints.revokeToken),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token.authorizationHeader,
          },
          body: jsonEncode({
            'token': token.accessToken,
            'client_id': OAuth2Config.clientId,
            'client_secret': OAuth2Config.clientSecret,
          }),
        ).timeout(const Duration(seconds: timeout));
      }
    } catch (e) {
      print('Error revoking token: $e');
    } finally {
      // Xóa dữ liệu local
      await _clearStoredData();
    }
  }

  // Lấy token từ storage
  static Future<AuthToken?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenJson = prefs.getString(_tokenKey);
      if (tokenJson != null) {
        final tokenData = json.decode(tokenJson);
        return AuthToken.fromJson(tokenData);
      }
      return null;
    } catch (e) {
      print('SharedPreferences error: $e. Using memory cache fallback.');
      return _cachedToken;
    }
  }

  // Lấy user data từ storage
  static Future<User?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userData = json.decode(userJson);
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('SharedPreferences error: $e. Using memory cache fallback.');
      return _cachedUser;
    }
  }

  // Kiểm tra user có phải nhân viên không
  static Future<bool> isStaffUser() async {
    final user = await getStoredUser();
    print('Checking staff status for user: ${user?.toJson()}');
    return user?.loaiNguoiDung == 'nhan_vien';
  }

  // Kiểm tra trạng thái đăng nhập
  static Future<bool> isLoggedIn() async {
    final token = await getStoredToken();
    if (token == null) return false;
    
    if (token.isExpired) {
      try {
        // Thử refresh token
        await refreshAccessToken();
        return true;
      } catch (e) {
        return false;
      }
    }
    
    return true;
  }

  // Lấy valid token (auto refresh nếu cần)
  static Future<AuthToken?> getValidToken() async {
    final token = await getStoredToken();
    if (token == null) return null;
    
    if (token.isExpiringSoon || token.isExpired) {
      try {
        return await refreshAccessToken();
      } catch (e) {
        return null;
      }
    }
    
    return token;
  }

  // Private methods
  static Future<void> _saveToken(AuthToken token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, json.encode(token.toJson()));
      print('Token saved to SharedPreferences successfully');
    } catch (e) {
      print('SharedPreferences error: $e. Using memory cache fallback.');
      _cachedToken = token;
      print('Token saved to memory cache successfully');
    }
  }

  static Future<void> _fetchAndSaveUserProfile(AuthToken token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.userProfile),
        headers: {
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));
      print('Get hereeeeeeeeeeeeeeeeeeeeeeeeeeeeeê 2222');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final user = User.fromJson(userData);
        print('Fetched user profile: $userData');
        
        // Lưu user data
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, json.encode(user.toJson()));
          print('User data saved to SharedPreferences successfully');
        } catch (e) {
          print('SharedPreferences error: $e. Using memory cache fallback.');
          _cachedUser = user;
          print('User data saved to memory cache successfully');
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  static Future<void> _clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      print('Data cleared from SharedPreferences successfully');
    } catch (e) {
      print('SharedPreferences error: $e. Clearing memory cache.');
    }
    
    // Always clear memory cache
    _cachedToken = null;
    _cachedUser = null;
    print('Memory cache cleared successfully');
  }
}