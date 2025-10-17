enum TableStatus {
  available,   // Bàn trống
  occupied,    // Bàn đã có khách
  reserved,    // Bàn đã đặt trước
  cleaning     // Bàn đang dọn dẹp
}

enum CustomerType {
  registered,  // Khách hàng đã đăng ký
  guest,       // Khách vãng lai
}

enum AreaType {
  inside,      // Trong nhà
  outside,     // Ngoài trời
  privateRoom, // VIP
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
  AreaType area;
  String? customerId;
  String? customerName;
  String? customerPhone;
  CustomerType? customerType;
  DateTime? reservationTime;
  String? occupancyType; // 'reservation' or 'walk-in'
  String? notes;

  Table({
    required this.id,
    required this.number,
    required this.capacity,
    this.status = TableStatus.available,
    this.area = AreaType.inside,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerType,
    this.reservationTime,
    this.occupancyType,
    this.notes,
  });

  // Copy constructor để cập nhật trạng thái
  Table copyWith({
    String? id,
    int? number,
    int? capacity,
    TableStatus? status,
    AreaType? area,
    String? customerId,
    String? customerName,  
    String? customerPhone,
    CustomerType? customerType,
    DateTime? reservationTime,
    String? occupancyType,
    String? notes,
  }) {
    return Table(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      area: area ?? this.area,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerType: customerType ?? this.customerType,
      reservationTime: reservationTime ?? this.reservationTime,
      occupancyType: occupancyType ?? this.occupancyType,
      notes: notes ?? this.notes,
    );
  }  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'capacity': capacity,
      'status': status.toString(),
      'area': area.toString(),
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerType': customerType?.toString(),
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
      area: json['area'] != null 
          ? AreaType.values.firstWhere(
              (e) => e.toString() == json['area'],
              orElse: () => AreaType.inside,
            )
          : AreaType.inside,
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerType: json['customerType'] != null 
          ? CustomerType.values.firstWhere(
              (e) => e.toString() == json['customerType'],
              orElse: () => CustomerType.registered,
            )
          : null,
      reservationTime: json['reservationTime'] != null 
          ? DateTime.parse(json['reservationTime']) 
          : null,
      notes: json['notes'],
    );
  }

  // Factory constructor để tạo Table từ Tables API mới
  factory Table.fromTablesApi(Map<String, dynamic> tableJson) {
    TableStatus status;
    switch (tableJson['status']?.toLowerCase()) {
      case 'occupied':
        status = TableStatus.occupied;
        break;
      case 'available':
        status = TableStatus.available;
        break;
      default:
        status = TableStatus.available;
    }
    
    // Xử lý khu vực
    AreaType area = _getAreaTypeFromString(tableJson['khu_vuc']);
    String khuVucDisplay = _getKhuVucDisplay(tableJson['khu_vuc']);
    
    // Xử lý thông tin khách hàng
    String? customerName;
    String? customerPhone;
    CustomerType? customerType;
    
    final currentCustomer = tableJson['current_customer'];
    if (currentCustomer != null) {
      customerName = currentCustomer['name'];
      customerPhone = currentCustomer['phone'];
      
      switch (currentCustomer['type']?.toLowerCase()) {
        case 'registered':
          customerType = CustomerType.registered;
          break;
        case 'guest':
          customerType = CustomerType.guest;
          break;
        default:
          customerType = CustomerType.registered;
      }
    }
    
    // Xử lý occupancy_time
    DateTime? reservationTime;
    String? occupancyType;
    final occupancyTimeData = tableJson['occupancy_time'];
    if (occupancyTimeData != null) {
      occupancyType = occupancyTimeData['type']; // 'reservation' or 'walk-in'
      if (occupancyTimeData['datetime'] != null) {
        try {
          reservationTime = DateTime.parse(occupancyTimeData['datetime']);
        } catch (e) {
          print('Error parsing datetime: $e');
        }
      }
    }
    
    String notes = 'Khu vực: $khuVucDisplay';
    if (customerName != null) {
      String customerTypeText = customerType == CustomerType.guest ? 'Khách vãng lai' : 'Khách hàng';
      notes += '\n$customerTypeText: $customerName';
      if (customerPhone != null) {
        notes += ' - $customerPhone';
      }
    }
    
    return Table(
      id: tableJson['id'].toString(),
      number: tableJson['so_ban'],
      capacity: tableJson['suc_chua'],
      status: status,
      area: area,
      customerName: customerName,
      customerPhone: customerPhone,
      customerType: customerType,
      reservationTime: reservationTime,
      occupancyType: occupancyType,
      notes: notes,
    );
  }

  // Hàm hỗ trợ để chuyển đổi khu vực từ string sang enum
  static AreaType _getAreaTypeFromString(String khuVuc) {
    switch (khuVuc) {
      case 'inside':
        return AreaType.inside;
      case 'outside':
        return AreaType.outside;
      case 'private-room':
        return AreaType.privateRoom;
      default:
        return AreaType.inside;
    }
  }

  // Hàm hỗ trợ để chuyển đổi khu vực hiển thị
  static String _getKhuVucDisplay(String khuVuc) {
    switch (khuVuc) {
      case 'inside':
        return 'Trong nhà';
      case 'outside':
        return 'Ngoài trời';
      case 'private-room':
        return 'VIP';
      default:
        return khuVuc;
    }
  }

  // Getter để lấy tên loại khách hàng
  String get customerTypeDisplayName {
    if (customerType == null) return '';
    switch (customerType!) {
      case CustomerType.registered:
        return 'Khách hàng';
      case CustomerType.guest:
        return 'Khách vãng lai';
    }
  }

  // Getter để lấy tên hiển thị khu vực
  String get areaDisplayName {
    switch (area) {
      case AreaType.inside:
        return 'Trong nhà';
      case AreaType.outside:
        return 'Ngoài trời';
      case AreaType.privateRoom:
        return 'VIP';
    }
  }

  // Getter để kiểm tra có khách hàng hay không
  bool get hasCustomer => customerName != null && customerName!.isNotEmpty;

  // Getter để format thời gian hiển thị
  String get reservationTimeDisplay {
    if (reservationTime == null) return '';
    // Convert UTC to Vietnam timezone (UTC+7)
    final localTime = reservationTime!.add(const Duration(hours: 7));
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Getter để lấy text loại đặt bàn
  String get occupancyTypeDisplay {
    if (occupancyType == null) return '';
    switch (occupancyType!) {
      case 'reservation':
        return 'Đặt trước';
      case 'walk-in':
        return 'Khách vãng lai';
      default:
        return occupancyType!;
    }
  }

  // Factory constructor để tạo Table từ DonHang API (deprecated - giữ lại để tương thích)
  factory Table.fromDonHangApi(Map<String, dynamic> donHangJson) {
    final banAn = donHangJson['ban_an'];
    final khachHang = donHangJson['khach_hang'];
    
    return Table(
      id: banAn['id'].toString(),
      number: banAn['so_ban'],
      capacity: banAn['suc_chua'],
      status: getTableStatusFromApiStatus(donHangJson['trang_thai']),
      area: _getAreaTypeFromString(banAn['khu_vuc']),
      customerName: khachHang['ho_ten'],
      customerPhone: khachHang['so_dien_thoai'],
      customerType: CustomerType.registered,
      reservationTime: DateTime.parse(donHangJson['ngay_dat']),
      notes: 'Khu vực: ${banAn['khu_vuc']}',
    );
  }
}