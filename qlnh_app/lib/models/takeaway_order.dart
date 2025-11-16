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
  final bool? khachHangXacNhanThanhToan;
  final double? phiGiaoHang;
  final double? tamTinh;
  final List<AppliedPromotion>? appliedPromotions;

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
    this.khachHangXacNhanThanhToan,
    this.phiGiaoHang,
    this.tamTinh,
    this.appliedPromotions,
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
      khachHangXacNhanThanhToan: json['khach_hang_xac_nhan_thanh_toan'] as bool?,
      phiGiaoHang: (json['phi_giao_hang'] as num?)?.toDouble(),
      tamTinh: (json['tam_tinh'] as num?)?.toDouble(),
      appliedPromotions: (json['applied_promotions'] as List?)
          ?.map((promo) => AppliedPromotion.fromJson(promo))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ghi_chu': ghiChu,
      'mon_an_list': items.map((item) => item.toJson()).toList(),
    };
  }

  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      'thoi_gian_khach_lay': thoiGianKhachLay?.toIso8601String(),
      'order_time': orderTime?.toIso8601String(),
      'trang_thai': trangThai,
      'thoi_gian_lay': thoiGianLay,
      'thoi_gian_san_sang': thoiGianSanSang?.toIso8601String(),
      'loai_order': loaiOrder,
      'chi_tiet_order': items.map((item) => item.toJson()).toList(),
      'tong_tien': tongTien,
      'khach_hang_xac_nhan_thanh_toan': khachHangXacNhanThanhToan,
      'phi_giao_hang': phiGiaoHang,
      'tam_tinh': tamTinh,
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
      'id': id,
      'ten_mon': tenMon,
      'hinh_anh': hinhAnh,
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

class AppliedPromotion {
  final int id;
  final String tenKhuyenMai;
  final String moTa;
  final String loaiGiamGia;
  final double giaTri;
  final double discountValue;

  AppliedPromotion({
    required this.id,
    required this.tenKhuyenMai,
    required this.moTa,
    required this.loaiGiamGia,
    required this.giaTri,
    required this.discountValue,
  });

  factory AppliedPromotion.fromJson(Map<String, dynamic> json) {
    return AppliedPromotion(
      id: json['id'] as int,
      tenKhuyenMai: json['ten_khuyen_mai'] as String,
      moTa: json['mo_ta'] as String,
      loaiGiamGia: json['loai_giam_gia'] as String,
      giaTri: (json['gia_tri'] as num).toDouble(),
      discountValue: (json['discount_value'] as num).toDouble(),
    );
  }

  String get displayType {
    if (loaiGiamGia == 'percentage') {
      final value = giaTri == giaTri.toInt() ? giaTri.toInt().toString() : giaTri.toString();
      return 'Giảm $value%';
    } else {
      final value = giaTri == giaTri.toInt() ? giaTri.toInt().toString() : giaTri.toString();
      return 'Giảm ${value}đ';
    }
  }
}