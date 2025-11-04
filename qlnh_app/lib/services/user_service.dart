import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  UserService._privateConstructor();

  static final UserService instance = UserService._privateConstructor();

  /// Fetch current user profile
  /// Returns null if not authenticated or on error
  Future<User?> getCurrentUser() async {
    try {
      if (!AuthService.instance.isLoggedIn) {
        print('User not logged in');
        return null;
      }

      final uri = Uri.parse(ApiEndpoints.userProfile);
      final response = await http.get(
        uri,
        headers: AuthService.instance.authHeaders,
      );

      print('Get user profile status: ${response.statusCode}');
      print('Get user profile response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        print('Failed to fetch user profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Update current user via PATCH. Only include fields that are non-null.
  /// Returns a map: {'ok': bool, 'message': String, 'user': User?}
  Future<Map<String, dynamic>> updateCurrentUser({
    String? hoTen,
    String? email,
    String? soDienThoai,
    String? password,
  }) async {
    try {
      if (!AuthService.instance.isLoggedIn) {
        return {'ok': false, 'message': 'Người dùng chưa đăng nhập'};
      }

      final uri = Uri.parse(ApiEndpoints.userProfile);
      final Map<String, dynamic> body = {};
      if (hoTen != null) body['ho_ten'] = hoTen;
      if (email != null) body['email'] = email;
      if (soDienThoai != null) body['so_dien_thoai'] = soDienThoai;
      if (password != null && password.isNotEmpty) body['password'] = password;

      if (body.isEmpty) return {'ok': false, 'message': 'Không có dữ liệu để cập nhật'};

      final response = await http.patch(
        uri,
        headers: AuthService.instance.authHeaders,
        body: json.encode(body),
      );

      print('Update user profile status: ${response.statusCode}');
      print('Update user profile response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final user = User.fromJson(data);
        return {'ok': true, 'message': 'Cập nhật thành công', 'user': user};
      }

      // Try to decode error message
      try {
        final Map<String, dynamic> errorData = response.body.isNotEmpty ? json.decode(response.body) as Map<String, dynamic> : {};
        final err = errorData['detail'] ?? errorData['message'] ?? response.body;
        return {'ok': false, 'message': err ?? 'Cập nhật thất bại (${response.statusCode})'};
      } catch (e) {
        return {'ok': false, 'message': 'Cập nhật thất bại (${response.statusCode})'};
      }
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }
}
