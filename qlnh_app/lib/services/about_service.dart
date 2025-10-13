import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/about_us.dart';

class AboutService {
  static Future<List<AboutUs>> getAboutUs() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.about),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => AboutUs.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load about us data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching about us: $e');
      rethrow;
    }
  }

  static Future<AboutUs?> getAboutUsByKey(String key) async {
    try {
      final allData = await getAboutUs();
      return allData.firstWhere(
        (item) => item.key == key,
        orElse: () => throw Exception('About us item with key $key not found'),
      );
    } catch (e) {
      print('Error fetching about us by key: $e');
      return null;
    }
  }
}
