import 'package:qlnh_nhan_vien/constants/api.dart';

class AppUtils {

  static String imageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/150'; // URL ảnh mặc định
    }
    if (path.startsWith('http')) {
      return path; // Đã là URL đầy đủ
    }
    return '${ApiEndpoints.baseUrl}/images/$path'; // Thêm base URL nếu cần
  }

}