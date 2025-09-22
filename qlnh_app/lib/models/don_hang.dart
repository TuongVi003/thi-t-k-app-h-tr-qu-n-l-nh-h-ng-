class DonHang {
  final int id;
  final String trangThai;
  final DateTime ngayDat;
  final int banAn;

  DonHang({
    required this.id,
    required this.trangThai,
    required this.ngayDat,
    required this.banAn,
  });

  factory DonHang.fromJson(Map<String, dynamic> json) {
    return DonHang(
      id: json['id'] as int,
      trangThai: json['trang_thai'] as String,
      ngayDat: DateTime.parse(json['ngay_dat'] as String),
      banAn: json['ban_an'] as int,
    );
  }

}