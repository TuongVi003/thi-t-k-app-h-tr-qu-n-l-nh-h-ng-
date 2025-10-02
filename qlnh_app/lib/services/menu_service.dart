import 'package:qlnh_app/models/category.dart';
import 'package:qlnh_app/models/menu_item.dart';
import 'package:qlnh_app/constants/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MenuService {
  static Future<List<DanhMuc>> layDanhSachDanhMuc() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.categories));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => DanhMuc.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      throw Exception('Error fetching categories: $e');
    }
  }

  static Future<List<MonAn>> layDanhSachMonAn({int? categoryId}) async {
    try {
      String url = ApiEndpoints.menu;
      if (categoryId != null) {
        url += '?danh_muc=$categoryId';
      }
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => MonAn.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load menu items');
      }
    } catch (e) {
      print('Error fetching menu items: $e');
      throw Exception('Error fetching menu items: $e');
    }
  }
}
