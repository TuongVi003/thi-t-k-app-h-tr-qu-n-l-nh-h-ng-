class User {
  final int id;
  final String? lastLogin;
  final bool isSuperuser;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final bool isStaff;
  final bool isActive;
  final String dateJoined;
  final String hoTen;
  final String soDienThoai;

  User({
    required this.id,
    this.lastLogin,
    required this.isSuperuser,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isStaff,
    required this.isActive,
    required this.dateJoined,
    required this.hoTen,
    required this.soDienThoai,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      lastLogin: json['last_login'],
      isSuperuser: json['is_superuser'] ?? false,
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      isStaff: json['is_staff'] ?? false,
      isActive: json['is_active'] ?? true,
      dateJoined: json['date_joined'] ?? '',
      hoTen: json['ho_ten'] ?? '',
      soDienThoai: json['so_dien_thoai'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last_login': lastLogin,
      'is_superuser': isSuperuser,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'is_staff': isStaff,
      'is_active': isActive,
      'date_joined': dateJoined,
      'ho_ten': hoTen,
      'so_dien_thoai': soDienThoai,
    };
  }

  // Helper to get display name
  String get displayName {
    if (hoTen.isNotEmpty) return hoTen;
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return username;
  }

  // Helper to get display email or phone
  String get contactInfo {
    if (email.isNotEmpty) return email;
    if (soDienThoai.isNotEmpty) return soDienThoai;
    return '';
  }
}
