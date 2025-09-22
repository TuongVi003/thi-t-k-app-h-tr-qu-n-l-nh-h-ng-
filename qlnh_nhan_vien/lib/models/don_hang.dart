import 'user.dart';

class DonHang {
  final int id;
  final User khachHang;
  final BanAn banAn;
  final String trangThai;
  final DateTime ngayDat;
  final dynamic khachVangLai; // có thể null

  DonHang({
    required this.id,
    required this.khachHang,
    required this.banAn,
    required this.trangThai,
    required this.ngayDat,
    this.khachVangLai,
  });

  factory DonHang.fromJson(Map<String, dynamic> json) {
    return DonHang(
      id: json['id'],
      khachHang: User.fromJson(json['khach_hang']),
      banAn: BanAn.fromJson(json['ban_an']),
      trangThai: json['trang_thai'],
      ngayDat: DateTime.parse(json['ngay_dat']),
      khachVangLai: json['khach_vang_lai'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'khach_hang': khachHang.toJson(),
      'ban_an': banAn.toJson(),
      'trang_thai': trangThai,
      'ngay_dat': ngayDat.toIso8601String(),
      'khach_vang_lai': khachVangLai,
    };
  }
}

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
      soBan: json['so_ban'],
      sucChua: json['suc_chua'],
      khuVuc: json['khu_vuc'],
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
}