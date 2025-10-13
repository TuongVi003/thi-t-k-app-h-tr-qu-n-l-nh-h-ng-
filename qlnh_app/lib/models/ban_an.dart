class BanAn {
  final int id;
  final int soban;
  final int sucChua;
  final String khuVuc;
  final String status;

  BanAn({
    required this.id,
    required this.soban,
    required this.sucChua,
    required this.khuVuc,
    required this.status,
  });

  factory BanAn.fromJson(Map<String, dynamic> json) {
    return BanAn(
      id: json['id'] as int,
      soban: json['so_ban'] as int,
      sucChua: json['suc_chua'] as int,
      khuVuc: json['khu_vuc'] as String,
      status: json['status'] as String,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isUnderMaintenance => status == 'maintenance';
}