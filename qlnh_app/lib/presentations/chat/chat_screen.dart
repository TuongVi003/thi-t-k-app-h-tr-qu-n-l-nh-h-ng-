import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  Conversation? _conversation;
  User? _currentUser;
  bool _isLoading = true;
  bool _isConnected = false;
  bool _isSending = false;
  String? _errorMessage;
  Timer? _typingTimer;
  
  // Typing indicator state
  bool _otherUserTyping = false;
  String _typingUserName = '';
  Timer? _typingIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    try {
      // Lấy thông tin user hiện tại
      _currentUser = await UserService.instance.getCurrentUser();
      
      if (_currentUser == null) {
        setState(() {
          _errorMessage = 'Không thể lấy thông tin người dùng';
          _isLoading = false;
        });
        return;
      }

      // Kết nối Socket.IO
      await _chatService.connect(_currentUser!.id);

      // Setup callbacks
      _chatService.onNewMessage = _handleNewMessage;
      _chatService.onError = _handleError;
      _chatService.onConnectionChange = _handleConnectionChange;
      _chatService.onTyping = _handleTyping;

      // Lấy conversation
      _conversation = await _chatService.getMyConversation();

      if (_conversation != null) {
        // Lấy lịch sử tin nhắn
        final messages = await _chatService.getMessages(_conversation!.id);
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khởi tạo: $e';
        _isLoading = false;
      });
    }
  }

  void _handleNewMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      // Nếu đã có message cùng id (server đã gửi trước) thì bỏ
      final existsById = _messages.any((m) => m.id == message.id);
      if (existsById) return;

      // Nếu đây là message gửi bởi chính client, tìm placeholder tạm
      // Placeholder messages use negative ids (see ChatMessage.temporary)
      if (message.isSentByMe) {
        final tempIndex = _messages.indexWhere((m) => m.id < 0 && m.nguoiGoiId == message.nguoiGoiId && m.noiDung == message.noiDung);
        if (tempIndex != -1) {
          // Thay thế placeholder bằng message thật từ server (giữ vị trí)
          _messages[tempIndex] = message;
          return;
        }
      }

      // Thêm message mới vào danh sách
      _messages.add(message);
    });
    
    _scrollToBottom();
  }

  void _handleError(String error) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handleConnectionChange(bool connected) {
    if (!mounted) return;
    
    setState(() => _isConnected = connected);
    
    if (connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã kết nối'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleTyping(int userId, String userName, bool isTyping) {
    if (!mounted) return;
    
    // Ignore typing events from current user
    if (userId == _currentUser?.id) return;
    
    setState(() {
      _otherUserTyping = isTyping;
      _typingUserName = userName;
    });
    
    // Auto-hide typing indicator after 3 seconds
    _typingIndicatorTimer?.cancel();
    if (isTyping) {
      _typingIndicatorTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _otherUserTyping = false;
          });
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      // Nếu chưa có conversation, tạo mới
      if (_conversation == null) {
        _conversation = await _chatService.getMyConversation();
      }

      if (_conversation == null) {
        _handleError('Không thể tạo cuộc trò chuyện');
        setState(() => _isSending = false);
        return;
      }

      // Tạo tin nhắn tạm thời để hiển thị ngay
      final tempMessage = ChatMessage.temporary(
        noiDung: text,
        nguoiGoiId: _currentUser!.id,
        nguoiGoiName: _currentUser!.hoTen,
        conversationId: _conversation!.id,
      );

      setState(() {
        _messages.add(tempMessage);
        _messageController.clear();
      });
      _scrollToBottom();

      // Gửi qua Socket.IO
      _chatService.sendMessage(text);

      setState(() => _isSending = false);
    } catch (e) {
      _handleError('Lỗi gửi tin nhắn: $e');
      setState(() => _isSending = false);
    }
  }

  void _onTyping() {
    // Cancel timer cũ
    _typingTimer?.cancel();

    // Gửi sự kiện đang gõ
    _chatService.sendTyping(true);

    // Sau 2 giây không gõ thì gửi sự kiện ngừng gõ
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _chatService.sendTyping(false);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _typingIndicatorTimer?.cancel();
    // Clear callbacks and disconnect when leaving the screen to free resources
    _chatService.clearCallbacks();
    _chatService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat hỗ trợ'),
            Text(
              _isConnected ? '● Đang kết nối' : '○ Không kết nối',
              style: TextStyle(
                fontSize: 12,
                color: _isConnected ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _initialize,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Messages list
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có tin nhắn',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gửi tin nhắn để bắt đầu trò chuyện',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                return _buildMessageBubble(message);
                              },
                            ),
                    ),

                    // Typing indicator
                    if (_otherUserTyping)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              '$_typingUserName đang soạn tin nhắn',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
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
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập tin nhắn...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  maxLines: null,
                                  textInputAction: TextInputAction.send,
                                  onChanged: (_) => _onTyping(),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _isSending ? null : _sendMessage,
                                icon: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            AppColors.textWhite,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                color: AppColors.textWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isSentByMe = message.nguoiGoiId == _currentUser?.id;
    
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Tên người gửi (chỉ hiển thị cho tin nhắn từ người khác)
            if (!isSentByMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.nguoiGoiDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // Bubble tin nhắn
            Container(
              decoration: BoxDecoration(
                gradient: isSentByMe
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSentByMe ? null : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isSentByMe ? 20 : 4),
                  bottomRight: Radius.circular(isSentByMe ? 4 : 20),
                ),
                border: isSentByMe
                    ? null
                    : Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: isSentByMe
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.noiDung,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSentByMe
                          ? AppColors.textWhite
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.thoiGian),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSentByMe
                          ? AppColors.textWhite.withOpacity(0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
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
            duration: Duration(milliseconds: 600),
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
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted && _otherUserTyping) {
                setState(() {}); // Trigger rebuild to restart animation
              }
            },
          );
        }),
      ),
    );
  }
}
