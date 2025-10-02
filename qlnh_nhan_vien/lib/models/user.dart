import '../utils/safe_parser.dart';

class User {
  final int id;
  final String username;
  final String hoTen;
  final String soDienThoai;
  final String loaiNguoiDung;
  final String chucVu;
  final String? caLam;
  final bool dangLamViec;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime dateJoined;
  final String? email;

  User({
    required this.id,
    required this.username,
    required this.hoTen,
    required this.soDienThoai,
    required this.loaiNguoiDung,
    required this.chucVu,
    this.caLam,
    required this.dangLamViec,
    required this.isActive,
    this.lastLogin,
    required this.dateJoined,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: SafeParser.toInt(json['id']),
      username: json['username'],
      hoTen: json['ho_ten'] ?? '',
      soDienThoai: json['so_dien_thoai'] ?? '',
      loaiNguoiDung: json['loai_nguoi_dung'] ?? '',
      chucVu: json['chuc_vu'] ?? '',
      caLam: json['ca_lam'],
      dangLamViec: SafeParser.toBool(json['dang_lam_viec']),
      isActive: SafeParser.toBool(json['is_active'] ?? true),
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      dateJoined: DateTime.parse(json['date_joined']),
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'ho_ten': hoTen,
      'so_dien_thoai': soDienThoai,
      'loai_nguoi_dung': loaiNguoiDung,
      'chuc_vu': chucVu,
      'ca_lam': caLam,
      'dang_lam_viec': dangLamViec,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'date_joined': dateJoined.toIso8601String(),
      'email': email,
    };
  }
}