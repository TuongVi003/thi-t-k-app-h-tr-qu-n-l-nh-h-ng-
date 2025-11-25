import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:qlnh_nhan_vien/constants/api.dart';
import 'package:qlnh_nhan_vien/models/chat_models.dart';
import 'package:qlnh_nhan_vien/services/auth_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Callbacks
  Function(ChatMessage)? onNewMessage;
  // New callback: provides optional conversation payload from server when available
  Function(ChatMessage, Map<String, dynamic>?)? onNewMessageWithConversation;
  Function(Conversation)? onNewConversation;  // Thêm callback cho conversation mới
  /// ⭐ NEW: Callback khi conversation được cập nhật (có tin nhắn mới)
  Function(Map<String, dynamic>)? onConversationUpdated;
  /// ⭐ NEW: Callback khi nhận event update_conversation_list từ server
  Function(Map<String, dynamic>)? onUpdateConversationList;
  Function(Map<String, dynamic>)? onUserTyping;
  Function(String)? onError;
  Function()? onConnect;
  Function()? onDisconnect;

  bool get isConnected => _isConnected;

  /// Kết nối Socket.IO
  Future<void> connect(int userId) async {
    if (_isConnected && _socket != null) {
      print('[ChatService] Already connected');
      return;
    }

    try {
      print('[ChatService] 📡 Connecting to ${ApiEndpoints.socketUrl}');
      print('[ChatService] 👤 User ID: $userId');
      
      _socket = IO.io(
        ApiEndpoints.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])  // Chỉ dùng websocket như app khách hàng
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

      _socket!.onConnect((_) {
        print('[ChatService] ✅ Connected! Socket ID: ${_socket!.id}');
        _isConnected = true;
        onConnect?.call();
      });

      _socket!.onDisconnect((_) {
        print('[ChatService] ❌ Disconnected from Socket.IO');
        _isConnected = false;
        onDisconnect?.call();
      });

      _socket!.on('new_message', (data) {
        print('[ChatService] 📩 New message: $data');
        try {
          final message = ChatMessage.fromJson(data);
          // Call legacy callback
          onNewMessage?.call(message);
          // If server provided conversation payload inside the message, forward it
          Map<String, dynamic>? convPayload;
          try {
            if (data is Map && data.containsKey('conversation')) {
              final raw = data['conversation'];
              if (raw is Map<String, dynamic>) convPayload = raw;
            }
          } catch (_) {
            convPayload = null;
          }

          onNewMessageWithConversation?.call(message, convPayload);
        } catch (e) {
          print('[ChatService] ⚠️ Error parsing message: $e');
        }
      });

      _socket!.on('new_conversation', (data) {
        print('[ChatService] 🆕 New conversation: $data');
        try {
          final conversation = Conversation.fromJson(data);
          onNewConversation?.call(conversation);
        } catch (e) {
          print('[ChatService] ⚠️ Error parsing conversation: $e');
        }
      });

      // ⭐ NEW: Listen for conversation updates (when existing conversation gets new message)
      _socket!.on('conversation_updated', (data) {
        print('[ChatService] 🔄 Conversation updated: $data');
        print('[ChatService] 🔍 Data type: ${data.runtimeType}');
        if (data is Map) {
          print('[ChatService] 🔍 Data keys: ${data.keys}');
        }
        try {
          if (data is Map<String, dynamic>) {
            onConversationUpdated?.call(data);
          } else if (data is Map) {
            // Convert to Map<String, dynamic>
            final convertedData = Map<String, dynamic>.from(data);
            onConversationUpdated?.call(convertedData);
          } else {
            print('[ChatService] ⚠️ conversation_updated data is not a Map: ${data.runtimeType}');
          }
        } catch (e) {
          print('[ChatService] ⚠️ Error handling conversation update: $e');
        }
      });

      // ⭐ NEW: Listen for update_conversation_list event (for staff conversation list updates)
      _socket!.on('update_conversation_list', (data) {
        print('[ChatService] 📋 Update conversation list: $data');
        try {
          if (data is Map<String, dynamic>) {
            onUpdateConversationList?.call(data);
          } else if (data is Map) {
            final convertedData = Map<String, dynamic>.from(data);
            onUpdateConversationList?.call(convertedData);
          } else {
            print('[ChatService] ⚠️ update_conversation_list data is not a Map: ${data.runtimeType}');
          }
        } catch (e) {
          print('[ChatService] ⚠️ Error handling update_conversation_list: $e');
        }
      });

      _socket!.on('user_typing', (data) {
        print('[ChatService] ⌨️ User typing: $data');
        onUserTyping?.call(data);
      });

      _socket!.on('error', (data) {
        print('[ChatService] ⚠️ Server error: $data');
        onError?.call(data['message'] ?? 'Unknown error');
      });

      _socket!.on('connect_error', (error) {
        print('[ChatService] ⚠️ Connection error: $error');
        _isConnected = false;
        onError?.call('Lỗi kết nối: $error');
      });

      _socket!.connect();
      
    } catch (e) {
      print('[ChatService] Connection exception: $e');
      _isConnected = false;
    }
  }

  /// Ngắt kết nối
  void disconnect() {
    if (_socket != null) {
      print('[ChatService] Disconnecting...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  /// Gửi tin nhắn qua Socket.IO
  void sendMessage({
    required String noiDung,
    int? customerId,
  }) {
    if (!_isConnected || _socket == null) {
      print('[ChatService] ❌ Cannot send message: not connected');
      onError?.call('Chưa kết nối đến server');
      return;
    }

    final data = {
      'noi_dung': noiDung.trim(),
      if (customerId != null) 'customer_id': customerId,
    };

    print('[ChatService] 📤 Sending message: $data');
    _socket!.emit('send_message', data);
  }

  /// Join vào conversation của customer cụ thể (cho staff)
  void joinConversation(int customerId) {
    if (!_isConnected || _socket == null) {
      print('[ChatService] Cannot join conversation: not connected');
      return;
    }

    print('[ChatService] Joining conversation with customer: $customerId');
    _socket!.emit('join_conversation', {'customer_id': customerId});
  }

  /// Gửi sự kiện đang gõ
  void sendTyping({
    required bool isTyping,
    int? customerId,
  }) {
    if (!_isConnected || _socket == null) return;

    final data = {
      'is_typing': isTyping,
      if (customerId != null) 'customer_id': customerId,
    };

    _socket!.emit('typing', data);
  }

  // =============== REST API Methods ===============

  /// Lấy danh sách conversations (cho staff)
  Future<List<Conversation>> getConversations() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/conversations/'),
        headers: {
          'Authorization': token.authorizationHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      print('[ChatService] Error loading conversations: $e');
      rethrow;
    }
  }

  /// Lấy conversation của customer (cho staff xem chi tiết)
  Future<Conversation> getConversationDetail(int conversationId) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/conversations/$conversationId/'),
        headers: {
          'Authorization': token.authorizationHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return Conversation.fromJson(data);
      } else {
        throw Exception('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('[ChatService] Error loading conversation detail: $e');
      rethrow;
    }
  }

  /// Lấy messages trong conversation
  Future<List<ChatMessage>> getMessages({
    required int conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/conversations/$conversationId/messages/?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': token.authorizationHeader,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('[ChatService] Error loading messages: $e');
      rethrow;
    }
  }

  /// Gửi message qua REST API (alternative)
  Future<ChatMessage> sendMessageRest({
    required int conversationId,
    required String noiDung,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/api/conversations/$conversationId/send_message/'),
        headers: {
          'Authorization': token.authorizationHeader,
          'Content-Type': 'application/json',
        },
        body: json.encode({'noi_dung': noiDung}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ChatMessage.fromJson(data);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('[ChatService] Error sending message: $e');
      rethrow;
    }
  }
}
