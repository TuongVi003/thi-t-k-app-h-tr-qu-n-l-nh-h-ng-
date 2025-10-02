class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
  });
}


class MonAn {
  final int id;
  final String tenMon;
  final String moTa;
  final double gia;
  final String? hinhAnh;
  final String? tenDanhMuc;

  MonAn({
    required this.id,
    required this.tenMon,
    required this.moTa,
    required this.gia,
    this.hinhAnh,
    this.tenDanhMuc,
  });

  factory MonAn.fromJson(Map<String, dynamic> json) {
    return MonAn(
      id: json['id'],
      tenMon: json['ten_mon'],
      moTa: json['mo_ta'],
      gia: json['gia'] is num
          ? (json['gia'] as num).toDouble()
          : double.tryParse(json['gia']?.toString() ?? '') ?? 0.0,
      hinhAnh: json['hinh_anh'],
      tenDanhMuc: json['danh_muc_ten'],
    );
  }
}
