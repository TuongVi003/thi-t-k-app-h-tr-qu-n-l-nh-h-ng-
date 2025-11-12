import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/notification.dart';
import 'auth_service.dart';

class NotificationApiService {
  NotificationApiService._privateConstructor();

  static final NotificationApiService instance =
      NotificationApiService._privateConstructor();

  /// Get all notifications for the current user
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final accessToken = AuthService.instance.accessToken;
      if (accessToken == null) {
        return {
          'ok': false,
          'message': 'Bạn cần đăng nhập để xem thông báo',
        };
      }

      final uri = Uri.parse(ApiEndpoints.notifications);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Notifications response status: ${response.statusCode}');
      print('Notifications response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final notifications = data
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        return {
          'ok': true,
          'message': 'Success',
          'data': notifications,
        };
      } else {
        return {
          'ok': false,
          'message': 'Không thể tải thông báo (${response.statusCode})',
        };
      }
    } catch (e) {
      print('Error getting notifications: $e');
      return {
        'ok': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }
}
