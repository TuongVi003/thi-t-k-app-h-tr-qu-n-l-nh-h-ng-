enum TableStatus {
  available,   // Bàn trống
  occupied,    // Bàn đã có khách
  reserved,    // Bàn đã đặt trước
  cleaning     // Bàn đang dọn dẹp
}

// Converter functions for API status
TableStatus getTableStatusFromApiStatus(String apiStatus) {
  switch (apiStatus.toLowerCase()) {
    case 'pending':
      return TableStatus.reserved;
    case 'confirmed':
      return TableStatus.reserved;
    case 'completed':
      return TableStatus.available;
    case 'cancelled':
      return TableStatus.available;
    default:
      return TableStatus.available;
  }
}

class Table {
  final String id;
  final int number;
  final int capacity;
  TableStatus status;
  String? customerId;
  String? customerName;
  String? customerPhone;
  DateTime? reservationTime;
  String? notes;

  Table({
    required this.id,
    required this.number,
    required this.capacity,
    this.status = TableStatus.available,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.reservationTime,
    this.notes,
  });

  // Copy constructor để cập nhật trạng thái
  Table copyWith({
    String? id,
    int? number,
    int? capacity,
    TableStatus? status,
    String? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? reservationTime,
    String? notes,
  }) {
    return Table(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      reservationTime: reservationTime ?? this.reservationTime,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'capacity': capacity,
      'status': status.toString(),
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'reservationTime': reservationTime?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Table.fromJson(Map<String, dynamic> json) {
    return Table(
      id: json['id'],
      number: json['number'],
      capacity: json['capacity'],
      status: TableStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TableStatus.available,
      ),
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      reservationTime: json['reservationTime'] != null 
          ? DateTime.parse(json['reservationTime']) 
          : null,
      notes: json['notes'],
    );
  }

  // Factory constructor để tạo Table từ DonHang API
  factory Table.fromDonHangApi(Map<String, dynamic> donHangJson) {
    final banAn = donHangJson['ban_an'];
    final khachHang = donHangJson['khach_hang'];
    
    return Table(
      id: banAn['id'].toString(),
      number: banAn['so_ban'],
      capacity: banAn['suc_chua'],
      status: getTableStatusFromApiStatus(donHangJson['trang_thai']),
      customerName: khachHang['ho_ten'],
      customerPhone: khachHang['so_dien_thoai'],
      reservationTime: DateTime.parse(donHangJson['ngay_dat']),
      notes: 'Khu vực: ${banAn['khu_vuc']}',
    );
  }
}