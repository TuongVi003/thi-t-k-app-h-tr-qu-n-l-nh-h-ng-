class BanAn {
  final int id;
  final int soBan;
  final int sucChua;
  final String khuVuc;

  BanAn({
    required this.id,
    required this.soBan,
    required this.sucChua,
    required this.khuVuc,
  });

  factory BanAn.fromJson(Map<String, dynamic> json) {
    return BanAn(
      id: json['id'],
      soBan: json['so_ban'] ?? 0,
      sucChua: json['suc_chua'] ?? 0,
      khuVuc: json['khu_vuc'] ?? 'inside',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'so_ban': soBan,
      'suc_chua': sucChua,
      'khu_vuc': khuVuc,
    };
  }

  String getKhuVucText() {
    switch (khuVuc) {
      case 'inside':
        return 'Trong nhà';
      case 'outside':
        return 'Ngoài trời';
      case 'private-room':
        return 'VIP';
      default:
        return khuVuc;
    }
  }
}
