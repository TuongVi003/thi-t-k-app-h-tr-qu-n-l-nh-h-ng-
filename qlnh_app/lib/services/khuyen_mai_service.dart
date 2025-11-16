import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/khuyen_mai.dart';

class KhuyenMaiService {
  static Future<List<KhuyenMai>> getKhuyenMai() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.promotions),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => KhuyenMai.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load promotions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching promotions: $e');
      rethrow;
    }
  }

  static Future<List<KhuyenMai>> getActiveKhuyenMai() async {
    try {
      final allPromotions = await getKhuyenMai();
      return allPromotions.where((promo) => promo.isActive).toList();
    } catch (e) {
      print('Error fetching active promotions: $e');
      rethrow;
    }
  }
}
