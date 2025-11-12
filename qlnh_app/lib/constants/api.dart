

class ApiEndpoints {
  // static const String baseUrl = 'https://d9p0zhfk-8000.asse.devtunnels.ms';
  static const String baseUrl = 'https://p61nc0b1-8000.asse.devtunnels.ms';

  // static const String socketUrl = 'https://d9p0zhfk-8001.asse.devtunnels.ms';
  static const String socketUrl = 'https://p61nc0b1-8001.asse.devtunnels.ms';

  static const String login = '$baseUrl/o/token/';
  static const String register = '$baseUrl/api/users/';
  static const String about = '$baseUrl/api/about-us/';

  // Đặt bàn
  static const String makeReservation = '$baseUrl/api/donhang/';

  // Lấy menu
  static const String menu = '$baseUrl/api/menu/';
  static const String categories = '$baseUrl/api/categories/';

  // Takeaway orders
  static const String takeawayOrders = '$baseUrl/api/takeaway/';
  static String getTakeawayOrder(int id) => '$baseUrl/api/takeaway/$id/';
  
  // User profile
  static const String userProfile = '$baseUrl/api/users/current-user/';
  
  // Notifications
  static const String notifications = '$baseUrl/api/notifications/';
  
  // Socket cleanup
  static const String cleanupSocket = '$baseUrl/api/cleanup-socket/';
}
