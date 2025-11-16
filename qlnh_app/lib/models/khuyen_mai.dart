class KhuyenMai {
  final int id;
  final String tenKhuyenMai;
  final String moTa;
  final String loaiGiamGia; // 'percentage' or 'fixed_amount'
  final String giaTri;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final bool active;
  final String? bannerImage;

  KhuyenMai({
    required this.id,
    required this.tenKhuyenMai,
    required this.moTa,
    required this.loaiGiamGia,
    required this.giaTri,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    required this.active,
    this.bannerImage,
  });

  factory KhuyenMai.fromJson(Map<String, dynamic> json) {
    return KhuyenMai(
      id: json['id'] as int,
      tenKhuyenMai: json['ten_khuyen_mai'] as String,
      moTa: json['mo_ta'] as String,
      loaiGiamGia: json['loai_giam_gia'] as String,
      giaTri: json['gia_tri'] as String,
      ngayBatDau: DateTime.parse(json['ngay_bat_dau'] as String),
      ngayKetThuc: DateTime.parse(json['ngay_ket_thuc'] as String),
      active: json['active'] as bool,
      bannerImage: json['banner_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten_khuyen_mai': tenKhuyenMai,
      'mo_ta': moTa,
      'loai_giam_gia': loaiGiamGia,
      'gia_tri': giaTri,
      'ngay_bat_dau': ngayBatDau.toIso8601String(),
      'ngay_ket_thuc': ngayKetThuc.toIso8601String(),
      'active': active,
      'banner_image': bannerImage,
    };
  }

  // Helper methods
  bool get isActive {
    final now = DateTime.now();
    return active && now.isAfter(ngayBatDau) && now.isBefore(ngayKetThuc);
  }

  String get displayDiscount {
    final value = double.parse(giaTri);
    final displayValue = value == value.toInt() ? value.toInt().toString() : value.toString();
    
    if (loaiGiamGia == 'percentage') {
      return '$displayValue%';
    } else {
      return '${displayValue}đ';
    }
  }

  String get displayType {
    final value = double.parse(giaTri);
    final displayValue = value == value.toInt() ? value.toInt().toString() : value.toString();
    
    if (loaiGiamGia == 'percentage') {
      return 'Giảm $displayValue%';
    } else {
      return 'Giảm ${displayValue}đ';
    }
  }
}
