
class DanhMuc {
  final int id;
  final String tenDanhMuc;

  DanhMuc({
    required this.id,
    required this.tenDanhMuc
  });

  factory DanhMuc.fromJson(Map<String, dynamic> json) {
    return DanhMuc(
      id: json['id'],
      tenDanhMuc: json['ten_danh_muc']
    );
  }
}
