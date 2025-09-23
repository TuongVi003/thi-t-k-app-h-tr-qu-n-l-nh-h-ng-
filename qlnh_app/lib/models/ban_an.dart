class BanAn {
  final int id;
  final int soban;
  final int sucChua;
  final String khuVuc;

  BanAn({
    required this.id,
    required this.soban,
    required this.sucChua,
    required this.khuVuc,
  });

  factory BanAn.fromJson(Map<String, dynamic> json) {
    return BanAn(
      id: json['id'] as int,
      soban: json['so_ban'] as int,
      sucChua: json['suc_chua'] as int,
      khuVuc: json['khu_vuc'] as String,
    );
  }
}