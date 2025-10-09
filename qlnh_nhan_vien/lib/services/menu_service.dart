import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/mon_an.dart';
import 'auth_service.dart';

class MenuService {
  static const String baseUrl = '${ApiEndpoints.baseUrl}/api/menu';

  Future<String?> _getToken() async {
    final token = await AuthService.getValidToken();
    return token?.authorizationHeader;
  }

  Future<List<MonAn>> getMenuItems() async {
    try {
      print('🍽️ [MenuService] Đang lấy danh sách món ăn...');
      final token = await _getToken();
      if (token == null) {
        print('❌ [MenuService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🔑 [MenuService] Token: ${token.substring(0, 20)}...');
      print('🌐 [MenuService] URL: $baseUrl/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      print('📡 [MenuService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [MenuService] Lấy được ${data.length} món ăn');
        return data.map((json) => MonAn.fromJson(json)).toList();
      } else {
        print('❌ [MenuService] Lỗi ${response.statusCode}: ${response.body}');
        throw Exception('Không thể tải menu: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [MenuService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<MonAn> getMenuItem(int id) async {
    try {
      print('🍽️ [MenuService] Đang lấy chi tiết món #$id...');
      final token = await _getToken();
      if (token == null) {
        print('❌ [MenuService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🌐 [MenuService] URL: $baseUrl/$id/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/$id/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      print('📡 [MenuService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [MenuService] Lấy được món #$id');
        return MonAn.fromJson(data);
      } else {
        print('❌ [MenuService] Lỗi ${response.statusCode}: ${response.body}');
        throw Exception('Không thể tải món ăn: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [MenuService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
