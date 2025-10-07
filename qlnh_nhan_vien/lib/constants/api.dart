class ApiEndpoints {
 static const String baseUrl = 'https://d9p0zhfk-8000.asse.devtunnels.ms';
  //  static const String baseUrl = 'https://p61nc0b1-8000.asse.devtunnels.ms';

  // OAuth2 endpoints
  static const String login = '$baseUrl/o/token/';
  static const String refreshToken = '$baseUrl/o/token/';
  static const String revokeToken = '$baseUrl/o/revoke_token/';
  
  // API endpoints
  static const String donHangList = '$baseUrl/api/donhang/';
  static const String userProfile = '$baseUrl/api/users/current-user/';

  // Ban An
  static const String banAnList = '$baseUrl/api/tables/';
  static String updateStatusTable(int id) => '$baseUrl/api/donhang/$id/update-status/';

  // Takeaway Orders
  static const String takeawayOrders = '$baseUrl/api/takeaway/';
  static String acceptTakeawayOrder(int id) => '$baseUrl/api/takeaway/$id/accept-order/';
  static String confirmTakeawayTime(int id) => '$baseUrl/api/takeaway/$id/confirm-time/';
  static String updateTakeawayStatus(int id) => '$baseUrl/api/takeaway/$id/update-status/';

  // User Management
  static const String checkIn = '$baseUrl/api/users/check-in/';
  static const String checkOut = '$baseUrl/api/users/check-out/';
}

class OAuth2Config {
  static const String clientId = 'EcWinP3m6Qlf6NlRv5ISsVu87uYCxGPAOoT4dQrY';
  static const String clientSecret = 'QYpTVUTIlGOO2S58fDyKWhPMkI2zCKEFmX4smjDx6y0CRN3zH7u9vfPmufvKMOLrvColVDeYYK0a7lTrQHffef8PtVCbXsAIN4bMw62A2oVl6sUn7vIZkCqNJRaULvvm';
  
}