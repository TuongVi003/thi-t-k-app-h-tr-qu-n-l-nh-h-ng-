enum BookingStatus {
  confirmed,  // Đã xác nhận
  pending,    // Chờ xác nhận
  cancelled,  // Đã hủy
  completed   // Đã hoàn thành
}

class Booking {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final DateTime bookingTime;
  final int numberOfGuests;
  final String? tableId;
  final int? preferredTableNumber;
  BookingStatus status;
  final DateTime createdAt;
  String? specialRequests;
  String? notes;

  Booking({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.bookingTime,
    required this.numberOfGuests,
    this.tableId,
    this.preferredTableNumber,
    this.status = BookingStatus.pending,
    DateTime? createdAt,
    this.specialRequests,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Booking copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    DateTime? bookingTime,
    int? numberOfGuests,
    String? tableId,
    int? preferredTableNumber,
    BookingStatus? status,
    DateTime? createdAt,
    String? specialRequests,
    String? notes,
  }) {
    return Booking(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      bookingTime: bookingTime ?? this.bookingTime,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      tableId: tableId ?? this.tableId,
      preferredTableNumber: preferredTableNumber ?? this.preferredTableNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      specialRequests: specialRequests ?? this.specialRequests,
      notes: notes ?? this.notes,
    );
  }

  bool isToday() {
    final now = DateTime.now();
    return bookingTime.year == now.year &&
           bookingTime.month == now.month &&
           bookingTime.day == now.day;
  }

  bool isUpcoming() {
    return bookingTime.isAfter(DateTime.now());
  }

  bool isPastDue() {
    return bookingTime.isBefore(DateTime.now()) && 
           status != BookingStatus.completed;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'bookingTime': bookingTime.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      'tableId': tableId,
      'preferredTableNumber': preferredTableNumber,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'specialRequests': specialRequests,
      'notes': notes,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      bookingTime: DateTime.parse(json['bookingTime']),
      numberOfGuests: json['numberOfGuests'],
      tableId: json['tableId'],
      preferredTableNumber: json['preferredTableNumber'],
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      specialRequests: json['specialRequests'],
      notes: json['notes'],
    );
  }
}