import 'package:flutter/material.dart';
import 'user.dart';

enum DonHangStatus {
  pending,
  confirmed,
  canceled;

  String get displayName {
    switch (this) {
      case DonHangStatus.pending:
        return 'Chờ xác nhận';
      case DonHangStatus.confirmed:
        return 'Đã xác nhận';
      case DonHangStatus.canceled:
        return 'Đã hủy';
    }
  }

  String get apiValue {
    switch (this) {
      case DonHangStatus.pending:
        return 'pending';
      case DonHangStatus.confirmed:
        return 'confirmed';
      case DonHangStatus.canceled:
        return 'canceled';
    }
  }

  static DonHangStatus fromApiValue(String value) {
    switch (value) {
      case 'pending':
        return DonHangStatus.pending;
      case 'confirmed':
        return DonHangStatus.confirmed;
      case 'canceled':
        return DonHangStatus.canceled;
      default:
        return DonHangStatus.pending;
    }
  }

  Color get color {
    switch (this) {
      case DonHangStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case DonHangStatus.confirmed:
        return const Color(0xFF4CAF50); // Green
      case DonHangStatus.canceled:
        return const Color(0xFFF44336); // Red
    }
  }
}

class DonHang {
  final int id;
  final User khachHang;
  final BanAn? banAn;
  final DonHangStatus trangThai;
  final DateTime ngayDat;
  final dynamic khachVangLai; // có thể null

  DonHang({
    required this.id,
    required this.khachHang,
    this.banAn,
    required this.trangThai,
    required this.ngayDat,
    this.khachVangLai,
  });

  factory DonHang.fromJson(Map<String, dynamic> json) {
    // Xử lý khách hàng: nếu null thì tạo User giả từ thông tin khách vãng lai
    User customer;
    if (json['khach_hang'] != null) {
      customer = User.fromJson(json['khach_hang']);
    } else {
      // Tạo User giả từ current_customer hoặc khách vãng lai
      String name = 'Khách vãng lai';
      String phone = '';
      
      if (json['ban_an']?['current_customer'] != null) {
        name = json['ban_an']['current_customer']['name'] ?? 'Khách vãng lai';
        phone = json['ban_an']['current_customer']['phone'] ?? '';
      }
      
      customer = User(
        id: 0,
        username: 'guest_${json['id']}',
        hoTen: name,
        soDienThoai: phone,
        loaiNguoiDung: 'khach_vang_lai',
        chucVu: 'customer',
        isActive: true,
        dateJoined: DateTime.now(),
        dangLamViec: false,
      );
    }
    
    return DonHang(
      id: json['id'],
      khachHang: customer,
      banAn: json['ban_an'] != null ? BanAn.fromJson(json['ban_an']) : null,
      trangThai: DonHangStatus.fromApiValue(json['trang_thai']),
      ngayDat: DateTime.parse(json['ngay_dat']),
      khachVangLai: json['khach_vang_lai'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'khach_hang': khachHang.toJson(),
      'ban_an': banAn?.toJson(),
      'trang_thai': trangThai.apiValue,
      'ngay_dat': ngayDat.toIso8601String(),
      'khach_vang_lai': khachVangLai,
    };
  }

  // Phương thức để tạo bản sao với trạng thái mới
  DonHang copyWith({
    int? id,
    User? khachHang,
    BanAn? banAn,
    DonHangStatus? trangThai,
    DateTime? ngayDat,
    dynamic khachVangLai,
  }) {
    return DonHang(
      id: id ?? this.id,
      khachHang: khachHang ?? this.khachHang,
      banAn: banAn ?? this.banAn,
      trangThai: trangThai ?? this.trangThai,
      ngayDat: ngayDat ?? this.ngayDat,
      khachVangLai: khachVangLai ?? this.khachVangLai,
    );
  }
}

class BanAn {
  final int id;
  final int soBan;
  final int sucChua;
  final String khuVuc;
  final String? status; // e.g. 'occupied' | 'available'
  final CurrentCustomer? currentCustomer;

  BanAn({
    required this.id,
    required this.soBan,
    required this.sucChua,
    required this.khuVuc,
    this.status,
    this.currentCustomer,
  });

  factory BanAn.fromJson(Map<String, dynamic> json) {
    return BanAn(
      id: json['id'],
      soBan: json['so_ban'],
      sucChua: json['suc_chua'],
      khuVuc: json['khu_vuc'],
      status: json['status'],
      currentCustomer: json['current_customer'] != null
          ? CurrentCustomer.fromJson(json['current_customer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'so_ban': soBan,
      'suc_chua': sucChua,
      'khu_vuc': khuVuc,
      'status': status,
      'current_customer': currentCustomer?.toJson(),
    };
  }
}

class CurrentCustomer {
  final String type; // 'registered' or 'guest'
  final String name;
  final String phone;

  CurrentCustomer({
    required this.type,
    required this.name,
    required this.phone,
  });

  factory CurrentCustomer.fromJson(Map<String, dynamic> json) {
    return CurrentCustomer(
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'phone': phone,
    };
  }
}