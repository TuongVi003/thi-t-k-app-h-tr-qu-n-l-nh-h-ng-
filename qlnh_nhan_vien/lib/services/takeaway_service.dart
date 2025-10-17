import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/takeaway_order.dart';
import 'auth_service.dart';

class TakeawayService {
  static const int timeout = 10; // seconds

  /// Lấy danh sách tất cả đơn takeaway
  static Future<List<TakeawayOrder>> getTakeawayOrders() async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.takeawayOrders),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('DEBUG: Raw API response: $jsonData'); // Debug log
        return jsonData.map((json) {
          print('DEBUG: Processing order JSON: $json'); // Debug log
          return TakeawayOrder.fromJson(json);
        }).toList();
      } else {
        throw Exception('Failed to load takeaway orders: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getTakeawayOrders: $e'); // Debug log
      throw Exception('Error fetching takeaway orders: $e');
    }
  }

  /// Nhân viên nhận đơn
  static Future<TakeawayOrder> acceptOrder(int orderId) async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.patch(
        Uri.parse(ApiEndpoints.acceptTakeawayOrder(orderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        // Gọi lại API GET để lấy order đầy đủ sau khi accept
        return await getTakeawayOrderById(orderId);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to accept order');
      }
    } catch (e) {
      throw Exception('Error accepting order: $e');
    }
  }

  /// Xác nhận thời gian lấy món
  ///
  /// If [thoiGianLay] is null, the API will receive `thoi_gian_lay: null` which
  /// indicates starting the cooking process without setting an explicit pickup time.
  static Future<TakeawayOrder> confirmTime(int orderId, int? thoiGianLay) async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.patch(
        Uri.parse(ApiEndpoints.confirmTakeawayTime(orderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
        body: json.encode({
          'thoi_gian_lay': thoiGianLay,
        }),
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        // Gọi lại API GET để lấy order đầy đủ sau khi confirm time
        return await getTakeawayOrderById(orderId);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to confirm time');
      }
    } catch (e) {
      throw Exception('Error confirming time: $e');
    }
  }

  /// Cập nhật trạng thái đơn hàng
  static Future<TakeawayOrder> updateStatus(int orderId, TakeawayOrderStatus status) async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.patch(
        Uri.parse(ApiEndpoints.updateTakeawayStatus(orderId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
        body: json.encode({
          'trang_thai': status.value,
        }),
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        // API chỉ trả về { trang_thai, thoi_gian_lay, ghi_chu }
        // Gọi lại API GET để lấy order đầy đủ
        return await getTakeawayOrderById(orderId);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update status');
      }
    } catch (e) {
      print('DEBUG: Error in updateStatus - takeaway_service.dart: $e');
      throw Exception('$e');
    }
  }

  /// Lấy chi tiết một đơn takeaway theo ID
  static Future<TakeawayOrder> getTakeawayOrderById(int orderId) async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.get(
        Uri.parse('${ApiEndpoints.takeawayOrders}$orderId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TakeawayOrder.fromJson(jsonData);
      } else {
        throw Exception('Failed to load order detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching order detail: $e');
    }
  }

  /// Check-in ca làm việc
  static Future<Map<String, dynamic>> checkIn() async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.checkIn),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to check in');
      }
    } catch (e) {
      throw Exception('Error checking in: $e');
    }
  }

  /// Check-out ca làm việc
  static Future<Map<String, dynamic>> checkOut() async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.checkOut),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to check out');
      }
    } catch (e) {
      throw Exception('Error checking out: $e');
    }
  }

  /// Nhân viên tạo đơn mang về cho khách
  static Future<TakeawayOrder> staffCreateOrder({
    int? khachHangId,
    String? khachHoTen,
    String? khachSoDienThoai,
    required List<Map<String, dynamic>> monAnList,
    String? ghiChu,
    DateTime? thoiGianKhachLay,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      // Validate input
      if (khachHangId == null && (khachHoTen == null || khachSoDienThoai == null)) {
        throw Exception('Vui lòng cung cấp thông tin khách hàng');
      }

      final Map<String, dynamic> body = {
        'mon_an_list': monAnList,
      };

      if (khachHangId != null) {
        body['khach_hang_id'] = khachHangId;
      } else {
        body['khach_ho_ten'] = khachHoTen;
        body['khach_so_dien_thoai'] = khachSoDienThoai;
      }

      if (ghiChu != null && ghiChu.isNotEmpty) {
        body['ghi_chu'] = ghiChu;
      }

      if (thoiGianKhachLay != null) {
        body['thoi_gian_khach_lay'] = thoiGianKhachLay.toIso8601String();
      }

      print('📦 Creating staff takeaway order: $body');

      final response = await http.post(
        Uri.parse(ApiEndpoints.staffCreateTakeaway),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: timeout));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TakeawayOrder.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        if (errorData['non_field_errors'] != null) {
          throw Exception(errorData['non_field_errors'][0]);
        }
        if (errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating staff takeaway order: $e');
      throw Exception('Lỗi tạo đơn: $e');
    }
  }
}