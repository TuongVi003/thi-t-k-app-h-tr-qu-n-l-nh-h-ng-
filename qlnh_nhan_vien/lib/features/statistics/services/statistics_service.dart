import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../constants/api.dart';
import '../models/statistics.dart';
import '../../../services/auth_service.dart';

class StatisticsService {
  static const int timeout = 10; // seconds

  /// Lấy thống kê tổng quan
  static Future<Statistics> getStatistics() async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.statistics),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('DEBUG: Statistics API response: $jsonData');
        return Statistics.fromJson(jsonData);
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getStatistics: $e');
      throw Exception('Error fetching statistics: $e');
    }
  }

 
  /// Lấy thống kê đơn hàng theo trạng thái, loại và nhân viên
  /// [startDate] - Ngày bắt đầu (format: yyyy-MM-dd)
  /// [endDate] - Ngày kết thúc (format: yyyy-MM-dd)
  static Future<OrderStatistics> getOrderStatistics({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final uri = Uri.parse(ApiEndpoints.orderStatistics).replace(
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print('DEBUG: Order Statistics API response: $jsonData');
        return OrderStatistics.fromJson(jsonData);
      } else {
        throw Exception('Failed to load order statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getOrderStatistics: $e');
      throw Exception('Error fetching order statistics: $e');
    }
  }
}
