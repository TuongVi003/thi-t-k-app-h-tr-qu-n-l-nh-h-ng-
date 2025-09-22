import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/model.dart';
import '../constants/api.dart';

class ReservationService {
  static Future<DonHang> makeReservation({
    required String accessToken,
    required List<CartItem> cartItems,
    required String soDienThoai,
    required String hoTen,
    String? ghiChu,
  }) async {
    final uri = Uri.parse(ApiEndpoints.makeReservation);

    final body = jsonEncode({
      'so_dien_thoai': soDienThoai,
      'ho_ten': hoTen,
      if (ghiChu != null && ghiChu.isNotEmpty) 'ghi_chu': ghiChu,
      'items': cartItems
          .map((item) => {
                'menu_item_id': item.menuItem.id,
                'quantity': item.quantity,
              })
          .toList(),
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
      return DonHang.fromJson(data);
    } else {
      throw Exception('Failed to make reservation (status ${response.statusCode})');
    }
  }
}