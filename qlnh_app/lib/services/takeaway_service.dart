import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/takeaway_order.dart';
import 'auth_service.dart';

class TakeawayService {
  static const int timeout = 10; // seconds

  /// Tạo đơn takeaway mới
  static Future<TakeawayOrder> createTakeawayOrder({
    required List<TakeawayCartItem> cartItems,
    String? ghiChu,
  }) async {
    try {
      final authService = AuthService.instance;
      
      if (!authService.isLoggedIn || authService.accessToken == null) {
        throw Exception('Vui lòng đăng nhập để đặt món');
      }

      final orderData = {
        'ghi_chu': ghiChu ?? '',
        'mon_an_list': cartItems.map((item) => {
          'mon_an_id': item.monAnId,
          'so_luong': item.soLuong,
        }).toList(),
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.takeawayOrders),
        headers: authService.authHeaders,
        body: json.encode(orderData),
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return TakeawayOrder.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể tạo đơn hàng');
      }
    } catch (e) {
      throw Exception('Lỗi tạo đơn hàng: $e');
    }
  }

  /// Lấy danh sách đơn takeaway của khách hàng
  static Future<List<TakeawayOrder>> getMyTakeawayOrders() async {
    try {
      final authService = AuthService.instance;
      
      if (!authService.isLoggedIn || authService.accessToken == null) {
        throw Exception('Vui lòng đăng nhập để xem đơn hàng');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.takeawayOrders),
        headers: authService.authHeaders,
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => TakeawayOrder.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách đơn hàng');
      }
    } catch (e) {
      throw Exception('Lỗi tải đơn hàng: $e');
    }
  }

  /// Lấy chi tiết một đơn takeaway
  static Future<TakeawayOrder> getTakeawayOrderDetail(int orderId) async {
    try {
      final authService = AuthService.instance;
      
      if (!authService.isLoggedIn || authService.accessToken == null) {
        throw Exception('Vui lòng đăng nhập để xem chi tiết đơn hàng');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.getTakeawayOrder(orderId)),
        headers: authService.authHeaders,
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TakeawayOrder.fromJson(jsonData);
      } else {
        throw Exception('Không thể tải chi tiết đơn hàng');
      }
    } catch (e) {
      throw Exception('Lỗi tải chi tiết đơn hàng: $e');
    }
  }

  /// Hủy đơn takeaway (chỉ khi trạng thái là pending hoặc confirmed)
  static Future<TakeawayOrder> cancelTakeawayOrder(int orderId) async {
    try {
      final authService = AuthService.instance;
      
      if (!authService.isLoggedIn || authService.accessToken == null) {
        throw Exception('Vui lòng đăng nhập để hủy đơn hàng');
      }

      final response = await http.patch(
        Uri.parse('${ApiEndpoints.takeawayOrders}$orderId/cancel-order/'),
        headers: authService.authHeaders,
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TakeawayOrder.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể hủy đơn hàng');
      }
    } catch (e) {
      throw Exception('Lỗi hủy đơn hàng: $e');
    }
  }
}