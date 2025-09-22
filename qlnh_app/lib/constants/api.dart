

class ApiEndpoints {
  static const String baseUrl = 'https://d9p0zhfk-8000.asse.devtunnels.ms';

  static const String login = '$baseUrl/o/token/';
  static const String register = '$baseUrl/api/users/';

  // Đặt bàn
  static const String makeReservation = '$baseUrl/api/donhang/';

  // static const String fetchUserProfile = '$baseUrl/api/user/profile';
  // static const String updateUserProfile = '$baseUrl/api/user/update';
  // static const String fetchItems = '$baseUrl/api/items';
  // static const String fetchItemDetails = '$baseUrl/api/items/details';
}
