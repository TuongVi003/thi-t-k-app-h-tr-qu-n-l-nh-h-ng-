class TakeawayOrder {
  final int? id;
  final DateTime? thoiGianKhachLay;
  final String? ghiChu;
  final DateTime? orderTime;
  final String trangThai;
  final int? thoiGianLay;
  final DateTime? thoiGianSanSang;
  final String loaiOrder;
  final List<TakeawayOrderItem> items;
  final double tongTien;

  TakeawayOrder({
    this.id,
    this.thoiGianKhachLay,
    this.ghiChu,
    this.orderTime,
    required this.trangThai,
    this.thoiGianLay,
    this.thoiGianSanSang,
    required this.loaiOrder,
    required this.items,
    required this.tongTien,
  });

  factory TakeawayOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        print('Error parsing DateTime: $e, value: $value');
        return null;
      }
    }

    return TakeawayOrder(
      id: json['id'],
      thoiGianKhachLay: parseDateTime(json['thoi_gian_khach_lay']) ,
      ghiChu: json['ghi_chu'],
      orderTime: parseDateTime(json['order_time']) ?? DateTime.now(),
      trangThai: json['trang_thai'] ?? 'pending',
      thoiGianLay: json['thoi_gian_lay'],
      thoiGianSanSang: parseDateTime(json['thoi_gian_san_sang']),
      loaiOrder: json['loai_order'] ?? 'takeaway',
      items: (json['chi_tiet_order'] as List? ?? [])
          .map((item) => TakeawayOrderItem.fromJson(item))
          .toList(),
      tongTien: (json['tong_tien'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ghi_chu': ghiChu,
      'mon_an_list': items.map((item) => item.toJson()).toList(),
    };
  }

  String get trangThaiDisplay {
    switch (trangThai) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cooking':
        return 'Đang nấu';
      case 'ready':
        return 'Sẵn sàng lấy';
      case 'completed':
        return 'Hoàn thành';
      case 'canceled':
        return 'Đã hủy';
      default:
        return trangThai;
    }
  }

  String get thoiGianLayDisplay {
    if (thoiGianLay == null) return 'Chưa xác định';
    return '$thoiGianLay phút';
  }
}

class TakeawayOrderItem {
  final int? id;
  final int monAnId;
  final String tenMon;
  final int soLuong;
  final double gia;
  final String? hinhAnh;

  TakeawayOrderItem({
    this.id,
    required this.monAnId,
    required this.tenMon,
    required this.soLuong,
    required this.gia,
    this.hinhAnh,
  });

  factory TakeawayOrderItem.fromJson(Map<String, dynamic> json) {
    final monAnDetail = json['mon_an_detail'] ?? {};
    return TakeawayOrderItem(
      id: json['id'],
      monAnId: json['mon_an'] ?? monAnDetail['id'],
      tenMon: monAnDetail['ten_mon'] ?? '',
      soLuong: json['so_luong'] ?? 1,
      gia: (json['gia'] as num?)?.toDouble() ?? 0.0,
      hinhAnh: monAnDetail['hinh_anh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mon_an_id': monAnId,
      'so_luong': soLuong,
    };
  }

  double get thanhTien => soLuong * gia;
}

class TakeawayCartItem {
  final int monAnId;
  final String tenMon;
  final double gia;
  final String? hinhAnh;
  final String? moTa;
  int soLuong;

  TakeawayCartItem({
    required this.monAnId,
    required this.tenMon,
    required this.gia,
    this.hinhAnh,
    this.moTa,
    this.soLuong = 1,
  });

  double get thanhTien => soLuong * gia;

  TakeawayOrderItem toOrderItem() {
    return TakeawayOrderItem(
      monAnId: monAnId,
      tenMon: tenMon,
      soLuong: soLuong,
      gia: gia,
      hinhAnh: hinhAnh,
    );
  }
}