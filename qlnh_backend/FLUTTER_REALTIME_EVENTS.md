# 📱 Flutter Real-time Events Documentation

## Socket.IO Events cho Flutter App

Flutter app cần kết nối Socket.IO và lắng nghe các events sau để cập nhật real-time.

---

## 🔌 Kết nối Socket.IO

### Flutter Package
```yaml
# pubspec.yaml
dependencies:
  socket_io_client: ^2.0.0
```

### Khởi tạo Socket
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  IO.Socket? socket;
  
  void connect(int userId) {
    socket = IO.io('http://your-server:8001', 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setAuth({
          'user_id': userId
        })
        .build()
    );
    
    socket!.connect();
    
    socket!.onConnect((_) {
      print('✅ Connected to Socket.IO');
    });
    
    socket!.onDisconnect((_) {
      print('❌ Disconnected');
    });
    
    // Đăng ký lắng nghe events
    registerEventListeners();
  }
  
  void registerEventListeners() {
    // Event 1: Tin nhắn mới
    socket!.on('new_message', handleNewMessage);
    
    // Event 2: Conversation mới (chỉ staff)
    socket!.on('new_conversation', handleNewConversation);
    
    // Event 3: User đang gõ
    socket!.on('user_typing', handleUserTyping);
    
    // Event 4: Lỗi
    socket!.on('error', handleError);
  }
}
```

---

## 📨 Event 1: `new_message` - Tin nhắn mới

### Khi nào emit:
- ✅ Khách hàng gửi tin → Tất cả staff nhận
- ✅ Staff gửi tin → Customer đó nhận + tất cả staff khác nhận

### Ai nhận:
- **Customer gửi** → `staff_room` + `customer_{id}`
- **Staff gửi** → `customer_{id}` + `staff_room`

### Payload:
```json
{
  "id": 25,
  "conversation_id": 5,
  "nguoi_goi_id": 123,
  "nguoi_goi_name": "Nguyễn Văn A",
  "noi_dung": "Xin chào",
  "thoi_gian": "2025-11-03T10:30:00Z",
  "conversation": {
    "id": 5,
    "customer_id": 123,
    "customer_name": "Nguyễn Văn A",
    "customer_phone": "0901234567",
    "last_message_at": "2025-11-03T10:30:00Z"
  }
}
```

### Flutter Handler:
```dart
void handleNewMessage(dynamic data) {
  print('📨 New message: ${data['noi_dung']}');
  
  final message = ChatMessage(
    id: data['id'],
    conversationId: data['conversation_id'],
    nguoiGoiId: data['nguoi_goi_id'],
    nguoiGoiName: data['nguoi_goi_name'],
    noiDung: data['noi_dung'],
    thoiGian: DateTime.parse(data['thoi_gian']),
  );
  
  // Thông tin conversation để update list
  final conversationData = data['conversation'];
  
  // 1. Thêm message vào conversation (nếu đang mở chat detail)
  if (messages.containsKey(message.conversationId)) {
    messages[message.conversationId]!.add(message);
  }
  
  // 2. Update last_message và last_message_at của conversation trong list
  final convIndex = conversations.indexWhere((c) => c.id == message.conversationId);
  if (convIndex != -1) {
    // Update last message
    conversations[convIndex].lastMessage = message;
    conversations[convIndex].lastMessageAt = message.thoiGian;
    
    // 3. Di chuyển conversation lên đầu list
    final conv = conversations.removeAt(convIndex);
    conversations.insert(0, conv);
  } else {
    // Conversation chưa có trong list (case hiếm gặp)
    // Có thể fetch lại conversation list hoặc tạo conversation mới
    print('⚠️ Conversation ${message.conversationId} not found in list');
  }
  
  // 4. Hiển thị notification nếu app ở background
  if (!isAppInForeground) {
    showLocalNotification(
      title: message.nguoiGoiName,
      body: message.noiDung,
    );
  }
  
  // 5. Play sound
  playNotificationSound();
  
  // 6. Update UI
  notifyListeners(); // hoặc setState() nếu dùng StatefulWidget
}
```

---

## 🆕 Event 2: `new_conversation` - Conversation mới (Staff only)

### Khi nào emit:
- ✅ Khách hàng mới nhắn tin lần đầu tiên (tạo conversation mới)

### Ai nhận:
- **Chỉ staff** trong room `staff_room`

### Payload:
```json
{
  "id": 5,
  "customer_id": 123,
  "customer_name": "Nguyễn Văn A",
  "customer_phone": "0901234567",
  "created_at": "2025-11-03T10:30:00Z",
  "last_message": {
    "noi_dung": "Xin chào, tôi muốn đặt bàn",
    "thoi_gian": "2025-11-03T10:30:00Z"
  }
}
```

### Flutter Handler (Staff App):
```dart
void handleNewConversation(dynamic data) {
  print('🆕 New conversation from: ${data['customer_name']}');
  
  final conversation = Conversation(
    id: data['id'],
    customerId: data['customer_id'],
    customerName: data['customer_name'],
    customerPhone: data['customer_phone'],
    createdAt: DateTime.parse(data['created_at']),
    lastMessage: ChatMessage(
      noiDung: data['last_message']['noi_dung'],
      thoiGian: DateTime.parse(data['last_message']['thoi_gian']),
    ),
    isNew: true, // Flag để highlight UI
  );
  
  // 1. Thêm conversation vào đầu danh sách
  conversations.insert(0, conversation);
  
  // 2. Hiển thị notification
  showLocalNotification(
    title: '💬 Khách hàng mới',
    body: '${conversation.customerName}: ${conversation.lastMessage.noiDung}',
  );
  
  // 3. Play sound
  playNotificationSound();
  
  // 4. Update badge count
  incrementUnreadCount();
  
  // 5. Update UI
  notifyListeners();
  
  // 6. Remove "new" flag sau 3s
  Future.delayed(Duration(seconds: 3), () {
    conversation.isNew = false;
    notifyListeners();
  });
}
```

---

## ⌨️ Event 3: `user_typing` - Đang gõ

### Khi nào emit:
- ✅ User bắt đầu gõ tin nhắn
- ✅ User dừng gõ (sau 1s không gõ nữa)

### Ai nhận:
- **Customer gõ** → `staff_room` (tất cả staff)
- **Staff gõ** → `customer_{id}` (customer đó)

### Payload:
```json
{
  "user_id": 123,
  "user_name": "Nguyễn Văn A",
  "is_typing": true
}
```

### Flutter Handler:
```dart
void handleUserTyping(dynamic data) {
  final userId = data['user_id'];
  final userName = data['user_name'];
  final isTyping = data['is_typing'];
  
  if (isTyping) {
    print('⌨️ $userName đang gõ...');
    // Hiển thị "đang gõ..." trong conversation
    showTypingIndicator(userName);
  } else {
    // Ẩn indicator
    hideTypingIndicator(userName);
  }
}

// Emit typing event khi user gõ
Timer? typingTimer;

void onTextChanged(String text) {
  // Emit typing = true
  socket?.emit('typing', {
    'is_typing': true,
    'customer_id': currentCustomerId, // Nếu là staff
  });
  
  // Cancel timer cũ
  typingTimer?.cancel();
  
  // Set timer mới để emit typing = false sau 1s
  typingTimer = Timer(Duration(seconds: 1), () {
    socket?.emit('typing', {
      'is_typing': false,
      'customer_id': currentCustomerId,
    });
  });
}
```

---

## ❌ Event 4: `error` - Lỗi

### Khi nào emit:
- ✅ Lỗi authorization
- ✅ Lỗi validation (nội dung trống, thiếu customer_id, etc)
- ✅ Lỗi server

### Payload:
```json
{
  "message": "Nội dung tin nhắn trống"
}
```

### Flutter Handler:
```dart
void handleError(dynamic data) {
  print('❌ Error: ${data['message']}');
  
  // Hiển thị snackbar/toast
  showErrorSnackBar(data['message']);
}
```

---

## 📤 Gửi Events từ Flutter

### 1. Gửi tin nhắn
```dart
void sendMessage(String content, {int? customerId}) {
  final data = {
    'noi_dung': content,
  };
  
  // Nếu là staff, cần thêm customer_id
  if (isStaff && customerId != null) {
    data['customer_id'] = customerId;
  }
  
  socket?.emit('send_message', data);
}
```

### 2. Join conversation (Staff)
```dart
void joinConversation(int customerId) {
  socket?.emit('join_conversation', {
    'customer_id': customerId,
  });
}
```

### 3. Typing indicator
```dart
void sendTypingStatus(bool isTyping, {int? customerId}) {
  final data = {
    'is_typing': isTyping,
  };
  
  if (isStaff && customerId != null) {
    data['customer_id'] = customerId;
  }
  
  socket?.emit('typing', data);
}
```

---

## 🔄 Complete Flutter Integration Example

### ChatService (Singleton)
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();
  
  IO.Socket? socket;
  bool isConnected = false;
  List<Conversation> conversations = [];
  Map<int, List<ChatMessage>> messages = {};
  
  // Kết nối
  void connect(int userId, String serverUrl) {
    socket = IO.io(serverUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setAuth({'user_id': userId})
        .build()
    );
    
    socket!.onConnect((_) {
      print('✅ Connected');
      isConnected = true;
      notifyListeners();
    });
    
    socket!.onDisconnect((_) {
      print('❌ Disconnected');
      isConnected = false;
      notifyListeners();
    });
    
    // Register events
    socket!.on('new_message', _handleNewMessage);
    socket!.on('new_conversation', _handleNewConversation);
    socket!.on('user_typing', _handleUserTyping);
    socket!.on('error', _handleError);
    
    socket!.connect();
  }
  
  // Handler: Tin nhắn mới
  void _handleNewMessage(dynamic data) {
    final message = ChatMessage.fromJson(data);
    
    // Add to messages list (nếu đang mở chat detail của conversation này)
    if (!messages.containsKey(message.conversationId)) {
      messages[message.conversationId] = [];
    }
    messages[message.conversationId]!.add(message);
    
    // Update conversation's last message trong danh sách
    final convIndex = conversations.indexWhere((c) => c.id == message.conversationId);
    if (convIndex != -1) {
      // Update last message và timestamp
      conversations[convIndex].lastMessage = message;
      conversations[convIndex].lastMessageAt = message.thoiGian;
      
      // Di chuyển conversation này lên đầu danh sách (sort by last_message_at)
      final conv = conversations.removeAt(convIndex);
      conversations.insert(0, conv);
    } else {
      // Trường hợp conversation chưa có trong list (staff app có thể gặp)
      // Có thể tạo conversation object mới từ data['conversation']
      if (data.containsKey('conversation')) {
        final convData = data['conversation'];
        final newConv = Conversation(
          id: convData['id'],
          customerId: convData['customer_id'],
          customerName: convData['customer_name'] ?? 'Unknown',
          customerPhone: convData['customer_phone'],
          lastMessage: message,
          lastMessageAt: message.thoiGian,
        );
        conversations.insert(0, newConv);
      }
    }
    
    // Show notification
    _showNotification(message.nguoiGoiName, message.noiDung);
    
    notifyListeners();
  }
  
  // Handler: Conversation mới (staff only)
  void _handleNewConversation(dynamic data) {
    final conversation = Conversation.fromJson(data);
    conversation.isNew = true;
    
    conversations.insert(0, conversation);
    
    // Show notification
    _showNotification('Khách hàng mới', conversation.customerName);
    
    notifyListeners();
    
    // Remove "new" flag
    Future.delayed(Duration(seconds: 3), () {
      conversation.isNew = false;
      notifyListeners();
    });
  }
  
  // Handler: Typing
  void _handleUserTyping(dynamic data) {
    // Implement typing logic
    notifyListeners();
  }
  
  // Handler: Error
  void _handleError(dynamic data) {
    print('❌ Error: ${data['message']}');
  }
  
  // Gửi tin nhắn
  void sendMessage(String content, {int? customerId}) {
    final data = {'noi_dung': content};
    if (customerId != null) {
      data['customer_id'] = customerId;
    }
    socket?.emit('send_message', data);
  }
  
  // Disconnect
  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
  }
  
  void _showNotification(String title, String body) {
    // Implement local notification
  }
}
```

### UI Usage
```dart
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  
  @override
  void initState() {
    super.initState();
    
    // Kết nối Socket.IO
    _chatService.connect(
      widget.userId,
      'http://your-server:8001',
    );
    
    // Lắng nghe thay đổi
    _chatService.addListener(_onChatUpdate);
  }
  
  void _onChatUpdate() {
    setState(() {
      // UI sẽ rebuild với data mới
    });
  }
  
  @override
  void dispose() {
    _chatService.removeListener(_onChatUpdate);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          // Connection status
          Icon(
            _chatService.isConnected 
              ? Icons.check_circle 
              : Icons.error,
            color: _chatService.isConnected 
              ? Colors.green 
              : Colors.red,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _chatService.conversations.length,
        itemBuilder: (context, index) {
          final conv = _chatService.conversations[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(conv.customerName[0]),
            ),
            title: Text(
              conv.customerName,
              style: conv.isNew 
                ? TextStyle(fontWeight: FontWeight.bold) 
                : null,
            ),
            subtitle: Text(conv.lastMessage?.noiDung ?? ''),
            trailing: conv.isNew 
              ? Chip(label: Text('MỚI'), backgroundColor: Colors.red)
              : null,
            onTap: () {
              // Mở chat detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(conv),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 📊 Event Flow Summary

```
┌─────────────────────────────────────────────────────┐
│          Customer App (Flutter)                     │
│  • Kết nối Socket.IO với user_id                    │
│  • Lắng nghe: new_message                          │
│  • Gửi: send_message                               │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ Socket.IO (Port 8001)
                   │
┌──────────────────▼──────────────────────────────────┐
│              Server                                  │
│  • Nhận message từ customer                         │
│  • Kiểm tra: conversation mới?                      │
│    - Nếu mới: emit new_conversation → staff_room   │
│  • Lưu DB                                           │
│  • Emit new_message → staff_room + customer_id     │
└──────────────────┬──────────────────────────────────┘
                   │
                   │
┌──────────────────▼──────────────────────────────────┐
│          Staff App (Flutter)                        │
│  • Kết nối Socket.IO với user_id (staff)           │
│  • Lắng nghe: new_message, new_conversation        │
│  • Gửi: send_message (với customer_id)            │
│  • Auto join: staff_room + all customer rooms      │
└─────────────────────────────────────────────────────┘
```

---

## ⚡ Performance Tips

### 1. Reconnection Strategy
```dart
socket!.onReconnect((data) {
  print('🔄 Reconnected');
  // Reload conversations và messages
  loadConversations();
});
```

### 2. Message Pagination
```dart
// Load old messages khi scroll up
Future<void> loadMoreMessages(int conversationId, int offset) async {
  final response = await http.get(
    Uri.parse('/api/conversations/$conversationId/messages/?limit=50&offset=$offset'),
    headers: {'Authorization': 'Bearer $token'},
  );
  // Add to messages list
}
```

### 3. Background Handling
```dart
// Khi app vào background
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    // Giữ socket nhưng reduce ping interval
  } else if (state == AppLifecycleState.resumed) {
    // Reconnect nếu bị disconnect
    if (!_chatService.isConnected) {
      _chatService.connect(userId, serverUrl);
    }
  }
}
```

---

## 🔐 Security Best Practices

### 1. Token Authentication
```dart
// Thay vì user_id trần, dùng JWT token
socket = IO.io(serverUrl, 
  IO.OptionBuilder()
    .setAuth({
      'token': jwtToken, // Server verify token
    })
    .build()
);
```

### 2. Validate Messages
```dart
void _handleNewMessage(dynamic data) {
  try {
    // Validate data structure
    if (data == null || !data.containsKey('id')) {
      print('⚠️ Invalid message data');
      return;
    }
    
    final message = ChatMessage.fromJson(data);
    // Process message
  } catch (e) {
    print('❌ Error parsing message: $e');
  }
}
```

---

## 📱 Testing

### Postman (WebSocket)
Test server trước khi implement Flutter:
```
ws://localhost:8001/socket.io/?EIO=4&transport=websocket&auth=%7B%22user_id%22%3A1%7D
```

### Flutter Debug
```dart
// Enable debug logs
socket = IO.io(serverUrl, 
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .enableAutoConnect()
    .enableForceNew()
    .enableReconnection()
    .setAuth({'user_id': userId})
    .build()
);

// Log all events
socket!.onAny((event, data) {
  print('📡 Event: $event, Data: $data');
});
```

---

## 🎯 Checklist Implementation

### Customer App:
- [ ] Kết nối Socket.IO với user_id
- [ ] Lắng nghe `new_message`
- [ ] Gửi `send_message` khi chat
- [ ] Hiển thị typing indicator
- [ ] Local notification khi có tin mới
- [ ] Reconnect khi mất kết nối

### Staff App:
- [ ] Kết nối Socket.IO với user_id (staff)
- [ ] Lắng nghe `new_message`
- [ ] Lắng nghe `new_conversation` ⭐
- [ ] Gửi `send_message` với customer_id
- [ ] Hiển thị badge "MỚI" cho conversation mới
- [ ] Auto join tất cả customer rooms
- [ ] Notification sound

---

## � Push Notifications (FCM)

Hệ thống tự động gửi push notification khi có tin nhắn mới:

### Customer gửi tin → Staff nhận notification:
```json
{
  "title": "💬 Tin nhắn mới từ Nguyễn Văn A",
  "body": "Xin chào, tôi muốn đặt bàn...",
  "data": {
    "type": "chat",
    "message_id": "25",
    "conversation_id": "5",
    "customer_id": "123",
    "customer_name": "Nguyễn Văn A"
  }
}
```

### Staff trả lời → Customer nhận notification:
```json
{
  "title": "💬 Nhân viên đã trả lời",
  "body": "Dạ, chúng tôi sẽ hỗ trợ bạn ngay...",
  "data": {
    "type": "chat",
    "message_id": "26",
    "conversation_id": "5",
    "staff_id": "7"
  }
}
```

### Flutter Handler cho Push Notification:

```dart
// Lắng nghe FCM notifications
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('📬 Received FCM: ${message.notification?.title}');
  
  if (message.data['type'] == 'chat') {
    // Navigate to chat screen hoặc update UI
    final conversationId = int.parse(message.data['conversation_id']);
    
    // Option 1: Show in-app notification
    showInAppNotification(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      onTap: () {
        navigateToChatScreen(conversationId);
      },
    );
    
    // Option 2: Auto fetch messages nếu đang ở conversation đó
    if (currentConversationId == conversationId) {
      fetchLatestMessages(conversationId);
    }
  }
});

// Handle notification khi app ở background và user tap
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  if (message.data['type'] == 'chat') {
    final conversationId = int.parse(message.data['conversation_id']);
    navigateToChatScreen(conversationId);
  }
});
```

### Server Implementation:

Hệ thống sử dụng `send_to_user()` từ `restaurant.utils`:

```python
# Khi customer gửi tin
send_push_to_staff(message)  # Gửi tới TẤT CẢ nhân viên

# Khi staff trả lời
send_push_to_customer(message, customer)  # Gửi tới customer cụ thể
```

**Lưu ý:**
- ✅ Push notification chỉ gửi khi có tin nhắn MỚI
- ✅ Staff nhận notification từ TẤT CẢ customers
- ✅ Customer chỉ nhận notification từ staff
- ✅ Notification bao gồm message preview (100 ký tự đầu)
- ✅ Data payload chứa đủ thông tin để navigate

---

## �🔄 Real-time Conversation List Update

Khi nhận event `new_message`, Flutter app cần:

1. **Thêm message** vào messages list (nếu đang mở chat detail)
2. **Update last_message** của conversation tương ứng
3. **Update last_message_at** timestamp
4. **Di chuyển conversation lên đầu** danh sách (sort by recency)
5. **Increment unread count** (nếu có implement)
6. **Trigger UI rebuild** để hiển thị thay đổi

### Logic Sorting Conversations:

```dart
// Sort conversations by last_message_at (mới nhất trên cùng)
conversations.sort((a, b) {
  if (a.lastMessageAt == null) return 1;
  if (b.lastMessageAt == null) return -1;
  return b.lastMessageAt!.compareTo(a.lastMessageAt!);
});
```

### Example: Update Conversation List

```dart
void updateConversationWithNewMessage(ChatMessage message, dynamic conversationData) {
  final convIndex = conversations.indexWhere((c) => c.id == message.conversationId);
  
  if (convIndex != -1) {
    // Conversation đã tồn tại -> update
    conversations[convIndex].lastMessage = message;
    conversations[convIndex].lastMessageAt = message.thoiGian;
    
    // Move to top
    final conv = conversations.removeAt(convIndex);
    conversations.insert(0, conv);
  } else {
    // Conversation chưa có -> tạo mới (dùng data từ event)
    final newConv = Conversation.fromJson(conversationData);
    newConv.lastMessage = message;
    conversations.insert(0, newConv);
  }
  
  notifyListeners();
}
```

---

**Tóm tắt Events:**

| Event | Direction | Customer | Staff | Payload | Purpose |
|-------|-----------|----------|-------|---------|---------|
| `new_message` | Server → Client | ✅ | ✅ | message + conversation data | Update chat & conversation list |
| `new_conversation` | Server → Client | ❌ | ✅ | conversation data | Add new conversation to staff list |
| `user_typing` | Server → Client | ✅ | ✅ | typing status | Show "đang gõ..." indicator |
| `error` | Server → Client | ✅ | ✅ | error message | Show error to user |
| `send_message` | Client → Server | ✅ | ✅ | {noi_dung, customer_id?} | Send new message |
| `typing` | Client → Server | ✅ | ✅ | {is_typing, customer_id?} | Notify others of typing |
