import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/api.dart';
import '../../../services/auth_service.dart';
import '../models/dine_in_order.dart';

class DineInOrderService {
  static String get baseUrl => '${ApiEndpoints.baseUrl}/api/dine-in';

  // Lấy token từ AuthService
  Future<String?> _getToken() async {
    final token = await AuthService.getValidToken();
    return token?.authorizationHeader;
  }

  // Lấy danh sách đơn dine-in
  Future<List<DineInOrder>> getDineInOrders() async {
    try {
      print('📋 [DineInOrderService] Đang lấy danh sách đơn hàng...');
      final token = await _getToken();
      if (token == null) {
        print('❌ [DineInOrderService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🔑 [DineInOrderService] Token: ${token.substring(0, 20)}...');
      print('🌐 [DineInOrderService] URL: $baseUrl/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      print('📡 [DineInOrderService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [DineInOrderService] Lấy được ${data.length} đơn hàng');
        return data.map((json) => DineInOrder.fromJson(json)).toList();
      } else {
        print('❌ [DineInOrderService] Lỗi ${response.statusCode}: ${response.body}');
        throw Exception('Không thể tải danh sách đơn hàng: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [DineInOrderService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Lấy chi tiết đơn dine-in
  Future<DineInOrder> getDineInOrderDetail(int orderId) async {
    try {
      print('📄 [DineInOrderService] Đang lấy chi tiết đơn #$orderId...');
      final token = await _getToken();
      if (token == null) {
        print('❌ [DineInOrderService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🌐 [DineInOrderService] URL: $baseUrl/$orderId/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/$orderId/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      print('📡 [DineInOrderService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [DineInOrderService] Lấy được chi tiết đơn #$orderId');
        return DineInOrder.fromJson(data);
      } else {
        print('❌ [DineInOrderService] Lỗi ${response.statusCode}: ${response.body}');
        throw Exception('Không thể tải chi tiết đơn hàng: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [DineInOrderService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Tạo đơn dine-in mới
  Future<DineInOrder> createDineInOrder(CreateDineInOrderRequest request) async {
    try {
      print('➕ [DineInOrderService] Đang tạo đơn mới...');
      print('📦 [DineInOrderService] Data: ${json.encode(request.toJson())}');
      
      final token = await _getToken();
      if (token == null) {
        print('❌ [DineInOrderService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🌐 [DineInOrderService] URL: $baseUrl/');
      
      final response = await http.post(
        Uri.parse('$baseUrl/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      print('📡 [DineInOrderService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [DineInOrderService] Tạo đơn thành công #${data['id']}');
        return DineInOrder.fromJson(data);
      } else {
        print('❌ [DineInOrderService] Lỗi ${response.statusCode}: ${response.body}');
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'Không thể tạo đơn hàng: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [DineInOrderService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Xác nhận thời gian chế biến
  Future<DineInOrder> confirmTime(int orderId, int thoiGianLay) async {
    try {
      print('⏰ [DineInOrderService] Xác nhận thời gian đơn #$orderId: $thoiGianLay phút');
      final token = await _getToken();
      if (token == null) {
        print('❌ [DineInOrderService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🌐 [DineInOrderService] URL: $baseUrl/$orderId/confirm-time/');
      
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/confirm-time/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'thoi_gian_lay': thoiGianLay}),
      );

      print('📡 [DineInOrderService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [DineInOrderService] Xác nhận thời gian thành công');
        return DineInOrder.fromJson(data);
      } else {
        print('❌ [DineInOrderService] Lỗi ${response.statusCode}: ${response.body}');
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'Không thể xác nhận thời gian: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [DineInOrderService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Bắt đầu nấu
  Future<DineInOrder> startCooking(int orderId) async {
    try {
      print('🍳 [DineInOrderService] Bắt đầu nấu đơn #$orderId');
      final token = await _getToken();
      if (token == null) {
        print('❌ [DineInOrderService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🌐 [DineInOrderService] URL: $baseUrl/$orderId/start-cooking/');
      
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/start-cooking/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      print('📡 [DineInOrderService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [DineInOrderService] Bắt đầu nấu thành công');
        return DineInOrder.fromJson(data);
      } else {
        print('❌ [DineInOrderService] Lỗi ${response.statusCode}: ${response.body}');
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'Không thể bắt đầu nấu: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [DineInOrderService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Đánh dấu món sẵn sàng (chỉ dành cho bếp trưởng)
  Future<DineInOrder> markReady(int orderId) async {
    try {
      print('✨ [DineInOrderService] Đánh dấu sẵn sàng đơn #$orderId');
      final token = await _getToken();
      if (token == null) {
        print('❌ [DineInOrderService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🌐 [DineInOrderService] URL: $baseUrl/$orderId/mark-ready/');
      
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/mark-ready/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      print('📡 [DineInOrderService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [DineInOrderService] Đánh dấu sẵn sàng thành công');
        return DineInOrder.fromJson(data);
      } else {
        print('❌ [DineInOrderService] Lỗi ${response.statusCode}: ${response.body}');
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'Không thể đánh dấu sẵn sàng: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [DineInOrderService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('$e');
    }
  }

  // Đem món tới bàn
  Future<DineInOrder> deliverToTable(int orderId, {String? paymentMethod}) async {
    try {
      print('🚚 [DineInOrderService] Đem món tới bàn - đơn #$orderId');
      final token = await _getToken();
      if (token == null) {
        print('❌ [DineInOrderService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🌐 [DineInOrderService] URL: $baseUrl/$orderId/deliver-to-table/');
      
      final Map<String, dynamic>? _body = paymentMethod != null ? {'payment_method': paymentMethod} : null;
      if (_body != null) print('📦 [DineInOrderService] Payment method: $paymentMethod');

      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/deliver-to-table/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: _body != null ? json.encode(_body) : null,
      );

      print('📡 [DineInOrderService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [DineInOrderService] Đã hoàn thành đơn hàng');
        return DineInOrder.fromJson(data);
      } else {
        print('❌ [DineInOrderService] Lỗi ${response.statusCode}: ${response.body}');
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'Không thể hoàn thành đơn hàng: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [DineInOrderService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Hủy đơn
  Future<DineInOrder> cancelOrder(int orderId) async {
    try {
      print('🚫 [DineInOrderService] Hủy đơn #$orderId');
      final token = await _getToken();
      if (token == null) {
        print('❌ [DineInOrderService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🌐 [DineInOrderService] URL: $baseUrl/$orderId/cancel-order/');
      
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/cancel-order/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      print('📡 [DineInOrderService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [DineInOrderService] Hủy đơn thành công');
        return DineInOrder.fromJson(data);
      } else {
        print('❌ [DineInOrderService] Lỗi ${response.statusCode}: ${response.body}');
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'Không thể hủy đơn hàng: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [DineInOrderService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Thêm món vào đơn hàng đang có
  Future<Map<String, dynamic>> addItemsToOrder(int orderId, List<OrderItem> items) async {
    try {
      print('➕ [DineInOrderService] Thêm món vào đơn #$orderId');
      print('📦 [DineInOrderService] Số món: ${items.length}');
      
      final token = await _getToken();
      if (token == null) {
        print('❌ [DineInOrderService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      final url = '${ApiEndpoints.baseUrl}/api/dine-in/$orderId/add-items/';
      print('🌐 [DineInOrderService] URL: $url');
      
      final body = {
        'mon_an_list': items.map((item) => item.toJson()).toList(),
      };
      print('📦 [DineInOrderService] Body: ${json.encode(body)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('📡 [DineInOrderService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [DineInOrderService] ${data['message']}');
        return data;
      } else {
        print('❌ [DineInOrderService] Lỗi ${response.statusCode}: ${response.body}');
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'Không thể thêm món: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [DineInOrderService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
