import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import 'auth_service.dart';

class ChatService {
  ChatService._privateConstructor();

  static final ChatService instance = ChatService._privateConstructor();

  IO.Socket? _socket;
  Conversation? _currentConversation;
  int? _currentUserId;
  
  // Callbacks cho UI
  Function(ChatMessage)? onNewMessage;
  /// Khi có conversation mới (emit từ server) - thường dành cho staff app
  Function(Conversation)? onNewConversation;
  Function(String)? onError;
  Function(bool)? onConnectionChange;
  /// Typing event: userId, userName, isTyping
  Function(int userId, String userName, bool isTyping)? onTyping;

  bool get isConnected => _socket?.connected ?? false;
  Conversation? get currentConversation => _currentConversation;

  /// Kết nối Socket.IO với user authentication
  Future<void> connect(int userId) async {
    if (_socket?.connected ?? false) {
      print('[ChatService] Already connected');
      return;
    }

    _currentUserId = userId;

    try {
      print('[ChatService] Connecting to ${ApiEndpoints.socketUrl}');
      
      _socket = IO.io(
        ApiEndpoints.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .setAuth({
              'user_id': userId,
            })
            .build(),
      );

      _setupSocketListeners();

      _socket!.connect();

      print('[ChatService] Socket initialized');
    } catch (e) {
      print('[ChatService] Error connecting: $e');
      onError?.call('Không thể kết nối: $e');
    }
  }

  /// Setup các event listeners cho socket
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Kết nối thành công
    _socket!.on('connect', (_) {
      print('[ChatService] Connected! Socket ID: ${_socket!.id}');
      onConnectionChange?.call(true);
    });

    // Log all incoming events (helpful for debugging connection issues)
    try {
      _socket!.onAny((event, data) {
        print('[ChatService] onAny -> event: $event, data: $data');
      });
    } catch (e) {
      // onAny may not be available on some versions; ignore safely
    }

    // Mất kết nối
    _socket!.on('disconnect', (_) {
      print('[ChatService] Disconnected');
      onConnectionChange?.call(false);
    });

    // Lỗi kết nối
    _socket!.on('connect_error', (data) {
      print('[ChatService] Connection error: $data');
      onError?.call('Lỗi kết nối: $data');
    });

    // Connect timeout
    _socket!.on('connect_timeout', (data) {
      print('[ChatService] connect_timeout: $data');
      onError?.call('Kết nối timeout');
    });

    // Nhận tin nhắn mới
    _socket!.on('new_message', (data) {
      print('[ChatService] New message received: $data');
      try {
        final message = ChatMessage.fromJson(data, currentUserId: _currentUserId);
        onNewMessage?.call(message);
      } catch (e) {
        print('[ChatService] Error parsing message: $e');
      }
    });

    // Conversation mới (staff) - payload may be partial, build a Conversation model
    _socket!.on('new_conversation', (data) {
      print('[ChatService] New conversation event: $data');
      try {
        if (data is Map<String, dynamic>) {
          final conv = _conversationFromSocketPayload(data);
          if (conv != null) onNewConversation?.call(conv);
        }
      } catch (e) {
        print('[ChatService] Error parsing new_conversation: $e');
      }
    });

    // Người dùng đang gõ
    _socket!.on('user_typing', (data) {
      print('[ChatService] User typing: $data');
      try {
        if (data is Map<String, dynamic>) {
          final int userId = data['user_id'] is int ? data['user_id'] : int.tryParse('${data['user_id']}') ?? 0;
          final String userName = data['user_name'] ?? data['ho_ten'] ?? 'Người dùng';
          final bool isTyping = data['is_typing'] == true;
          onTyping?.call(userId, userName, isTyping);
        }
      } catch (e) {
        print('[ChatService] Error parsing user_typing: $e');
      }
    });

    // Nhận lỗi từ server
    _socket!.on('error', (data) {
      print('[ChatService] Server error: $data');
      onError?.call(data['message'] ?? 'Có lỗi xảy ra');
    });
  }

  /// Gửi tin nhắn qua Socket.IO
  void sendMessage(String noiDung, {int? customerId}) {
    if (_socket == null || !(_socket!.connected)) {
      onError?.call('Chưa kết nối tới server');
      return;
    }

    if (noiDung.trim().isEmpty) {
      onError?.call('Tin nhắn không được để trống');
      return;
    }

    final data = {
      'noi_dung': noiDung.trim(),
      if (customerId != null) 'customer_id': customerId,
    };

    print('[ChatService] Sending message: $data');
    _socket!.emit('send_message', data);
  }

  /// Gửi sự kiện đang gõ
  void sendTyping(bool isTyping, {int? customerId}) {
    if (_socket == null || !(_socket!.connected)) return;

    final data = {
      'is_typing': isTyping,
      if (customerId != null) 'customer_id': customerId,
    };

    _socket!.emit('typing', data);
  }

  /// Join vào conversation cụ thể (dành cho staff)
  void joinConversation(int customerId) {
    if (_socket == null || !(_socket!.connected)) return;

    _socket!.emit('join_conversation', {'customer_id': customerId});
    print('[ChatService] Joined conversation with customer $customerId');
  }

  /// Ngắt kết nối Socket.IO
  void disconnect() {
    print('[ChatService] Disconnecting...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentConversation = null;
  }

  // === REST API Methods ===

  /// Lấy conversation của khách hàng hiện tại
  Future<Conversation?> getMyConversation() async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/conversations/my_conversation/');
      final response = await http.get(
        uri,
        headers: AuthService.instance.authHeaders,
      );

      print('[ChatService] Get my conversation: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentConversation = Conversation.fromJson(data);
        return _currentConversation;
      }

      return null;
    } catch (e) {
      print('[ChatService] Error getting conversation: $e');
      return null;
    }
  }

  /// Lấy tất cả conversations (dành cho staff)
  Future<List<Conversation>> getAllConversations() async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/conversations/');
      final response = await http.get(
        uri,
        headers: AuthService.instance.authHeaders,
      );

      print('[ChatService] Get all conversations: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => Conversation.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('[ChatService] Error getting conversations: $e');
      return [];
    }
  }

  /// Lấy messages trong conversation
  Future<List<ChatMessage>> getMessages(int conversationId, {int limit = 50, int offset = 0}) async {
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/conversations/$conversationId/messages/?limit=$limit&offset=$offset',
      );
      final response = await http.get(
        uri,
        headers: AuthService.instance.authHeaders,
      );

      print('[ChatService] Get messages: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data
            .map((json) => ChatMessage.fromJson(json, currentUserId: _currentUserId))
            .toList();
      }

      return [];
    } catch (e) {
      print('[ChatService] Error getting messages: $e');
      return [];
    }
  }

  /// Gửi tin nhắn qua REST API (fallback nếu socket không hoạt động)
  Future<ChatMessage?> sendMessageViaApi(int conversationId, String noiDung) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/api/conversations/$conversationId/send_message/');
      final response = await http.post(
        uri,
        headers: AuthService.instance.authHeaders,
        body: json.encode({'noi_dung': noiDung}),
      );

      print('[ChatService] Send message via API: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ChatMessage.fromJson(data, currentUserId: _currentUserId);
      }

      return null;
    } catch (e) {
      print('[ChatService] Error sending message via API: $e');
      return null;
    }
  }

  /// Clear callbacks khi dispose
  void clearCallbacks() {
    onNewMessage = null;
    onError = null;
    onConnectionChange = null;
    onTyping = null;
  }

  /// Helper: build a Conversation from socket payload for 'new_conversation'
  Conversation? _conversationFromSocketPayload(Map<String, dynamic> data) {
    try {
      final int id = data['id'] is int ? data['id'] : int.tryParse('${data['id']}') ?? 0;
  final dynamic customerIdRaw = data['customer_id'] ?? data['customer'];
  final String? customerName = data['customer_name'] ?? (data['customer_info']?['ho_ten']);
      final bool isStaffGroup = data['is_staff_group'] ?? true;
      final DateTime createdAt = data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now();

      DateTime? lastMessageAt;
      ChatMessageSimple? lastMsg;
      if (data['last_message'] != null && data['last_message'] is Map<String, dynamic>) {
        final lm = data['last_message'] as Map<String, dynamic>;
        lastMessageAt = lm['thoi_gian'] != null ? DateTime.parse(lm['thoi_gian']) : null;
        lastMsg = ChatMessageSimple(
          id: lm['id'] is int ? lm['id'] : int.tryParse('${lm['id']}') ?? 0,
          noiDung: lm['noi_dung'] ?? '',
          thoiGian: lastMessageAt ?? DateTime.now(),
          nguoiGoiName: lm['nguoi_goi_name'] ?? '',
        );
      }

      int? parsedCustomerId;
      if (customerIdRaw is int) {
        parsedCustomerId = customerIdRaw;
      } else if (customerIdRaw != null) {
        parsedCustomerId = int.tryParse(customerIdRaw.toString());
      }

      return Conversation(
        id: id,
        customerId: parsedCustomerId,
        customerName: customerName,
        isStaffGroup: isStaffGroup,
        createdAt: createdAt,
        lastMessageAt: lastMessageAt,
        lastMessage: lastMsg,
        unreadCount: data['unread_count'] ?? 1,
      );
    } catch (e) {
      print('[ChatService] _conversationFromSocketPayload error: $e');
      return null;
    }
  }
}
