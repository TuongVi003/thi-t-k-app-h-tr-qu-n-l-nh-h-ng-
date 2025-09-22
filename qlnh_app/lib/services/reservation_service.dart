import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/model.dart';
import '../constants/api.dart';

class ReservationService {
  static Future<DonHang> makeReservation({
    required String accessToken,
    required int sucChua,
    required String khuVuc,
    required DateTime ngayDat,
    String trangThai = 'pending'
  }) async {
    final uri = Uri.parse(ApiEndpoints.makeReservation);

    final body = jsonEncode({
      'suc_chua': sucChua,
      'khu_vuc': khuVuc,
      'ngay_dat': ngayDat.toIso8601String(),
      'trang_thai': trangThai,
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: body,
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return DonHang.fromJson(data);
    } else {
      throw Exception('Failed to make reservation (status ${response.statusCode})');
    }
  }
}