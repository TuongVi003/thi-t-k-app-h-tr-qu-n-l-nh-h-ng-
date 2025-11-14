import '../utils/safe_parser.dart';

class TakeawayOrder {
  final int id;
  final String? ghiChu;
  final DateTime orderTime;
  final String trangThai;
  final int? thoiGianLay;
  final DateTime? thoiGianSanSang;
  final String? loaiOrder;
  final String? phuongThucGiaoHang;
  final String? diaChiGiaoHang;
  final KhachHangDetail? khachHangDetail;
  final NhanVienDetail? nhanVienDetail;
  final List<ChiTietOrder> chiTietOrder;
  final double tongTien;
  final bool khachHangXacNhanThanhToan;

  TakeawayOrder({
    required this.id,
    this.ghiChu,
    required this.orderTime,
    required this.trangThai,
    this.thoiGianLay,
    this.thoiGianSanSang,
    this.loaiOrder,
    this.phuongThucGiaoHang,
    this.diaChiGiaoHang,
    this.khachHangDetail,
    this.nhanVienDetail,
    required this.chiTietOrder,
    required this.tongTien,
    this.khachHangXacNhanThanhToan = false,
  });

  factory TakeawayOrder.fromJson(Map<String, dynamic> json) {
    return TakeawayOrder(
      id: SafeParser.toInt(json['id']),
      ghiChu: SafeParser.toStringOrNull(json['ghi_chu']),
      orderTime: SafeParser.toDateTime(json['order_time']),
      trangThai: SafeParser.toStringSafe(json['trang_thai']),
      thoiGianLay: SafeParser.toIntOrNull(json['thoi_gian_lay']),
      thoiGianSanSang: SafeParser.toDateTimeOrNull(json['thoi_gian_san_sang']),
      loaiOrder: SafeParser.toStringOrNull(json['loai_order']),
      phuongThucGiaoHang:
          SafeParser.toStringOrNull(json['phuong_thuc_giao_hang']),
      diaChiGiaoHang: SafeParser.toStringOrNull(json['dia_chi_giao_hang']),
      khachHangDetail: json['khach_hang_detail'] != null
          ? KhachHangDetail.fromJson(json['khach_hang_detail'])
          : null,
      nhanVienDetail: json['nhan_vien_detail'] != null
          ? NhanVienDetail.fromJson(json['nhan_vien_detail'])
          : null,
      chiTietOrder: (json['chi_tiet_order'] as List)
          .map((item) => ChiTietOrder.fromJson(item))
          .toList(),
      tongTien: SafeParser.toDouble(json['tong_tien']),
      khachHangXacNhanThanhToan: json['khach_hang_xac_nhan_thanh_toan'] ?? false,
    );
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
        return 'Sẵn sàng';
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

class KhachHangDetail {
  final int id;
  final String hoTen;
  final String soDienThoai;

  KhachHangDetail({
    required this.id,
    required this.hoTen,
    required this.soDienThoai,
  });

  factory KhachHangDetail.fromJson(Map<String, dynamic> json) {
    return KhachHangDetail(
      id: SafeParser.toInt(json['id']),
      hoTen: SafeParser.toStringSafe(json['ho_ten']),
      soDienThoai: SafeParser.toStringSafe(json['so_dien_thoai']),
    );
  }
}

class NhanVienDetail {
  final int id;
  final String hoTen;
  final String chucVu;

  NhanVienDetail({
    required this.id,
    required this.hoTen,
    required this.chucVu,
  });

  factory NhanVienDetail.fromJson(Map<String, dynamic> json) {
    return NhanVienDetail(
      id: SafeParser.toInt(json['id']),
      hoTen: SafeParser.toStringSafe(json['ho_ten']),
      chucVu: SafeParser.toStringSafe(json['chuc_vu']),
    );
  }
}

class ChiTietOrder {
  final int id;
  final int soLuong;
  final int gia;
  final String trangThai;
  final MonAnDetail monAnDetail;

  ChiTietOrder({
    required this.id,
    required this.soLuong,
    required this.gia,
    required this.trangThai,
    required this.monAnDetail,
  });

  factory ChiTietOrder.fromJson(Map<String, dynamic> json) {
    return ChiTietOrder(
      id: SafeParser.toInt(json['id']),
      soLuong: SafeParser.toInt(json['so_luong']),
      gia: SafeParser.toInt(json['gia']),
      trangThai: SafeParser.toStringSafe(json['trang_thai']),
      monAnDetail: MonAnDetail.fromJson(json['mon_an_detail']),
    );
  }

  double get thanhTien => soLuong * gia.toDouble();
}

class MonAnDetail {
  final int id;
  final String tenMon;
  final double gia;
  final String? moTa;
  final String? hinhAnh;
  final String? danhMucTen;

  MonAnDetail({
    required this.id,
    required this.tenMon,
    required this.gia,
    this.moTa,
    this.hinhAnh,
    this.danhMucTen,
  });

  factory MonAnDetail.fromJson(Map<String, dynamic> json) {
    return MonAnDetail(
      id: SafeParser.toInt(json['id']),
      tenMon: SafeParser.toStringSafe(json['ten_mon']),
      gia: SafeParser.toDouble(json['gia']),
      moTa: SafeParser.toStringOrNull(json['mo_ta']),
      hinhAnh: SafeParser.toStringOrNull(json['hinh_anh']),
      danhMucTen: SafeParser.toStringOrNull(json['danh_muc_ten']),
    );
  }
}

enum TakeawayOrderStatus {
  pending,
  confirmed,
  cooking,
  ready,
  completed,
  canceled,
}

extension TakeawayOrderStatusExtension on TakeawayOrderStatus {
  String get value {
    switch (this) {
      case TakeawayOrderStatus.pending:
        return 'pending';
      case TakeawayOrderStatus.confirmed:
        return 'confirmed';
      case TakeawayOrderStatus.cooking:
        return 'cooking';
      case TakeawayOrderStatus.ready:
        return 'ready';
      case TakeawayOrderStatus.completed:
        return 'completed';
      case TakeawayOrderStatus.canceled:
        return 'canceled';
    }
  }

  String get display {
    switch (this) {
      case TakeawayOrderStatus.pending:
        return 'Chờ xác nhận';
      case TakeawayOrderStatus.confirmed:
        return 'Đã xác nhận';
      case TakeawayOrderStatus.cooking:
        return 'Đang nấu';
      case TakeawayOrderStatus.ready:
        return 'Sẵn sàng';
      case TakeawayOrderStatus.completed:
        return 'Hoàn thành';
      case TakeawayOrderStatus.canceled:
        return 'Đã hủy';
    }
  }
}
