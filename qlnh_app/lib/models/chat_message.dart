class ChatMessage {
  final int id;
  final int conversationId;
  final int nguoiGoiId;
  final String nguoiGoiName;
  final String nguoiGoiDisplay;
  final String noiDung;
  final DateTime thoiGian;
  final bool isSentByMe;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.nguoiGoiId,
    required this.nguoiGoiName,
    required this.nguoiGoiDisplay,
    required this.noiDung,
    required this.thoiGian,
    this.isSentByMe = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final nguoiGoiId = json['nguoi_goi_id'] ?? json['nguoi_goi'];
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'] ?? json['conversation'],
      nguoiGoiId: nguoiGoiId,
      nguoiGoiName: json['nguoi_goi_name'] ?? '',
      nguoiGoiDisplay: json['nguoi_goi_display'] ?? json['nguoi_goi_name'] ?? '',
      noiDung: json['noi_dung'],
      thoiGian: DateTime.parse(json['thoi_gian']),
      isSentByMe: currentUserId != null && nguoiGoiId == currentUserId,
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

  // Tạo message tạm thời khi đang gửi
  static ChatMessage temporary({
    required String noiDung,
    required int nguoiGoiId,
    required String nguoiGoiName,
    required int conversationId,
  }) {
    // Use negative id for temporary client-side messages so we can
    // distinguish them from server-persisted messages (which have positive ids)
    return ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch, // temporary negative id
      conversationId: conversationId,
      nguoiGoiId: nguoiGoiId,
      nguoiGoiName: nguoiGoiName,
      nguoiGoiDisplay: nguoiGoiName,
      noiDung: noiDung,
      thoiGian: DateTime.now(),
      isSentByMe: true,
    );
  }
}
