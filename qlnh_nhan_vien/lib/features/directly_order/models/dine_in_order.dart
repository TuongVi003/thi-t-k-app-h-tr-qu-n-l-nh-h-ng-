class DineInOrder {
  final int id;
  final int? banAnId;
  final String? banAnSoBan;
  final int? khachHangId;
  final int? nhanVienId;
  final String nhanVienHoTen;
  final DateTime orderTime;
  final String loaiOrder;
  final String trangThai;
  final int? thoiGianLay;
  final DateTime? thoiGianSanSang;
  final String? ghiChu;
  final List<ChiTietDineInOrder> chiTietOrder;
  final double tongTien;

  DineInOrder({
    required this.id,
    this.banAnId,
    this.banAnSoBan,
    this.khachHangId,
    this.nhanVienId,
    required this.nhanVienHoTen,
    required this.orderTime,
    required this.loaiOrder,
    required this.trangThai,
    this.thoiGianLay,
    this.thoiGianSanSang,
    this.ghiChu,
    required this.chiTietOrder,
    required this.tongTien,
  });

  factory DineInOrder.fromJson(Map<String, dynamic> json) {
    // Helper function để parse số (có thể là String, int, hoặc double)
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Helper function để parse DateTime an toàn
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    List<ChiTietDineInOrder> chiTiet = [];
    if (json['chi_tiet_order'] != null) {
      chiTiet = (json['chi_tiet_order'] as List)
          .map((item) => ChiTietDineInOrder.fromJson(item))
          .toList();
    }

    // Xử lý nhân viên: nếu có nhan_vien_detail thì lấy từ đó, không thì lấy từ khach_hang_detail
    String nhanVienHoTen = '';
    if (json['nhan_vien_detail'] != null) {
      nhanVienHoTen = json['nhan_vien_detail']['ho_ten'] ?? '';
    } else if (json['khach_hang_detail'] != null) {
      nhanVienHoTen = json['khach_hang_detail']['ho_ten'] ?? '';
    }

    return DineInOrder(
      id: json['id'],
      banAnId: json['ban_an'],
      banAnSoBan: json['ban_an']?.toString() ?? 'N/A',
      khachHangId: json['khach_hang'],
      nhanVienId: json['nhan_vien'],
      nhanVienHoTen: nhanVienHoTen,
      orderTime: parseDateTime(json['order_time']) ?? DateTime.now(),
      loaiOrder: json['loai_order'] ?? 'dine_in',
      trangThai: json['trang_thai'] ?? 'pending',
      thoiGianLay: json['thoi_gian_lay'],
      thoiGianSanSang: parseDateTime(json['thoi_gian_san_sang']),
      ghiChu: json['ghi_chu'],
      chiTietOrder: chiTiet,
      tongTien: parseDouble(json['tong_tien']),
    );
  }

  String getTrangThaiText() {
    switch (trangThai) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cooking':
        return 'Đang nấu';
      case 'ready':
        return 'Sẵn sàng';
      case 'completed':
        return 'Hoàn thành';
      case 'canceled':
        return 'Đã hủy';
      default:
        return trangThai;
    }
  }
}

class ChiTietDineInOrder {
  final int id;
  final int orderId;
  final int monAnId;
  final String tenMonAn;
  final int soLuong;
  final double gia;
  final String? hinhAnh;

  ChiTietDineInOrder({
    required this.id,
    required this.orderId,
    required this.monAnId,
    required this.tenMonAn,
    required this.soLuong,
    required this.gia,
    this.hinhAnh,
  });

  factory ChiTietDineInOrder.fromJson(Map<String, dynamic> json) {
    // Helper function để parse số
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return ChiTietDineInOrder(
      id: json['id'],
      orderId: json['order'],
      monAnId: json['mon_an'],
      tenMonAn: json['mon_an_detail']?['ten_mon'] ?? '',
      soLuong: json['so_luong'],
      gia: parseDouble(json['gia']),
      hinhAnh: json['mon_an_detail']?['hinh_anh'],
    );
  }

  double get thanhTien => soLuong * gia;
}

class CreateDineInOrderRequest {
  final int banAnId;
  final List<OrderItem> monAnList;
  final String? ghiChu;

  CreateDineInOrderRequest({
    required this.banAnId,
    required this.monAnList,
    this.ghiChu,
  });

  Map<String, dynamic> toJson() {
    return {
      'ban_an_id': banAnId,
      'mon_an_list': monAnList.map((item) => item.toJson()).toList(),
      'ghi_chu': ghiChu ?? '',
    };
  }
}

class OrderItem {
  final int monAnId;
  final int soLuong;

  OrderItem({
    required this.monAnId,
    required this.soLuong,
  });

  Map<String, dynamic> toJson() {
    return {
      'mon_an_id': monAnId,
      'so_luong': soLuong,
    };
  }
}
