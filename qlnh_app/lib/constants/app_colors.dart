import 'package:flutter/material.dart';

/// Class quản lý màu sắc của ứng dụng
/// Sử dụng tông màu xanh lam (blue/teal) chuyên nghiệp và hiện đại
class AppColors {
  AppColors._(); // Private constructor để ngăn khởi tạo

  // Màu chính - Primary Colors
  static const Color primary = Color(0xFF0D47A1); // Xanh dương đậm chuyên nghiệp
  static const Color primaryLight = Color(0xFF5472D3); // Xanh dương sáng
  static const Color primaryDark = Color(0xFF002171); // Xanh dương đậm hơn
  static const Color primaryVeryLight = Color(0xFFE3F2FD); // Xanh dương rất nhạt

  // Màu phụ - Accent Colors
  static const Color accent = Color(0xFF00897B); // Xanh ngọc (teal)
  static const Color accentLight = Color(0xFF4EBAAA); // Xanh ngọc sáng
  static const Color accentDark = Color(0xFF005B4F); // Xanh ngọc đậm

  // Màu nền - Background Colors
  static const Color background = Color(0xFFF5F7FA); // Xám nhạt tinh tế
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Màu text - Text Colors
  static const Color textPrimary = Color(0xFF212121); // Đen nhạt
  static const Color textSecondary = Color(0xFF757575); // Xám
  static const Color textLight = Color(0xFF9E9E9E); // Xám nhạt
  static const Color textWhite = Colors.white;

  // Màu trạng thái - Status Colors
  static const Color success = Color(0xFF2E7D32); // Xanh lá đậm
  static const Color successLight = Color(0xFF66BB6A); // Xanh lá sáng
  static const Color successBackground = Color(0xFFE8F5E9); // Nền xanh lá nhạt

  static const Color warning = Color(0xFFF57C00); // Cam cảnh báo
  static const Color warningLight = Color(0xFFFFB74D); // Cam sáng
  static const Color warningBackground = Color(0xFFFFF3E0); // Nền cam nhạt

  static const Color error = Color(0xFFD32F2F); // Đỏ lỗi
  static const Color errorLight = Color(0xFFEF5350); // Đỏ sáng
  static const Color errorBackground = Color(0xFFFFEBEE); // Nền đỏ nhạt

  static const Color info = Color(0xFF1976D2); // Xanh thông tin
  static const Color infoLight = Color(0xFF64B5F6); // Xanh sáng
  static const Color infoBackground = Color(0xFFE3F2FD); // Nền xanh nhạt

  // Màu cho trạng thái đơn hàng
  static const Color orderPending = Color(0xFFFF9800); // Cam - Chờ xác nhận
  static const Color orderProcessing = Color(0xFF2196F3); // Xanh dương - Đang xử lý
  static const Color orderReady = Color(0xFF9C27B0); // Tím - Sẵn sàng
  static const Color orderCompleted = Color(0xFF4CAF50); // Xanh lá - Hoàn thành
  static const Color orderCancelled = Color(0xFFF44336); // Đỏ - Đã hủy

  // Màu border và divider
  static const Color border = Color(0xFFE0E0E0); // Xám nhạt
  static const Color borderLight = Color(0xFFEEEEEE); // Xám rất nhạt
  static const Color divider = Color(0xFFBDBDBD); // Xám chia cách

  // Màu shadow
  static const Color shadow = Color(0x1A000000); // Đen với độ mờ 10%
  static const Color shadowLight = Color(0x0D000000); // Đen với độ mờ 5%

  // Gradient cho các hiệu ứng đẹp
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Màu cho các category/chip
  static const Color chipBackground = Color(0xFFE8EAF6); // Tím nhạt
  static const Color chipSelectedBackground = Color(0xFF3F51B5); // Tím đậm
  static const Color chipText = Color(0xFF3F51B5); // Tím đậm
  static const Color chipSelectedText = Colors.white;

  // Màu cho button
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  static const Color buttonTextDisabled = Color(0xFF9E9E9E);
}
