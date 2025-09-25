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
  final BanAn banAn;
  final DonHangStatus trangThai;
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
      trangThai: DonHangStatus.fromApiValue(json['trang_thai']),
      ngayDat: DateTime.parse(json['ngay_dat']),
      khachVangLai: json['khach_vang_lai'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'khach_hang': khachHang.toJson(),
      'ban_an': banAn.toJson(),
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