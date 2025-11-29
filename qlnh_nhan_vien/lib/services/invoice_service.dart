import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:qlnh_nhan_vien/constants/api.dart';
import '../models/invoice.dart';
import 'auth_service.dart';

class InvoiceService {
  static const int timeoutSeconds = 10;

  // Fetch invoice JSON from /api/hoadon/{id}/
  static Future<Map<String, dynamic>> getInvoice(int hoaDonId) async {
  debugPrint('[InvoiceService] 📄 Fetching invoice ID: $hoaDonId');
    final token = await AuthService.getValidToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/hoadon/$hoaDonId/');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token.authorizationHeader,
      },
    ).timeout(const Duration(seconds: timeoutSeconds));

    debugPrint('[InvoiceService] 📄 Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      debugPrint('[InvoiceService] 📄 Response body length: ${response.body.length}');
      if (data is Map<String, dynamic>) return data;
      throw Exception('Invalid invoice data');
    } else {
      throw Exception('Không thể tải hóa đơn: ${response.statusCode}');
    }
  }

  // Fetch invoice by order ID from /api/hoadon/by-order/{order_id}/
  static Future<Invoice> getInvoiceByOrder(int orderId) async {
    debugPrint('[InvoiceService] 📄 Fetching invoice for order ID: $orderId');
    final token = await AuthService.getValidToken();
    if (token == null) throw Exception('Chưa đăng nhập');

    final uri = Uri.parse(ApiEndpoints.getInvoiceByOrder(orderId));
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token.authorizationHeader,
      },
    ).timeout(const Duration(seconds: timeoutSeconds));

    debugPrint('[InvoiceService] 📄 Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return Invoice.fromJson(data);
    } else {
      throw Exception('Không thể tải hóa đơn: ${response.statusCode}');
    }
  }
}
