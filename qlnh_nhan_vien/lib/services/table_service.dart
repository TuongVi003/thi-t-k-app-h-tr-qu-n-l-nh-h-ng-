import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/ban_an.dart';
import 'auth_service.dart';

class TableService {
  static const String baseUrl = '${ApiEndpoints.baseUrl}/api/tables';

  Future<String?> _getToken() async {
    final token = await AuthService.getValidToken();
    return token?.authorizationHeader;
  }

  Future<List<BanAn>> getTables() async {
    try {
      print('🪑 [TableService] Đang lấy danh sách bàn...');
      final token = await _getToken();
      if (token == null) {
        print('❌ [TableService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🔑 [TableService] Token: ${token.substring(0, 20)}...');
      print('🌐 [TableService] URL: $baseUrl/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      print('📡 [TableService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [TableService] Lấy được ${data.length} bàn');
        return data.map((json) => BanAn.fromJson(json)).toList();
      } else {
        print('❌ [TableService] Lỗi ${response.statusCode}: ${response.body}');
        throw Exception('Không thể tải danh sách bàn: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [TableService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  Future<BanAn> getTable(int id) async {
    try {
      print('🪑 [TableService] Đang lấy thông tin bàn #$id...');
      final token = await _getToken();
      if (token == null) {
        print('❌ [TableService] Token null - chưa đăng nhập');
        throw Exception('Chưa đăng nhập');
      }

      print('🌐 [TableService] URL: $baseUrl/$id/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/$id/'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      print('📡 [TableService] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ [TableService] Lấy được thông tin bàn #$id');
        return BanAn.fromJson(data);
      } else {
        print('❌ [TableService] Lỗi ${response.statusCode}: ${response.body}');
        throw Exception('Không thể tải thông tin bàn: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [TableService] Exception: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
