import 'dart:convert';
import 'dart:async';
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
    print('[ChatService] 📞 connect() called with userId: $userId, current: $_currentUserId, socket exists: ${_socket != null}, connected: ${_socket?.connected}');
    
    // ⭐ CRITICAL: ALWAYS force cleanup before EVERY connection attempt
    // This ensures no cached auth or stale session can be reused
    if (_socket != null) {
      print('[ChatService] 🔄 FORCE CLEANUP before connecting (existing socket detected)...');
      await _forceCleanup();
      print('[ChatService] ✅ Cleanup complete, ready for new connection');
    } else if (_currentUserId != null && _currentUserId != userId) {
      // Even if socket is null, if we're switching users, wait for backend cleanup
      print('[ChatService] 🔄 User switch detected (old: $_currentUserId, new: $userId), requesting backend cleanup...');
      // Try to inform backend to cleanup sessions for the previous user (best-effort)
      try {
        final oldUser = _currentUserId;
        final uri = Uri.parse(ApiEndpoints.cleanupSocket);
        final headers = AuthService.instance.authHeaders;
        final body = json.encode({'user_id': oldUser});
        final resp = await http.post(uri, headers: headers, body: body);
        print('[ChatService] Backend cleanup (user switch) status: ${resp.statusCode}');
      } catch (e) {
        print('[ChatService] Warning: failed to request backend cleanup on user switch: $e');
      }
      _currentUserId = null;
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    _currentUserId = userId;

    try {
      final token = AuthService.instance.accessToken;

      print('[ChatService] 🆕 Creating BRAND NEW socket for user_id: $userId');
      print('[ChatService] 🔗 Connecting to: ${ApiEndpoints.socketUrl}');
      print('[ChatService] 🔑 Using token (truncated): ${token != null ? token.substring(0, 20) + "..." : "(null)"}');

      // Include user_id + token + timestamp to remain compatible with current backend
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = '$userId-$timestamp-${DateTime.now().microsecond}';

      final authPayload = {
        'user_id': userId,
        'token': token,
        'timestamp': timestamp,
        'unique_id': uniqueId,
      };

      print('[ChatService] 📦 Auth payload prepared: user_id=$userId, unique_id=$uniqueId, timestamp=$timestamp');
      
      _socket = IO.io(
        ApiEndpoints.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()  
            .disableReconnection()  
            .setAuth(authPayload)
            .build(),
      );

      _setupSocketListeners();

      // Prepare a short-lived completer to await actual connection or timeout
      final completer = Completer<bool>();

      void _onOnceConnect(dynamic _) {
        if (!completer.isCompleted) completer.complete(true);
      }

      void _onOnceConnectError(dynamic _) {
        if (!completer.isCompleted) completer.complete(false);
      }

      // Attach temporary handlers
      try {
        _socket!.on('connect', _onOnceConnect);
        _socket!.on('connect_error', _onOnceConnectError);
        _socket!.on('connect_timeout', _onOnceConnectError);
      } catch (e) {
        // ignore if handlers cannot be attached
      }

      _socket!.connect();

      print('[ChatService] 🚀 Socket connection initiated for user $userId');

      // Wait up to 5s for a connection; otherwise treat as failed
      bool connected = false;
      try {
        connected = await completer.future.timeout(const Duration(milliseconds: 5000));
      } catch (_) {
        connected = false;
      }

      // Cleanup temporary handlers
      try {
        _socket!.off('connect', _onOnceConnect);
        _socket!.off('connect_error', _onOnceConnectError);
        _socket!.off('connect_timeout', _onOnceConnectError);
      } catch (_) {}

      if (!connected) {
        print('[ChatService] ❌ Socket failed to connect within timeout');
        onError?.call('Không thể kết nối tới server (timeout)');
        // Best-effort cleanup
        try {
          if (_socket!.connected) _socket!.disconnect();
        } catch (_) {}
        return;
      }
      
    } catch (e) {
      print('[ChatService] ❌ Error connecting: $e');
      onError?.call('Không thể kết nối: $e');
    }
  }

  /// Setup các event listeners cho socket
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Kết nối thành công
    _socket!.on('connect', (_) {
      print('[ChatService] ✅ CONNECTED! User ID: $_currentUserId, Socket ID: ${_socket!.id}');
      print('[ChatService] 📡 Backend should have mapped: sid=${_socket!.id} -> user_id=$_currentUserId');
      onConnectionChange?.call(true);
    });
    
    // Reconnect (shouldn't happen since we disabled it, but just in case)
    _socket!.on('reconnect', (attempt) {
      print('[ChatService] ⚠️ RECONNECT detected (attempt $attempt) - This should NOT happen!');
      print('[ChatService] User ID: $_currentUserId, Socket ID: ${_socket!.id}');
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
    _socket!.on('disconnect', (reason) {
      print('[ChatService] 🔌 DISCONNECTED - Reason: $reason');
      print('[ChatService] User ID was: $_currentUserId');
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
  Future<void> sendMessage(String noiDung, {int? customerId}) async {
    if (_socket == null || !(_socket!.connected)) {
      print('[ChatService] ⚠️ Socket not connected, attempting REST fallback');

      // Try to send via REST immediately so user action is not blocked.
      if (_currentConversation != null) {
        final fallback = await sendMessageViaApi(_currentConversation!.id, noiDung.trim());
        if (fallback != null) {
          onNewMessage?.call(fallback);
          // Also attempt to reconnect in background for future socket use
          if (_currentUserId != null) {
            // fire-and-forget
            connect(_currentUserId!);
          }
          return;
        } else {
          onError?.call('Không gửi được tin nhắn (socket và REST đều lỗi)');
          // Try to reconnect in background
          if (_currentUserId != null) connect(_currentUserId!);
          return;
        }
      } else {
        // Try to obtain conversation and send
        final conv = await getMyConversation();
        if (conv != null) {
          final fallback = await sendMessageViaApi(conv.id, noiDung.trim());
          if (fallback != null) {
            onNewMessage?.call(fallback);
            if (_currentUserId != null) connect(_currentUserId!);
            return;
          }
        }

        onError?.call('Chưa có conversation để gửi và socket không kết nối');
        if (_currentUserId != null) connect(_currentUserId!);
        return;
      }
    }

    if (noiDung.trim().isEmpty) {
      onError?.call('Tin nhắn không được để trống');
      return;
    }

    // Send immediately (no client-side queueing). Server will validate and
    // reject if the session isn't valid; rely on server-side fixes for stale sid.

    final data = {
      'noi_dung': noiDung.trim(),
      if (customerId != null) 'customer_id': customerId,
    };

    print('[ChatService] 📤 SENDING MESSAGE:');
    print('[ChatService]    From user_id: $_currentUserId');
    print('[ChatService]    Socket ID: ${_socket!.id}');
    print('[ChatService]    Data: $data');
    print('[ChatService]    Backend should use: connected_users[${_socket!.id}] = $_currentUserId');
    
    // Emit via socket and wait briefly for server to echo back the message.
    // If no echo within timeout, fallback to REST API to ensure message is persisted.
    bool acked = false;

    void ackHandler(dynamic payload) {
      try {
        if (payload is Map<String, dynamic>) {
          final String serverText = (payload['noi_dung'] ?? '') as String;
          final dynamic senderIdRaw = payload['nguoi_goi_id'] ?? payload['nguoi_goi'];
          final int senderId = senderIdRaw is int ? senderIdRaw : int.tryParse('$senderIdRaw') ?? 0;
          if (serverText.trim() == noiDung.trim() && senderId == (_currentUserId ?? 0)) {
            acked = true;
          }
        }
      } catch (e) {
        // ignore parse errors
      }
    }

    try {
      _socket!.on('new_message', ackHandler);
      _socket!.emit('send_message', data);

      // Wait short time for server broadcast to come back
      await Future.delayed(const Duration(milliseconds: 900));
    } catch (e) {
      print('[ChatService] Error emitting message: $e');
    } finally {
      try {
        _socket!.off('new_message', ackHandler);
      } catch (_) {}
    }

    if (!acked) {
      print('[ChatService] ⚠️ No socket ack received, falling back to REST API');
      if (_currentConversation != null) {
        final fallback = await sendMessageViaApi(_currentConversation!.id, noiDung.trim());
        if (fallback != null) {
          // Notify UI with server-confirmed message
          onNewMessage?.call(fallback);
        } else {
          onError?.call('Không gửi được tin nhắn (socket và REST đều lỗi)');
        }
      } else {
        onError?.call('Không có conversation để gửi qua REST');
      }
    }
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
  Future<void> disconnect() async {
    await _forceCleanup();
  }

  /// FORCE cleanup - more aggressive than disconnect()
  Future<void> _forceCleanup() async {
    if (_socket == null) {
      print('[ChatService] _forceCleanup: No socket to cleanup');
      _currentConversation = null;
      _currentUserId = null;
      return;
    }
    
    final oldUserId = _currentUserId;
    final oldSocketId = _socket?.id;
    
    print('[ChatService] � FORCE CLEANUP (user: $oldUserId, socket: $oldSocketId)...');
    
    try {
      // Best-effort: tell backend to cleanup any sessions related to this socket/user
      try {
        final uri = Uri.parse(ApiEndpoints.cleanupSocket);
        final headers = AuthService.instance.authHeaders;
        final body = json.encode({'user_id': oldUserId, 'socket_id': oldSocketId});
        final resp = await http.post(uri, headers: headers, body: body);
        print('[ChatService] Backend cleanup (force) status: ${resp.statusCode}');
      } catch (e) {
        print('[ChatService] Warning: backend cleanup call failed during force cleanup: $e');
      }
      if (_socket!.connected) {
        _socket!.disconnect();
      }
      _socket!.clearListeners();
      _socket!.dispose();
    } catch (e) {
      print('[ChatService] Error during force cleanup: $e');
    }
    
  _socket = null;
  _currentConversation = null;
  _currentUserId = null;
    
    // Wait LONGER for backend
    print('[ChatService] ⏳ Waiting 1.2s for backend cleanup...');
    await Future.delayed(const Duration(milliseconds: 1200));
    
    print('[ChatService] ✅ Force cleanup complete (was user: $oldUserId, socket: $oldSocketId)');
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
