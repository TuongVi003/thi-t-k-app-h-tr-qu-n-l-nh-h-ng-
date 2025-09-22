import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/don_hang.dart';
import '../models/table.dart' as models;

class ApiService {
  static const int timeout = 7; // seconds

  // Fetch tất cả đơn hàng từ API
  static Future<List<DonHang>> fetchDonHangList() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.donHangList),
        headers: {
          'Content-Type': 'application/json',
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

  // Chuyển đổi đơn hàng thành bàn ăn để hiển thị
  static Future<List<models.Table>> fetchTablesFromDonHang() async {
    try {
      final donHangList = await fetchDonHangList();
      
      // Tạo map để track các bàn theo số bàn
      Map<int, models.Table> tableMap = {};
      
      // Tạo Set để track các bàn từ API
      Set<int> allTableNumbers = {};
      for (var donHang in donHangList) {
        allTableNumbers.add(donHang.banAn.soBan);
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
        final tableNumber = donHang.banAn.soBan;
        
        // Kiểm tra trạng thái đơn hàng
        models.TableStatus status;
        switch (donHang.trangThai.toLowerCase()) {
          case 'pending':
            status = models.TableStatus.reserved; // Bàn đã đặt, chờ xác nhận
            break;
          case 'confirmed':
            status = models.TableStatus.reserved; // Bàn đã xác nhận đặt
            break;
          case 'canceled':
            status = models.TableStatus.available; // Bàn đã hủy, có thể dùng
            break;
          default:
            status = models.TableStatus.available;
        }
        
        // Chỉ cập nhật bàn nếu có đơn hàng active (pending/confirmed)
        if (donHang.trangThai == 'pending' || donHang.trangThai == 'confirmed') {
          String khuVucDisplay = _getKhuVucDisplay(donHang.banAn.khuVuc);
          
          tableMap[tableNumber] = models.Table(
            id: donHang.banAn.id.toString(),
            number: donHang.banAn.soBan,
            capacity: donHang.banAn.sucChua,
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
      models.Table(id: '1', number: 1, capacity: 2, status: models.TableStatus.available),
      models.Table(id: '2', number: 2, capacity: 4, status: models.TableStatus.occupied, 
            customerName: 'Nguyễn Văn A', customerPhone: '0123456789'),
      models.Table(id: '3', number: 3, capacity: 6, status: models.TableStatus.reserved,
            customerName: 'Trần Thị B', customerPhone: '0987654321',
            reservationTime: DateTime.now().add(const Duration(hours: 1))),
      models.Table(id: '4', number: 4, capacity: 4, status: models.TableStatus.available),
      models.Table(id: '5', number: 5, capacity: 2, status: models.TableStatus.cleaning),
      models.Table(id: '6', number: 6, capacity: 8, status: models.TableStatus.occupied,
            customerName: 'Lê Văn C', customerPhone: '0345678912'),
      models.Table(id: '7', number: 7, capacity: 4, status: models.TableStatus.available),
      models.Table(id: '8', number: 8, capacity: 2, status: models.TableStatus.reserved,
            customerName: 'Phạm Thị D', customerPhone: '0456789123',
            reservationTime: DateTime.now().add(const Duration(hours: 2))),
    ];
  }
}