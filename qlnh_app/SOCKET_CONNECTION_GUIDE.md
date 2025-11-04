# Hướng dẫn kết nối Socket.IO với Django Backend

## 📋 Tổng quan

Tài liệu này mô tả chi tiết các bước để tích hợp Socket.IO vào Flutter app và kết nối với Django backend để thực hiện real-time chat.

---

## 🎯 Kiến trúc hệ thống

```
┌─────────────────┐         Socket.IO          ┌──────────────────┐
│   Flutter App   │◄──────────────────────────►│  Socket.IO Server│
│  (Port Client)  │     WebSocket/Polling      │   (Port 8001)    │
└─────────────────┘                            └──────────────────┘
         │                                              │
         │         REST API (HTTP)                      │
         │◄────────────────────────────────────────────►│
         │                                              │
         ▼                                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Django REST Framework                        │
│                      (Port 8000)                                │
│                         Database                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Bước 1: Cài đặt Dependencies

### Backend (Django)

```bash
# Cài đặt Socket.IO cho Python
pip install python-socketio

# Cài đặt WSGI server (eventlet)
pip install eventlet
```

### Frontend (Flutter)

Thêm vào `pubspec.yaml`:
```yaml
dependencies:
  socket_io_client: ^3.1.2
```

Chạy:
```bash
flutter pub get
```

---

## 🏗️ Bước 2: Cấu trúc Backend

### 2.1. Tạo Socket.IO Handler (WSGI Mode)

File: `restaurant/socket_handlers_wsgi.py`

```python
import socketio
from restaurant.models import Conversation, ChatMessage, NguoiDung

# Tạo Socket.IO server instance (WSGI mode với eventlet)
sio = socketio.Server(
    async_mode='eventlet',
    cors_allowed_origins='*',  # Production: chỉ định domain cụ thể
    logger=True,
    engineio_logger=True
)

# Track connected users
connected_users = {}  # {socket_id: user_id}

@sio.event
def connect(sid, environ, auth):
    """Xử lý kết nối"""
    if not auth or 'user_id' not in auth:
        return False  # Từ chối kết nối
    
    user_id = auth.get('user_id')
    user = NguoiDung.objects.get(id=user_id)
    connected_users[sid] = user_id
    
    # Join rooms dựa trên loại user
    if user.loai_nguoi_dung == 'khach_hang':
        sio.enter_room(sid, f"customer_{user_id}")
    elif user.loai_nguoi_dung == 'nhan_vien':
        sio.enter_room(sid, 'staff_room')
    
    return True

@sio.event
def send_message(sid, data):
    """Xử lý gửi tin nhắn"""
    user_id = connected_users.get(sid)
    sender = NguoiDung.objects.get(id=user_id)
    
    # Lưu vào database
    message = ChatMessage.objects.create(
        conversation=conversation,
        nguoi_goi=sender,
        noi_dung=data['noi_dung']
    )
    
    # Broadcast tin nhắn
    message_data = {
        'id': message.id,
        'nguoi_goi_id': sender.id,
        'noi_dung': message.noi_dung,
        'thoi_gian': message.thoi_gian.isoformat(),
    }
    sio.emit('new_message', message_data, room=target_room)
```

### 2.2. Tạo Script chạy Socket.IO Server

File: `run_socketio.py` (root của project backend)

```python
import eventlet
eventlet.monkey_patch()

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'qlnh_backend.settings')
django.setup()

from restaurant.socket_handlers_wsgi import sio

if __name__ == '__main__':
    print("🚀 Starting Socket.IO server on port 8001...")
    
    # Chạy WSGI server với eventlet
    eventlet.wsgi.server(
        eventlet.listen(('0.0.0.0', 8001)),
        sio,
        log_output=True
    )
```

---

## 📱 Bước 3: Cấu hình Flutter App

### 3.1. Tạo API Constants

File: `lib/constants/api.dart`

```dart
class ApiEndpoints {
  // REST API Server
  static const String baseUrl = 'http://localhost:8000';
  
  // Socket.IO Server (quan trọng!)
  static const String socketUrl = 'http://localhost:8001';
  
  // REST endpoints
  static const String login = '$baseUrl/o/token/';
  // ... các endpoints khác
}
```

**Lưu ý quan trọng:**
- `baseUrl`: Django REST API (port 8000)
- `socketUrl`: Socket.IO server (port 8001)
- Nếu dùng ngrok/tunnel, thay bằng URL public

### 3.2. Tạo Models

#### File: `lib/models/conversation.dart`

```dart
class Conversation {
  final int id;
  final int? customerId;
  final String? customerName;
  final bool isStaffGroup;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  Conversation({
    required this.id,
    this.customerId,
    this.customerName,
    required this.isStaffGroup,
    required this.createdAt,
    this.lastMessageAt,
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
    );
  }
}
```

#### File: `lib/models/chat_message.dart`

```dart
class ChatMessage {
  final int id;
  final int conversationId;
  final int nguoiGoiId;
  final String nguoiGoiName;
  final String noiDung;
  final DateTime thoiGian;
  final bool isSentByMe;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.nguoiGoiId,
    required this.nguoiGoiName,
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
      noiDung: json['noi_dung'],
      thoiGian: DateTime.parse(json['thoi_gian']),
      isSentByMe: currentUserId != null && nguoiGoiId == currentUserId,
    );
  }
}
```

### 3.3. Tạo Chat Service (Kết nối Socket.IO)

File: `lib/services/chat_service.dart`

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api.dart';
import '../models/chat_message.dart';

class ChatService {
  static final ChatService instance = ChatService._privateConstructor();
  ChatService._privateConstructor();

  IO.Socket? _socket;
  int? _currentUserId;
  
  // Callbacks
  Function(ChatMessage)? onNewMessage;
  Function(String)? onError;
  Function(bool)? onConnectionChange;

  bool get isConnected => _socket?.connected ?? false;

  /// Bước quan trọng: Kết nối tới Socket.IO server
  Future<void> connect(int userId) async {
    _currentUserId = userId;

    print('[ChatService] Connecting to ${ApiEndpoints.socketUrl}');
    
    // Tạo socket instance
    _socket = IO.io(
      ApiEndpoints.socketUrl,  // URL của Socket.IO server
      IO.OptionBuilder()
          .setTransports(['websocket'])  // Sử dụng WebSocket
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(5)
          .setAuth({
            'user_id': userId,  // Gửi user_id khi kết nối
          })
          .build(),
    );

    // Setup listeners
    _setupSocketListeners();

    // Kết nối
    _socket!.connect();
  }

  void _setupSocketListeners() {
    // Kết nối thành công
    _socket!.on('connect', (_) {
      print('[ChatService] ✅ Connected! Socket ID: ${_socket!.id}');
      onConnectionChange?.call(true);
    });

    // Mất kết nối
    _socket!.on('disconnect', (_) {
      print('[ChatService] ❌ Disconnected');
      onConnectionChange?.call(false);
    });

    // Lỗi kết nối
    _socket!.on('connect_error', (data) {
      print('[ChatService] ⚠️ Connection error: $data');
      onError?.call('Lỗi kết nối: $data');
    });

    // Nhận tin nhắn mới
    _socket!.on('new_message', (data) {
      print('[ChatService] 📩 New message: $data');
      final message = ChatMessage.fromJson(data, currentUserId: _currentUserId);
      onNewMessage?.call(message);
    });

    // Lỗi từ server
    _socket!.on('error', (data) {
      print('[ChatService] ❌ Server error: $data');
      onError?.call(data['message'] ?? 'Có lỗi xảy ra');
    });
  }

  /// Gửi tin nhắn qua Socket.IO
  void sendMessage(String noiDung, {int? customerId}) {
    if (_socket == null || !_socket!.connected) {
      onError?.call('Chưa kết nối tới server');
      return;
    }

    final data = {
      'noi_dung': noiDung.trim(),
      if (customerId != null) 'customer_id': customerId,
    };

    print('[ChatService] 📤 Sending: $data');
    _socket!.emit('send_message', data);  // Emit event
  }

  /// Ngắt kết nối
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
```

### 3.4. Tạo Chat Screen

File: `lib/presentations/chat/chat_screen.dart`

```dart
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService.instance;
  List<ChatMessage> _messages = [];
  bool _isConnected = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Lấy thông tin user
    _currentUser = await UserService.instance.getCurrentUser();
    
    // Kết nối Socket.IO
    await _chatService.connect(_currentUser!.id);
    
    // Setup callbacks
    _chatService.onNewMessage = (message) {
      setState(() => _messages.add(message));
    };
    
    _chatService.onConnectionChange = (connected) {
      setState(() => _isConnected = connected);
    };
    
    // Load messages từ API
    final conversation = await _chatService.getMyConversation();
    final messages = await _chatService.getMessages(conversation!.id);
    setState(() => _messages = messages);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    // Gửi qua Socket.IO
    _chatService.sendMessage(text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isConnected ? '● Đang kết nối' : '○ Không kết nối'),
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          // Input
          _buildInputArea(),
        ],
      ),
    );
  }
}
```

---

## 🔄 Bước 4: Flow kết nối chi tiết

### 4.1. Quá trình kết nối

```
1. User đăng nhập → Nhận user_id
   ↓
2. ChatService.connect(user_id)
   ↓
3. Tạo IO.Socket với config:
   - URL: ApiEndpoints.socketUrl (http://localhost:8001)
   - Transport: websocket
   - Auth: {user_id: xxx}
   ↓
4. socket.connect() → Gửi request tới server
   ↓
5. Backend nhận kết nối:
   - Kiểm tra auth payload
   - Verify user_id tồn tại
   - Join vào rooms tương ứng
   ↓
6. Emit 'connect' event → Client nhận được
   ↓
7. Callbacks được gọi:
   - onConnectionChange(true)
   - Hiển thị "● Đang kết nối"
```

### 4.2. Quá trình gửi tin nhắn

```
1. User gõ tin nhắn và nhấn gửi
   ↓
2. ChatService.sendMessage(noiDung)
   ↓
3. socket.emit('send_message', {noi_dung: '...'})
   ↓
4. Backend nhận event 'send_message':
   - Kiểm tra user_id từ connected_users
   - Lưu message vào database
   - Broadcast tới các rooms tương ứng
   ↓
5. Backend emit 'new_message' với message data
   ↓
6. Tất cả clients trong room nhận được:
   - Event 'new_message'
   - Callback onNewMessage được gọi
   - UI cập nhật với tin nhắn mới
```

---

## 🔍 Bước 5: Debug và Troubleshooting

### 5.1. Kiểm tra kết nối

**Flutter Console:**
```
[ChatService] Connecting to http://localhost:8001
[ChatService] ✅ Connected! Socket ID: abc123xyz
```

**Backend Console:**
```
[CONNECT] Client abc123xyz connected
[CONNECT] User John Doe (5) connected as abc123xyz
[JOIN] Customer 5 joined room: customer_5
```

### 5.2. Các lỗi thường gặp

#### ❌ Lỗi: "Connection error: Error: xhr poll error"

**Nguyên nhân:**
- Socket.IO server không chạy
- URL sai trong api.dart

**Giải pháp:**
```bash
# Kiểm tra server đang chạy
netstat -ano | findstr :8001

# Chạy lại server
python run_socketio.py
```

#### ❌ Lỗi: "Unauthorized" / Kết nối bị từ chối

**Nguyên nhân:**
- Không gửi user_id trong auth
- user_id không tồn tại

**Giải pháp:**
```dart
// Kiểm tra auth config
.setAuth({
  'user_id': userId,  // Phải có
})
```

#### ❌ Lỗi: "CORS policy"

**Nguyên nhân:**
- CORS không được cấu hình đúng

**Giải pháp:**
```python
# Trong socket_handlers_wsgi.py
sio = socketio.Server(
    cors_allowed_origins='*',  # Hoặc domain cụ thể
)
```

### 5.3. Test Socket.IO bằng code JavaScript

```javascript
// test.js
const io = require('socket.io-client');

const socket = io('http://localhost:8001', {
  auth: { user_id: 5 }
});

socket.on('connect', () => {
  console.log('✅ Connected!');
  
  socket.emit('send_message', {
    noi_dung: 'Test message from JS'
  });
});

socket.on('new_message', (data) => {
  console.log('📩 New message:', data);
});

socket.on('error', (error) => {
  console.log('❌ Error:', error);
});
```

---

## 📊 Bước 6: Monitoring

### Kiểm tra kết nối active

```python
# Thêm vào socket_handlers_wsgi.py
@sio.event
def get_active_users(sid):
    return {
        'total': len(connected_users),
        'users': list(connected_users.values())
    }
```

### Log events

```dart
// Trong chat_service.dart
_socket!.onAny((event, data) {
  print('[Socket Event] $event: $data');
});
```

---

## ✅ Checklist triển khai

- [ ] Cài đặt `python-socketio` và `eventlet`
- [ ] Tạo file `socket_handlers_wsgi.py`
- [ ] Tạo file `run_socketio.py`
- [ ] Thêm `socket_io_client` vào `pubspec.yaml`
- [ ] Cấu hình `socketUrl` trong `api.dart`
- [ ] Tạo models (Conversation, ChatMessage)
- [ ] Tạo ChatService với Socket.IO
- [ ] Tạo ChatScreen UI
- [ ] Test kết nối và gửi tin nhắn
- [ ] Handle errors và reconnection

---

## 🚀 Kết luận

Bạn đã hoàn thành việc tích hợp Socket.IO giữa Flutter và Django! Các điểm chính:

1. **Backend**: Socket.IO server chạy riêng trên port 8001 với eventlet
2. **Frontend**: Socket.IO client kết nối với auth payload (user_id)
3. **Real-time**: Events được emit và broadcast qua rooms
4. **Fallback**: REST API vẫn hoạt động nếu Socket.IO fail

**Chạy hệ thống:**
```powershell
# Terminal 1
python manage.py runserver

# Terminal 2  
python run_socketio.py

# Flutter
flutter run
```

Giờ bạn có một hệ thống chat real-time hoàn chỉnh! 🎉
