class Conversation {
  final int id;
  final int? customerId;
  final CustomerInfo? customerInfo;
  final bool isStaffGroup;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final ChatMessage? lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    this.customerId,
    this.customerInfo,
    required this.isStaffGroup,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      customerId: json['customer'],
      customerInfo: json['customer_info'] != null 
          ? CustomerInfo.fromJson(json['customer_info']) 
          : null,
      isStaffGroup: json['is_staff_group'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at']) 
          : null,
      lastMessage: json['last_message'] != null 
          ? ChatMessage.fromJson(json['last_message']) 
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customerId,
      'customer_info': customerInfo?.toJson(),
      'is_staff_group': isStaffGroup,
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
    };
  }
}

class CustomerInfo {
  final int id;
  final String username;
  final String hoTen;
  final String loaiNguoiDung;
  final String? chucVu;

  CustomerInfo({
    required this.id,
    required this.username,
    required this.hoTen,
    required this.loaiNguoiDung,
    this.chucVu,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'],
      username: json['username'],
      hoTen: json['ho_ten'],
      loaiNguoiDung: json['loai_nguoi_dung'],
      chucVu: json['chuc_vu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'ho_ten': hoTen,
      'loai_nguoi_dung': loaiNguoiDung,
      'chuc_vu': chucVu,
    };
  }
}

class ChatMessage {
  final int id;
  final int? conversationId;
  final int? nguoiGoiId;
  final String nguoiGoiName;
  final String nguoiGoiDisplay;
  final String noiDung;
  final DateTime thoiGian;
  final CustomerInfo? nguoiGoiInfo;

  ChatMessage({
    required this.id,
    this.conversationId,
    this.nguoiGoiId,
    required this.nguoiGoiName,
    required this.nguoiGoiDisplay,
    required this.noiDung,
    required this.thoiGian,
    this.nguoiGoiInfo,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'] ?? json['conversation'],
      nguoiGoiId: json['nguoi_goi_id'] ?? json['nguoi_goi'],
      nguoiGoiName: json['nguoi_goi_name'] ?? '',
      nguoiGoiDisplay: json['nguoi_goi_display'] ?? json['nguoi_goi_name'] ?? '',
      noiDung: json['noi_dung'],
      thoiGian: DateTime.parse(json['thoi_gian']),
      nguoiGoiInfo: json['nguoi_goi_info'] != null 
          ? CustomerInfo.fromJson(json['nguoi_goi_info']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'nguoi_goi_id': nguoiGoiId,
      'nguoi_goi_name': nguoiGoiName,
      'nguoi_goi_display': nguoiGoiDisplay,
      'noi_dung': noiDung,
      'thoi_gian': thoiGian.toIso8601String(),
    };
  }

  // Override equality để so sánh messages dựa trên ID
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
