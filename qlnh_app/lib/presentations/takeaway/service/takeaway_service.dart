import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../../constants/api.dart';
import '../../../models/takeaway_order.dart';
import '../../../services/auth_service.dart';

class TakeawayService {
  static const int timeout = 30; // seconds

  /// Tạo đơn takeaway mới
  static Future<TakeawayOrder> createTakeawayOrder({
    required List<TakeawayCartItem> cartItems,
    DateTime? ngay,
    String? ghiChu,
    String? phuongThucGiaoHang,
    String? diaChiGiaoHang,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final authService = AuthService.instance;

      if (!authService.isLoggedIn || authService.accessToken == null) {
        throw Exception('Vui lòng đăng nhập để đặt món');
      }

      // Round coordinates to reduce total digits and avoid backend validation errors
      double? roundedLatitude = latitude == null
          ? null
          : double.parse(latitude.toStringAsFixed(6));
      double? roundedLongitude = longitude == null
          ? null
          : double.parse(longitude.toStringAsFixed(6));

      final orderData = {
        'ghi_chu': ghiChu ?? '',
        'mon_an_list': cartItems
            .map(
              (item) => {
                'mon_an_id': item.monAnId,
                'so_luong': item.soLuong,
              },
            )
            .toList(),
        if (phuongThucGiaoHang != null) 'phuong_thuc_giao_hang': phuongThucGiaoHang,
        if (diaChiGiaoHang != null && diaChiGiaoHang.isNotEmpty) 'dia_chi_giao_hang': diaChiGiaoHang,
        if (roundedLatitude != null) 'latitude': roundedLatitude,
        if (roundedLongitude != null) 'longitude': roundedLongitude,
        if (ngay != null) 'thoi_gian_khach_lay': ngay.toIso8601String(),
      };
      print('Thoi gian khach lay: ${ngay?.toIso8601String()}');

      final response = await http
          .post(
            Uri.parse(ApiEndpoints.takeawayOrders),
            headers: authService.authHeaders,
            body: json.encode(orderData),
          )
          .timeout(const Duration(seconds: timeout));

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('Thành công: $jsonData');
        return TakeawayOrder.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        print('Thất bại: $errorData');
        throw Exception(errorData['error'] ?? 'Không thể tạo đơn hàng');
      }
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Yêu cầu tạo đơn vượt quá thời gian chờ (${timeout}s). Vui lòng thử lại.');
      }
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

      final response = await http
          .get(
            Uri.parse(ApiEndpoints.takeawayOrders),
            headers: authService.authHeaders,
          )
          .timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => TakeawayOrder.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách đơn hàng');
      }
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Yêu cầu tải danh sách đơn vượt quá thời gian chờ (${timeout}s). Vui lòng thử lại.');
      }
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

      final response = await http
          .get(
            Uri.parse(ApiEndpoints.getTakeawayOrder(orderId)),
            headers: authService.authHeaders,
          )
          .timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TakeawayOrder.fromJson(jsonData);
      } else {
        throw Exception('Không thể tải chi tiết đơn hàng');
      }
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Yêu cầu tải chi tiết đơn vượt quá thời gian chờ (${timeout}s). Vui lòng thử lại.');
      }
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

      final response = await http
          .patch(
            Uri.parse('${ApiEndpoints.takeawayOrders}$orderId/cancel-order/'),
            headers: authService.authHeaders,
          )
          .timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TakeawayOrder.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Không thể hủy đơn hàng');
      }
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Yêu cầu hủy đơn vượt quá thời gian chờ (${timeout}s). Vui lòng thử lại.');
      }
      throw Exception('Lỗi hủy đơn hàng: $e');
    }
  }
}
