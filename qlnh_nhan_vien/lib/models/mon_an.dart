class MonAn {
  final int id;
  final String tenMon;
  final double gia;
  final String? moTa;
  final int? danhMuc;
  final bool available;
  final String? hinhAnh;

  MonAn({
    required this.id,
    required this.tenMon,
    required this.gia,
    this.moTa,
    this.danhMuc,
    required this.available,
    this.hinhAnh,
  });

  factory MonAn.fromJson(Map<String, dynamic> json) {
    // Parse gia - có thể là String hoặc number từ API
    double parseGia(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return MonAn(
      id: json['id'],
      tenMon: json['ten_mon'] ?? '',
      gia: parseGia(json['gia']),
      moTa: json['mo_ta'],
      danhMuc: json['danh_muc'],
      available: json['available'] ?? true,
      hinhAnh: json['hinh_anh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten_mon': tenMon,
      'gia': gia,
      'mo_ta': moTa,
      'danh_muc': danhMuc,
      'available': available,
      'hinh_anh': hinhAnh,
    };
  }
}
