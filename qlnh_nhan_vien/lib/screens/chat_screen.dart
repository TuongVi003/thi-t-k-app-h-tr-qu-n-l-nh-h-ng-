import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qlnh_nhan_vien/models/chat_models.dart';
import 'package:qlnh_nhan_vien/services/chat_service.dart';
import 'package:qlnh_nhan_vien/services/auth_service.dart';
import 'package:intl/intl.dart';

/// Màn hình danh sách conversations (cho nhân viên)
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final ChatService _chatService = ChatService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeChatAndLoadConversations();
  }

  Future<void> _initializeChatAndLoadConversations() async {
    try {
      // Kết nối Socket.IO
      final user = await AuthService.getStoredUser();
      if (user != null) {
        await _chatService.connect(user.id);

        // Lắng nghe tin nhắn mới
        _chatService.onNewMessage = _onNewMessage;
        // Lắng nghe tin nhắn có kèm conversation payload (realtime update)
        _chatService.onNewMessageWithConversation =
            _onNewMessageWithConversation;

        // Lắng nghe conversation mới
        _chatService.onNewConversation = _onNewConversation;
        
        // ⭐ Chỉ lắng nghe update_conversation_list để cập nhật danh sách real-time
        _chatService.onUpdateConversationList = _onUpdateConversationList;
      }

      // Load conversations
      await _loadConversations();
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final conversations = await _chatService.getConversations();

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách chat: $e';
        _isLoading = false;
      });
    }
  }

  void _onNewMessage(ChatMessage message) {
    // ✅ Check mounted trước khi setState
    if (!mounted) return;

    // Cập nhật conversation list khi có tin mới
    setState(() {
      final index =
          _conversations.indexWhere((c) => c.id == message.conversationId);
      if (index != -1) {
        // ✅ Kiểm tra xem message này đã được xử lý chưa (tránh duplicate)
        final currentLastMessage = _conversations[index].lastMessage;
        if (currentLastMessage != null && currentLastMessage.id == message.id) {
          print(
              '[ConversationsListScreen] ⚠️ Duplicate message ignored: ID ${message.id}');
          return; // Đã xử lý rồi, bỏ qua
        }

        // Cập nhật last message
        final updatedConv = Conversation(
          id: _conversations[index].id,
          customerId: _conversations[index].customerId,
          customerInfo: _conversations[index].customerInfo,
          isStaffGroup: _conversations[index].isStaffGroup,
          createdAt: _conversations[index].createdAt,
          lastMessageAt: message.thoiGian,
          lastMessage: message,
          unreadCount: _conversations[index].unreadCount + 1,
        );

        // Xóa conversation cũ và thêm lên đầu
        _conversations.removeAt(index);
        _conversations.insert(0, updatedConv);
      }
    });
  }

  /// Handler for new_message that includes optional conversation payload
  void _onNewMessageWithConversation(
      ChatMessage message, Map<String, dynamic>? convData) {
    // ✅ Check mounted trước khi setState
    if (!mounted) return;

    // Prefer using server-provided conversation payload to update/insert conversation
    setState(() {
      final convId = message.conversationId;
      final index = _conversations.indexWhere((c) => c.id == convId);

      // If conversation exists, update it (but avoid duplicate message)
      if (index != -1) {
        final currentLastMessage = _conversations[index].lastMessage;
        if (currentLastMessage != null && currentLastMessage.id == message.id) {
          print(
              '[ConversationsListScreen] ⚠️ Duplicate message ignored: ID ${message.id}');
          return;
        }

        // ⭐ FIX: Update customerInfo from message.nguoiGoiInfo if sender is customer
        CustomerInfo? updatedCustomerInfo = _conversations[index].customerInfo;
        if (updatedCustomerInfo == null && message.nguoiGoiInfo != null) {
          updatedCustomerInfo = message.nguoiGoiInfo;
        }

        final updatedConv = Conversation(
          id: _conversations[index].id,
          customerId: _conversations[index].customerId,
          customerInfo: updatedCustomerInfo,  // ⭐ Use updated info
          isStaffGroup: _conversations[index].isStaffGroup,
          createdAt: _conversations[index].createdAt,
          lastMessageAt: message.thoiGian,
          lastMessage: message,
          unreadCount: _conversations[index].unreadCount + 1,
        );

        _conversations.removeAt(index);
        _conversations.insert(0, updatedConv);
        return;
      }

      // If conversation not found, try to build from convData (if provided)
      if (convData != null) {
        try {
          final newConvId = convData['id'] ?? convId;
          final customerId = convData['customer_id'];
          final customerName = convData['customer_name'] ?? '';
          final createdAt = convData['created_at'] != null
              ? DateTime.parse(convData['created_at'])
              : message.thoiGian;
          final lastMessageAt = convData['last_message_at'] != null
              ? DateTime.parse(convData['last_message_at'])
              : message.thoiGian;

          final customerInfo = customerId != null
              ? CustomerInfo(
                  id: customerId,
                  username: '',
                  hoTen: customerName,
                  loaiNguoiDung: 'khach_hang',
                )
              : null;

          final newConv = Conversation(
            id: newConvId,
            customerId: customerId,
            customerInfo: customerInfo,
            isStaffGroup: true,
            createdAt: createdAt,
            lastMessageAt: lastMessageAt,
            lastMessage: message,
            unreadCount: 1,
          );

          _conversations.insert(0, newConv);
          return;
        } catch (e) {
          print(
              '[ConversationsListScreen] ⚠️ Failed to build conversation from payload: $e');
        }
      }

      // Fallback: create minimal conversation using available message data
      final fallbackConv = Conversation(
        id: convId ?? -1,
        customerId: null,
        customerInfo: null,
        isStaffGroup: true,
        createdAt: message.thoiGian,
        lastMessageAt: message.thoiGian,
        lastMessage: message,
        unreadCount: 1,
      );
      _conversations.insert(0, fallbackConv);
    });
  }

  void _onNewConversation(Conversation conversation) {
    // ✅ Check mounted trước khi setState
    if (!mounted) return;

    // Thêm conversation mới vào đầu danh sách
    print(
        '[ConversationsListScreen] 🆕 New conversation from customer ${conversation.customerId}');
    setState(() {
      // Kiểm tra xem conversation đã có trong list chưa
      final exists = _conversations.any((c) => c.id == conversation.id);
      if (!exists) {
        _conversations.insert(0, conversation);

        // Hiển thị notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '💬 Khách hàng mới: ${conversation.customerInfo?.hoTen ?? "Khách hàng"}',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  /// ⭐ Handler for update_conversation_list event - Real-time cập nhật danh sách
  void _onUpdateConversationList(Map<String, dynamic> data) {
    if (!mounted) return;
    
    try {
      final int convId = data['id'] ?? -1;
      final bool isNew = data['is_new'] ?? false;
      print('[ConversationsListScreen] 📋 update_conversation_list: Conv #$convId (isNew: $isNew)');
      
      setState(() {
        final index = _conversations.indexWhere((c) => c.id == convId);
        
        // Parse last_message
        ChatMessage? lastMsg;
        if (data['last_message'] != null && data['last_message'] is Map<String, dynamic>) {
          try {
            lastMsg = ChatMessage.fromJson(data['last_message']);
          } catch (e) {
            print('[ConversationsListScreen] ⚠️ Error parsing last_message: $e');
          }
        }
        
        if (index != -1) {
          // Conversation đã tồn tại -> Cập nhật & Đẩy lên đầu
          final currentConv = _conversations[index];
          
          // Tránh update trùng lặp
          if (lastMsg != null && currentConv.lastMessage?.id == lastMsg.id) {
            print('[ConversationsListScreen] ⚠️ Duplicate update ignored for Conv #$convId');
            return;
          }
          
          // Update customerInfo từ server data hoặc message
          CustomerInfo? updatedCustomerInfo = currentConv.customerInfo;
          
          // Ưu tiên lấy từ data server
          if (data['customer_id'] != null && data['customer_name'] != null) {
            updatedCustomerInfo = CustomerInfo(
              id: data['customer_id'],
              username: data['customer_phone'] ?? '',
              hoTen: data['customer_name'],
              loaiNguoiDung: 'khach_hang',
            );
          } else if (updatedCustomerInfo == null && lastMsg?.nguoiGoiInfo != null) {
            updatedCustomerInfo = lastMsg!.nguoiGoiInfo;
          }
          
          final updatedConv = Conversation(
            id: currentConv.id,
            customerId: data['customer_id'] ?? currentConv.customerId,
            customerInfo: updatedCustomerInfo,
            isStaffGroup: currentConv.isStaffGroup,
            createdAt: currentConv.createdAt,
            lastMessageAt: data['last_message_at'] != null 
                ? DateTime.parse(data['last_message_at']) 
                : (lastMsg?.thoiGian ?? currentConv.lastMessageAt),
            lastMessage: lastMsg ?? currentConv.lastMessage,
            unreadCount: currentConv.unreadCount + 1,
          );
          
          _conversations.removeAt(index);
          _conversations.insert(0, updatedConv);
          print('[ConversationsListScreen] ✅ Updated & reordered Conv #$convId to top');
          
        } else if (isNew) {
          // Conversation mới -> Thêm vào đầu danh sách
          print('[ConversationsListScreen] 🆕 Adding new conversation #$convId');
          
          final customerId = data['customer_id'];
          final customerName = data['customer_name'] ?? 'Khách hàng';
          
          CustomerInfo? customerInfo;
          if (customerId != null) {
            customerInfo = CustomerInfo(
              id: customerId,
              username: data['customer_phone'] ?? '',
              hoTen: customerName,
              loaiNguoiDung: 'khach_hang',
            );
          }
          
          final newConv = Conversation(
            id: convId,
            customerId: customerId,
            customerInfo: customerInfo,
            isStaffGroup: true,
            createdAt: data['created_at'] != null 
                ? DateTime.parse(data['created_at']) 
                : DateTime.now(),
            lastMessageAt: data['last_message_at'] != null 
                ? DateTime.parse(data['last_message_at']) 
                : DateTime.now(),
            lastMessage: lastMsg,
            unreadCount: 1,
          );
          
          _conversations.insert(0, newConv);
          
          // Hiển thị thông báo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🆕 Khách hàng mới: $customerName'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          print('[ConversationsListScreen] ⚠️ Conv #$convId not found and is_new=false, skipping');
        }
      });
    } catch (e) {
      print('[ConversationsListScreen] ❌ Error in _onUpdateConversationList: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn khách hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
          if (_chatService.isConnected)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Icon(Icons.circle, color: Colors.greenAccent, size: 12),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có tin nhắn nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          print(
              '[ConversationsListScreen] Building conversation card for ID ${conversation.toJson()}');
          return _buildConversationCard(conversation);
        },
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    // ⭐ FIX: Ưu tiên lấy tên từ customerInfo hoặc từ nguoiGoiInfo nếu là khách hàng
    String customerName = 'Khách hàng';
    
    if (conversation.customerInfo != null) {
      // Có customerInfo từ API - ưu tiên nhất
      customerName = conversation.customerInfo!.hoTen;
    } else if (conversation.lastMessage?.nguoiGoiInfo != null) {
      // Lấy từ nguoiGoiInfo của tin nhắn cuối (nếu là khách hàng)
      final nguoiGoiInfo = conversation.lastMessage!.nguoiGoiInfo!;
      if (nguoiGoiInfo.loaiNguoiDung == 'khach_hang') {
        customerName = nguoiGoiInfo.hoTen;
      } else if (conversation.customerId != null) {
        // Tin nhắn cuối từ nhân viên, dùng customerId làm fallback
        customerName = 'Khách hàng #${conversation.customerId}';
      }
    } else if (conversation.customerId != null) {
      // Fallback cuối cùng
      customerName = 'Khách hàng #${conversation.customerId}';
    }
    
    final lastMessage = conversation.lastMessage?.noiDung ?? 'Chưa có tin nhắn';
    final lastMessageTime = conversation.lastMessageAt;
    
    print('[ConversationCard] ID: ${conversation.id}, Customer: $customerName, LastMsg: ${lastMessage.substring(0, lastMessage.length > 20 ? 20 : lastMessage.length)}...');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            customerName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: conversation.unreadCount > 0
                ? Colors.black87
                : Colors.grey[600],
            fontWeight: conversation.unreadCount > 0
                ? FontWeight.w500
                : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMessageTime != null)
              Text(
                _formatTime(lastMessageTime),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          // Điều hướng đến màn hình chat chi tiết
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                conversation: conversation,
              ),
            ),
          ).then((_) => _loadConversations());
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }

  @override
  void dispose() {
    // ✅ Clear callbacks để tránh memory leak
    _chatService.onNewMessage = null;
    _chatService.onNewMessageWithConversation = null;
    _chatService.onNewConversation = null;
    _chatService.onUpdateConversationList = null;
    // Không disconnect socket ở đây vì có thể dùng ở màn hình khác
    super.dispose();
  }
}

/// Màn hình chat chi tiết với 1 khách hàng
class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailScreen({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _currentUserId;

  // Typing indicator state
  bool _isOtherUserTyping = false;
  String? _typingUserName;

  // Typing timer
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();

    // Listen to text changes to emit typing events
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _initializeChat() async {
    try {
      // 1. Lấy user hiện tại
      final user = await AuthService.getStoredUser();
      if (user == null) {
        print('Error: User not found');
        return;
      }
      _currentUserId = user.id;

      // 2. FIX RACE CONDITION: Đảm bảo Socket đã kết nối trước khi thực hiện hành động
      if (!_chatService.isConnected) {
        print('[ChatDetailScreen] Socket chưa kết nối, đang kết nối lại...');
        await _chatService.connect(user.id);

        // QUAN TRỌNG: Chờ một chút để Socket hoàn tất handshake (bắt tay)
        // Nếu không có dòng này, lệnh joinConversation ngay sau đó có thể bị fail do socket chưa ready
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 3. Sau khi chắc chắn đã connect, mới Join vào conversation
      if (widget.conversation.customerId != null) {
        print('[ChatDetailScreen] Joining conversation room...');
        _chatService.joinConversation(widget.conversation.customerId!);
      }

      // 4. Thiết lập lắng nghe sự kiện (Listeners)
      // Lưu ý: Việc gán listener có thể làm bất cứ lúc nào, không cần chờ connect
      _chatService.onNewMessage = _onNewMessage;
      _chatService.onUserTyping = _onUserTyping;

      // 5. Load tin nhắn cũ từ API
      await _loadMessages();
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        // Kiểm tra mounted trước khi setState để tránh lỗi nếu user thoát màn hình nhanh
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final messages = await _chatService.getMessages(
        conversationId: widget.conversation.id,
        limit: 100,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNewMessage(ChatMessage message) {
    // Chỉ cập nhật nếu message thuộc conversation này
    if (message.conversationId == widget.conversation.id) {
      // ✅ Check mounted trước khi setState
      if (!mounted) return;

      setState(() {
        // ✅ Kiểm tra duplicate bằng message ID
        final exists = _messages.any((m) => m.id == message.id);
        if (!exists) {
          _messages.add(message);
        } else {
          print(
              '[ChatDetailScreen] ⚠️ Duplicate message ignored: ID ${message.id}');
        }
      });

      // Auto scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _onUserTyping(Map<String, dynamic> data) {
    // ✅ Check mounted trước khi xử lý
    if (!mounted) return;

    // Chỉ hiển thị typing indicator nếu là customer của conversation này đang gõ
    final typingUserId = data['user_id'];
    final isTyping = data['is_typing'] ?? false;
    final userName = data['user_name'] ?? 'Khách hàng';

    // Chỉ hiển thị nếu không phải là mình và là user của conversation này
    if (typingUserId != _currentUserId &&
        typingUserId == widget.conversation.customerId) {
      setState(() {
        _isOtherUserTyping = isTyping;
        _typingUserName = isTyping ? userName : null;
      });
    }
  }

  void _onTextChanged() {
    final text = _messageController.text.trim();

    if (text.isNotEmpty) {
      // User is typing, emit typing = true
      _chatService.sendTyping(
        isTyping: true,
        customerId: widget.conversation.customerId,
      );

      // Cancel previous timer
      _typingTimer?.cancel();

      // Set new timer to emit typing = false after 1 second of inactivity
      _typingTimer = Timer(const Duration(seconds: 1), () {
        _chatService.sendTyping(
          isTyping: false,
          customerId: widget.conversation.customerId,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Gửi qua Socket.IO
      _chatService.sendMessage(
        noiDung: text,
        customerId: widget.conversation.customerId,
      );

      // Clear input
      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName =
        widget.conversation.customerInfo?.hoTen ?? 'Khách hàng';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(
                customerName[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_chatService.isConnected)
                    const Text(
                      'Đang hoạt động',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Chưa có tin nhắn'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.nguoiGoiId == _currentUserId;
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),

          // Typing indicator
          if (_isOtherUserTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    '$_typingUserName đang gõ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTypingAnimation(),
                ],
              ),
            ),

          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isSending ? null : _sendMessage,
                  mini: true,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.nguoiGoiDisplay,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            const SizedBox(height: 2),
            Text(
              message.noiDung,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.thoiGian),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingAnimation() {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              final animationValue = (value + (index * 0.33)) % 1.0;
              final opacity = (animationValue < 0.5
                  ? animationValue * 2
                  : (1.0 - animationValue) * 2);

              return Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 13, 71, 161),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted && _isOtherUserTyping) {
                setState(() {}); // Trigger rebuild to restart animation
              }
            },
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    // Clear Socket.IO callbacks để tránh memory leak
    _chatService.onNewMessage = null;
    _chatService.onUserTyping = null;

    // Cancel timer và remove listeners
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
