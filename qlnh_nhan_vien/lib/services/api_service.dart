import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/don_hang.dart';
import '../models/table.dart' as models;
import 'auth_service.dart';

class ApiService {
  static const int timeout = 7; // seconds

  // Fetch tất cả đơn hàng từ API
  static Future<List<DonHang>> fetchDonHangList() async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.donHangList),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => DonHang.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load don hang list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching don hang list: $e');
    }
  }

  // Fetch bàn ăn từ API mới với slot thời gian
  static Future<List<models.Table>> fetchTablesFromApi({String? slot}) async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      // Xây dựng URL với slot parameter
      String url = ApiEndpoints.banAnList;
      if (slot != null) {
        url += '?slot=$slot';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        List<models.Table> tables = jsonData
            .map((json) => models.Table.fromTablesApi(json))
            .toList();
        
        // Sắp xếp theo số bàn
        tables.sort((a, b) => a.number.compareTo(b.number));
        return tables;
      } else {
        throw Exception('Failed to load tables: ${response.statusCode}');
      }
    } catch (e) {
      // Nếu API lỗi, trả về dữ liệu mẫu
      print('Error fetching tables from API, using mock data: $e');
      return _getMockTables();
    }
  }

  // Chuyển đổi đơn hàng thành bàn ăn để hiển thị (deprecated - giữ lại để tương thích)
  static Future<List<models.Table>> fetchTablesFromDonHang() async {
    try {
      final donHangList = await fetchDonHangList();
      
      // Tạo map để track các bàn theo số bàn
      Map<int, models.Table> tableMap = {};
      
      // Tạo Set để track các bàn từ API
      Set<int> allTableNumbers = {};
      for (var donHang in donHangList) {
        allTableNumbers.add(donHang.banAn?.soBan ?? 0);
      }
      
      // Thêm các bàn từ 1 đến 20 (giả sử có 20 bàn)
      for (int i = 1; i <= 20; i++) {
        allTableNumbers.add(i);
      }
      
      // Tạo tất cả bàn như available trước
      for (int tableNumber in allTableNumbers) {
        tableMap[tableNumber] = models.Table(
          id: tableNumber.toString(),
          number: tableNumber,
          capacity: _getDefaultCapacity(tableNumber),
          status: models.TableStatus.available,
        );
      }
      
      // Xử lý DonHang từ API
      for (var donHang in donHangList) {
        final tableNumber = donHang.banAn?.soBan ?? 0;
        
        // Kiểm tra trạng thái đơn hàng
        models.TableStatus status;
        switch (donHang.trangThai) {
          case DonHangStatus.pending:
            status = models.TableStatus.reserved; // Bàn đã đặt, chờ xác nhận
            break;
          case DonHangStatus.confirmed:
            status = models.TableStatus.reserved; // Bàn đã xác nhận đặt
            break;
          case DonHangStatus.canceled:
            status = models.TableStatus.available; // Bàn đã hủy, có thể dùng
            break;
        }
        
        // Chỉ cập nhật bàn nếu có đơn hàng active (pending/confirmed)
        if (donHang.trangThai == DonHangStatus.pending || donHang.trangThai == DonHangStatus.confirmed) {
          String khuVucDisplay = _getKhuVucDisplay(donHang.banAn?.khuVuc ?? '');
          
          tableMap[tableNumber] = models.Table(
            id: donHang.banAn?.id.toString() ?? '',
            number: donHang.banAn?.soBan ?? 0,
            capacity: donHang.banAn?.sucChua ?? 0,
            status: status,
            customerName: donHang.khachHang.hoTen,
            customerPhone: donHang.khachHang.soDienThoai,
            reservationTime: donHang.ngayDat,
            notes: 'Khu vực: $khuVucDisplay - Đơn #${donHang.id}',
          );
        }
      }
      
      // Convert map thành list và sắp xếp
      List<models.Table> allTables = tableMap.values.toList();
      allTables.sort((a, b) => a.number.compareTo(b.number));
      
      return allTables;
    } catch (e) {
      // Nếu API lỗi, trả về dữ liệu mẫu
      print('Error fetching from API, using mock data: $e');
      return _getMockTables();
    }
  }

  // Hàm hỗ trợ để chuyển đổi khu vực
  static String _getKhuVucDisplay(String khuVuc) {
    switch (khuVuc) {
      case 'inside':
        return 'Trong nhà';
      case 'outside':
        return 'Ngoài trời';
      case 'private-room':
        return 'VIP';
      default:
        return khuVuc;
    }
  }

  // Hàm hỗ trợ để xác định dung lượng mặc định của bàn
  static int _getDefaultCapacity(int tableNumber) {
    if (tableNumber <= 5) return 2;      // Bàn 1-5: 2 người
    if (tableNumber <= 15) return 4;     // Bàn 6-15: 4 người  
    return 6;                            // Bàn 16-20: 6 người
  }

  // Dữ liệu mẫu khi API không khả dụng
  static List<models.Table> _getMockTables() {
    return [
      models.Table(
        id: '1', 
        number: 1, 
        capacity: 2, 
        status: models.TableStatus.available,
        area: models.AreaType.inside,
        notes: 'Khu vực: Trong nhà',
      ),
      models.Table(
        id: '2', 
        number: 2, 
        capacity: 4, 
        status: models.TableStatus.occupied, 
        area: models.AreaType.outside,
        customerName: 'Nguyễn Văn A', 
        customerPhone: '0123456789',
        customerType: models.CustomerType.registered,
        notes: 'Khu vực: Ngoài trời\nKhách hàng: Nguyễn Văn A - 0123456789',
      ),
      models.Table(
        id: '3', 
        number: 3, 
        capacity: 6, 
        status: models.TableStatus.occupied,
        area: models.AreaType.privateRoom,
        customerName: 'Trần Thị B', 
        customerPhone: '0987654321',
        customerType: models.CustomerType.guest,
        reservationTime: DateTime.now().add(const Duration(hours: 1)),
        notes: 'Khu vực: VIP\nKhách vãng lai: Trần Thị B - 0987654321',
      ),
      models.Table(
        id: '4', 
        number: 4, 
        capacity: 4, 
        status: models.TableStatus.available,
        area: models.AreaType.outside,
        notes: 'Khu vực: Ngoài trời',
      ),
      models.Table(
        id: '5', 
        number: 5, 
        capacity: 2, 
        status: models.TableStatus.cleaning,
        area: models.AreaType.inside,
        notes: 'Khu vực: Trong nhà',
      ),
      models.Table(
        id: '6', 
        number: 6, 
        capacity: 8, 
        status: models.TableStatus.occupied,
        area: models.AreaType.privateRoom,
        customerName: 'Lê Văn C', 
        customerPhone: '0345678912',
        customerType: models.CustomerType.registered,
        notes: 'Khu vực: VIP\nKhách hàng: Lê Văn C - 0345678912',
      ),
      models.Table(
        id: '7', 
        number: 7, 
        capacity: 4, 
        status: models.TableStatus.available,
        area: models.AreaType.inside,
        notes: 'Khu vực: Trong nhà',
      ),
      models.Table(
        id: '8', 
        number: 8, 
        capacity: 2, 
        status: models.TableStatus.occupied,
        area: models.AreaType.outside,
        customerName: 'Phạm Thị D', 
        customerPhone: '0456789123',
        customerType: models.CustomerType.guest,
        reservationTime: DateTime.now().add(const Duration(hours: 2)),
        notes: 'Khu vực: Ngoài trời\nKhách vãng lai: Phạm Thị D - 0456789123',
      ),
    ];
  }

  /// Gọi API để dọn/clear bàn (chuyển trạng thái occupied -> available)
  /// Trả về JSON response của API dưới dạng Map<String, dynamic>
  static Future<Map<String, dynamic>> clearTableApi(int tableId) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Không có token hợp lệ.');

      final response = await http.post(
        Uri.parse(ApiEndpoints.clearTable(tableId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final err = json.decode(response.body);
        throw Exception(err['error'] ?? 'Failed to clear table: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error clearing table: $e');
    }
  }

  /// Nhân viên đặt bàn dùm khách hàng gọi qua hotline
  /// Trả về thông tin đơn hàng và bàn ăn đã được đặt
  static Future<Map<String, dynamic>> createHotlineReservation({
    required int banAnId,
    required String khachHoTen,
    required String khachSoDienThoai,
    required String ngayDat, // ISO 8601 format
    String trangThai = 'pending',
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Không có token hợp lệ.');

      print('📞 Creating hotline reservation:');
      print('   Table: $banAnId, Customer: $khachHoTen, Phone: $khachSoDienThoai');
      print('   Date: $ngayDat, Status: $trangThai');

      final response = await http.post(
        Uri.parse(ApiEndpoints.nhanVienMakeDonhang),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
        body: json.encode({
          'ban_an_id': banAnId,
          'khach_ho_ten': khachHoTen,
          'khach_so_dien_thoai': khachSoDienThoai,
          'ngay_dat': ngayDat,
          'trang_thai': trangThai,
        }),
      ).timeout(const Duration(seconds: timeout));

      print('📞 Response status: ${response.statusCode}');
      print('📞 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final err = json.decode(response.body);
        // Xử lý lỗi bàn đã được đặt
        if (err['non_field_errors'] != null) {
          throw Exception(err['non_field_errors'][0]);
        }
        throw Exception(err['error'] ?? 'Failed to create reservation: ${response.statusCode}');
      }
    } catch (e) {
      print('📞 Error creating hotline reservation: $e');
      throw Exception('Lỗi khi đặt bàn: $e');
    }
  }

  // Cập nhật trạng thái đơn đặt bàn
  static Future<DonHang> updateBookingStatus(int donHangId, String trangThai) async {
    try {
      final token = await AuthService.getValidToken();
      
      if (token == null) {
        throw Exception('Không có token hợp lệ. Vui lòng đăng nhập lại.');
      }

      // Kiểm tra trạng thái hợp lệ
      if (!['pending', 'confirmed', 'canceled'].contains(trangThai)) {
        throw Exception('Trạng thái không hợp lệ: $trangThai');
      }

      final response = await http.patch(
        Uri.parse(ApiEndpoints.updateStatusTable(donHangId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token.authorizationHeader,
        },
        body: json.encode({
          'trang_thai': trangThai,
        }),
      ).timeout(const Duration(seconds: timeout));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return DonHang.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw Exception('Đơn hàng không tồn tại');
      } else if (response.statusCode == 403) {
        throw Exception('Chỉ nhân viên mới được cập nhật trạng thái');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Dữ liệu không hợp lệ');
      } else {
        throw Exception('Lỗi cập nhật trạng thái: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API: $e');
    }
  }
}