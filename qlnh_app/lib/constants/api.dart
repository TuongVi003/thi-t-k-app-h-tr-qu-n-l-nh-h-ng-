

class ApiEndpoints {
  static const String baseUrl = 'https://d9p0zhfk-8000.asse.devtunnels.ms';

  static const String login = '$baseUrl/o/token/';
  static const String register = '$baseUrl/api/users/';

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
}
