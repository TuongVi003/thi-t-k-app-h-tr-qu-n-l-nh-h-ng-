import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qlnh_nhan_vien/utils/app_utils.dart';
import '../constants/api.dart';
import 'auth_service.dart';

class AboutUsService {
  static const int timeout = 10;

  /// Fetch about-us data from API and return payment QR image URL
  static Future<String?> getPaymentQrUrl() async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.aboutUs),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        // Find the item with key = 'payment_qr'
        final paymentQrItem = jsonData.firstWhere(
          (item) => item['key'] == 'payment_qr',
          orElse: () => null,
        );

        if (paymentQrItem != null && paymentQrItem['noi_dung'] != null) {
          final imagePath = paymentQrItem['noi_dung'] as String;
          // Return full URL
          return AppUtils.imageUrl(imagePath);
        }
        
        return null;
      } else {
        throw Exception('Failed to load about-us data: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error in getPaymentQrUrl: $e');
      throw Exception('Error fetching payment QR: $e');
    }
  }
}
