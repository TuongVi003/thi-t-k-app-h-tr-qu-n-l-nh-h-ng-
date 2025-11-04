# ✅ Đã cập nhật - Nhận Conversation mới Real-time

## 🆕 Tính năng mới

App nhân viên giờ đã có thể:
- **Nhận conversation mới tự động** khi khách hàng nhắn tin lần đầu
- **Hiển thị notification** khi có khách hàng mới
- **Cập nhật danh sách** real-time không cần refresh

## 📝 Những gì đã thay đổi

### 1. ChatService (`lib/services/chat_service.dart`)

**Thêm:**
- Callback `onNewConversation` để lắng nghe conversation mới
- Listener cho event `new_conversation` từ Socket.IO

```dart
// Callback mới
Function(Conversation)? onNewConversation;

// Event listener mới
_socket!.on('new_conversation', (data) {
  print('[ChatService] 🆕 New conversation: $data');
  final conversation = Conversation.fromJson(data);
  onNewConversation?.call(conversation);
});
```

### 2. ConversationsListScreen (`lib/screens/chat_screen.dart`)

**Thêm:**
- Method `_onNewConversation()` để xử lý conversation mới
- Hiển thị SnackBar notification khi có khách hàng mới
- Tự động thêm conversation mới vào đầu danh sách

```dart
void _onNewConversation(Conversation conversation) {
  // Thêm vào đầu list
  _conversations.insert(0, conversation);
  
  // Hiển thị notification
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('💬 Khách hàng mới: ...'),
      backgroundColor: Colors.green,
    ),
  );
}
```

## 🎯 Cách hoạt động

### Flow hoàn chỉnh:

```
1. Khách hàng mới (chưa từng chat) gửi tin đầu tiên
   ↓
2. Backend tạo Conversation mới
   ↓
3. Backend emit event 'new_conversation' tới staff_room
   ↓
4. Tất cả nhân viên online nhận event
   ↓
5. App Flutter:
   - ChatService nhận event
   - Gọi callback onNewConversation()
   - ConversationsListScreen cập nhật UI
   - Hiển thị SnackBar "💬 Khách hàng mới"
   ↓
6. Nhân viên thấy conversation mới ở đầu danh sách
```

## 🧪 Test tính năng

### Chuẩn bị:
1. ✅ Backend chạy cả 2 servers (port 8000 + 8001)
2. ✅ Backend đã cập nhật với event `new_conversation`
3. ✅ App nhân viên đã build lại

### Test Steps:

**Bước 1: Mở app Nhân viên**
```
1. Login với tài khoản nhân viên
2. Click nút chat (FloatingActionButton)
3. Xem danh sách conversations hiện tại
```

**Bước 2: Khách hàng mới gửi tin**
```
Option A: Dùng app Khách hàng (qlnh_app)
- Login với tài khoản khách hàng MỚI
- Gửi tin nhắn đầu tiên

Option B: Dùng test HTML
- Mở test_chat.html
- Login với customer_id mới
- Gửi tin nhắn
```

**Bước 3: Kiểm tra app Nhân viên**
```
✅ Thấy conversation mới xuất hiện ở đầu list
✅ Thấy SnackBar "💬 Khách hàng mới: [Tên]"
✅ Không cần refresh
```

### Logs mong đợi:

```
[ChatService] ✅ Connected! Socket ID: ...
[ChatService] 🆕 New conversation: {id: 5, customer_id: 10, ...}
[ConversationsListScreen] 🆕 New conversation from customer 10
```

## ⚠️ Lưu ý quan trọng

### Backend PHẢI có event này

File: `restaurant/socket_handlers_wsgi.py` hoặc `socket_handlers.py`

Phải có code này trong hàm `send_message()`:

```python
# Kiểm tra xem có phải conversation mới không
is_new_conversation = conv.messages.count() == 1

if is_new_conversation:
    conversation_data = {
        'id': conv.id,
        'customer_id': sender.id,
        'customer_name': sender.ho_ten,
        'customer_phone': sender.so_dien_thoai,
        'created_at': conv.created_at.isoformat(),
        'last_message': {
            'noi_dung': message.noi_dung,
            'thoi_gian': message.thoi_gian.isoformat()
        }
    }
    sio.emit('new_conversation', conversation_data, room='staff_room')
```

**Files backend đính kèm đã có code này!**

### Restart sau khi cập nhật

```bash
# Flutter
flutter run

# Backend (nếu cần)
# Terminal 1
python manage.py runserver

# Terminal 2
python run_socketio.py
```

## 🎨 Tùy chỉnh Notification

### Thay đổi màu sắc:

```dart
SnackBar(
  backgroundColor: Colors.blue,  // Đổi màu
  // ...
)
```

### Thêm sound:

```dart
import 'package:audioplayers/audioplayers.dart';

void _onNewConversation(Conversation conversation) {
  // ... code hiện tại
  
  // Play sound
  final player = AudioPlayer();
  player.play(AssetSource('sounds/notification.mp3'));
}
```

### Thêm badge đếm:

```dart
// Trong ConversationsListScreen state
int _unreadConversationsCount = 0;

void _onNewConversation(Conversation conversation) {
  setState(() {
    _conversations.insert(0, conversation);
    _unreadConversationsCount++;
  });
  
  // Update app badge
  FlutterAppBadger.updateBadgeCount(_unreadConversationsCount);
}
```

## 📊 Data Flow

### Event payload từ backend:

```json
{
  "id": 5,
  "customer_id": 10,
  "customer_name": "Nguyễn Văn A",
  "customer_phone": "0901234567",
  "created_at": "2025-11-03T10:30:00Z",
  "last_message": {
    "noi_dung": "Xin chào, tôi muốn đặt bàn",
    "thoi_gian": "2025-11-03T10:30:00Z"
  }
}
```

### Model mapping:

```dart
Conversation.fromJson(data) {
  id: 5,
  customerId: 10,
  customerInfo: CustomerInfo(
    hoTen: "Nguyễn Văn A",
    soDienThoai: "0901234567",
  ),
  lastMessage: ChatMessage(...),
}
```

## ✅ Checklist hoàn thành

- [x] Thêm callback `onNewConversation` trong ChatService
- [x] Thêm listener cho event `new_conversation`
- [x] Implement `_onNewConversation()` trong ConversationsListScreen
- [x] Hiển thị SnackBar notification
- [x] Tự động thêm conversation vào đầu list
- [x] Kiểm tra duplicate (không thêm nếu đã có)
- [x] Test với khách hàng mới

## 🚀 Ready to use!

Bây giờ app nhân viên đã có đầy đủ tính năng:
- ✅ Chat real-time qua Socket.IO
- ✅ Nhận tin nhắn mới tự động
- ✅ Nhận conversation mới tự động
- ✅ Hiển thị notification
- ✅ Cập nhật UI real-time

**Chỉ cần đảm bảo backend đã có URL routing cho `/api/conversations/` là OK!**

---

**Vẫn còn lỗi 404?** → Đọc file `FIX_404_STEP_BY_STEP.md`
