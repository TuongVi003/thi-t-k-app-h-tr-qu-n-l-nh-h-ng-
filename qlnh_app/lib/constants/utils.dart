import 'package:qlnh_app/constants/api.dart';

class Utils {
  static String imageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    return '${ApiEndpoints.baseUrl}/images/$path';
  }
}