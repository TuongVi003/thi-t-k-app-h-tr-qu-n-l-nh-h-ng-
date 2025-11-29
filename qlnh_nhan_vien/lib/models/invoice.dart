class Invoice {
  final int id;
  final List<InvoiceItem> chiTietMonAn;
  final double tongTienMonAn;
  final double tongGiamGia;
  final String phiGiaoHang;
  final double tongTienCuoiCung;
  final DateTime ngayTao;
  final String paymentMethod;
  final CustomerInfo? khachHangInfo;
  final List<int> khuyenMai;

  Invoice({
    required this.id,
    required this.chiTietMonAn,
    required this.tongTienMonAn,
    required this.tongGiamGia,
    required this.phiGiaoHang,
    required this.tongTienCuoiCung,
    required this.ngayTao,
    required this.paymentMethod,
    this.khachHangInfo,
    required this.khuyenMai,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      chiTietMonAn: (json['chi_tiet_mon_an'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
      tongTienMonAn: (json['tong_tien_mon_an'] as num).toDouble(),
      tongGiamGia: (json['tong_giam_gia'] as num).toDouble(),
      phiGiaoHang: json['phi_giao_hang'].toString(),
      tongTienCuoiCung: (json['tong_tien_cuoi_cung'] as num).toDouble(),
      ngayTao: DateTime.parse(json['ngay_tao']),
      paymentMethod: json['payment_method'],
      khachHangInfo: json['khach_hang_info'] != null 
          ? CustomerInfo.fromJson(json['khach_hang_info'])
          : null,
      khuyenMai: List<int>.from(json['khuyen_mai']),
    );
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'cash':
        return 'Tiền mặt';
      case 'card':
        return 'Thẻ/QR';
      default:
        return 'Chưa xác định';
    }
  }
}

class InvoiceItem {
  final int monAnId;
  final String tenMon;
  final int soLuong;
  final double giaDonVi;
  final double thanhTien;
  final String? hinhAnh;

  InvoiceItem({
    required this.monAnId,
    required this.tenMon,
    required this.soLuong,
    required this.giaDonVi,
    required this.thanhTien,
    this.hinhAnh,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      monAnId: json['mon_an_id'],
      tenMon: json['ten_mon'],
      soLuong: json['so_luong'],
      giaDonVi: (json['gia_don_vi'] as num).toDouble(),
      thanhTien: (json['thanh_tien'] as num).toDouble(),
      hinhAnh: json['hinh_anh'],
    );
  }
}

class CustomerInfo {
  final int id;
  final String hoTen;
  final String soDienThoai;

  CustomerInfo({
    required this.id,
    required this.hoTen,
    required this.soDienThoai,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'],
      hoTen: json['ho_ten'],
      soDienThoai: json['so_dien_thoai'],
    );
  }
}
