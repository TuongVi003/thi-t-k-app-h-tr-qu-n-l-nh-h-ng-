class Conversation {
  final int id;
  final int? customerId;
  final String? customerName;
  final bool isStaffGroup;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final ChatMessageSimple? lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    this.customerId,
    this.customerName,
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
      customerName: json['customer_info']?['ho_ten'],
      isStaffGroup: json['is_staff_group'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      lastMessage: json['last_message'] != null
          ? ChatMessageSimple.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customerId,
      'is_staff_group': isStaffGroup,
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
    };
  }
}

class ChatMessageSimple {
  final int id;
  final String noiDung;
  final DateTime thoiGian;
  final String nguoiGoiName;

  ChatMessageSimple({
    required this.id,
    required this.noiDung,
    required this.thoiGian,
    required this.nguoiGoiName,
  });

  factory ChatMessageSimple.fromJson(Map<String, dynamic> json) {
    return ChatMessageSimple(
      id: json['id'],
      noiDung: json['noi_dung'],
      thoiGian: DateTime.parse(json['thoi_gian']),
      nguoiGoiName: json['nguoi_goi_name'],
    );
  }
}
