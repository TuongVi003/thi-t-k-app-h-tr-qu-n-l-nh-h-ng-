import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/model.dart';
import '../constants/api.dart';

class ReservationService {
  static Future<List<BanAn>> getTablesForReservation(String khuVuc) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/tables-for-reservations/?khu_vuc=$khuVuc');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => BanAn.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Không thể tải danh sách bàn: ${response.statusCode}');
    }
  }

  static Future<DonHang> makeReservation({
    required String accessToken,
    required int sucChua,
    required String khuVuc,
    required DateTime ngayDat,
    required int banAnId,
    String trangThai = 'pending'
  }) async {
    final uri = Uri.parse(ApiEndpoints.makeReservation);

    final body = jsonEncode({
      'suc_chua': sucChua,
      'khu_vuc': khuVuc,
      'ngay_dat': ngayDat.toIso8601String(),
      'trang_thai': trangThai,
      'ban_an_id': banAnId,
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
      final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('${errorData['non_field_errors'] ?? response.body}');
    }
  }
}