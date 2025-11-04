# 🐛 Fix: Duplicate Messages Issue

## Vấn đề

Khi gửi hoặc nhận tin nhắn, **messages bị hiển thị duplicate** (2 lần) trong UI, mặc dù database chỉ lưu 1 record.

### Ví dụ:
```
[14:39] hieu: hello
[14:39] hieu: hello  ← DUPLICATE
[15:10] hieu: OO
[15:10] hieu: OO     ← DUPLICATE
```

---

## 🔍 Nguyên nhân

### 1. Backend emit tin nhắn tới NHIỀU rooms

**File:** `socket_handlers_wsgi.py`

```python
@sio.event
def send_message(sid, data):
    # ...
    
    # Broadcast tin nhắn
    if sender.loai_nguoi_dung == 'khach_hang':
        # Gửi tới 2 rooms:
        sio.emit('new_message', message_data, room='staff_room')          # ← Room 1
        sio.emit('new_message', message_data, room=f"customer_{sender.id}") # ← Room 2
```

### 2. Staff JOIN VÀO CẢ 2 rooms

**File:** `socket_handlers_wsgi.py`

```python
@sio.event
def connect(sid, environ, auth):
    # ...
    if user.loai_nguoi_dung == 'nhan_vien':
        # Staff join staff room
        sio.enter_room(sid, 'staff_room')  # ← Join room 1
        
        # Staff also joins all active customer rooms
        conversations = Conversation.objects.filter(is_staff_group=True)
        for conv in conversations:
            if conv.customer:
                customer_room = f"customer_{conv.customer.id}"
                sio.enter_room(sid, customer_room)  # ← Join room 2, 3, 4...
```

### 3. Kết quả: Client nhận TIN NHẮN 2 LẦN

```
Customer gửi tin "hello"
    ↓
Backend emit → staff_room
    ↓
Flutter Staff App nhận event lần 1 ✅
    ↓
Backend emit → customer_6 room
    ↓
Flutter Staff App nhận event lần 2 ❌ (DUPLICATE!)
    ↓
_onNewMessage() được gọi 2 lần
    ↓
_messages.add(message) × 2
    ↓
UI hiển thị 2 tin giống nhau
```

---

## ✅ Giải pháp

### 1. Kiểm tra duplicate trong ChatDetailScreen

**File:** `lib/screens/chat_screen.dart`

**Trước khi fix:**
```dart
void _onNewMessage(ChatMessage message) {
  if (message.conversationId == widget.conversation.id) {
    setState(() {
      _messages.add(message);  // ❌ Luôn add, không check duplicate
    });
  }
}
```

**Sau khi fix:**
```dart
void _onNewMessage(ChatMessage message) {
  if (message.conversationId == widget.conversation.id) {
    setState(() {
      // ✅ Kiểm tra duplicate bằng message ID
      final exists = _messages.any((m) => m.id == message.id);
      if (!exists) {
        _messages.add(message);
      } else {
        print('[ChatDetailScreen] ⚠️ Duplicate message ignored: ID ${message.id}');
      }
    });
    // ... scroll logic
  }
}
```

**Logic:**
- So sánh `message.id` với tất cả messages đã có trong `_messages`
- Nếu đã tồn tại → Bỏ qua (không add)
- Nếu chưa có → Add vào list

---

### 2. Kiểm tra duplicate trong ConversationsListScreen

**File:** `lib/screens/chat_screen.dart`

**Trước khi fix:**
```dart
void _onNewMessage(ChatMessage message) {
  setState(() {
    final index = _conversations.indexWhere((c) => c.id == message.conversationId);
    if (index != -1) {
      // Cập nhật last message
      final updatedConv = Conversation(...);
      _conversations.removeAt(index);
      _conversations.insert(0, updatedConv);  // ❌ Luôn update
    }
  });
}
```

**Sau khi fix:**
```dart
void _onNewMessage(ChatMessage message) {
  setState(() {
    final index = _conversations.indexWhere((c) => c.id == message.conversationId);
    if (index != -1) {
      // ✅ Kiểm tra duplicate
      final currentLastMessage = _conversations[index].lastMessage;
      if (currentLastMessage != null && currentLastMessage.id == message.id) {
        print('[ConversationsListScreen] ⚠️ Duplicate message ignored: ID ${message.id}');
        return;  // Đã xử lý rồi, bỏ qua
      }
      
      // Cập nhật last message
      final updatedConv = Conversation(...);
      _conversations.removeAt(index);
      _conversations.insert(0, updatedConv);
    }
  });
}
```

---

### 3. Override equality operators cho ChatMessage

**File:** `lib/models/chat_models.dart`

**Thêm vào class ChatMessage:**
```dart
class ChatMessage {
  final int id;
  // ... other fields
  
  // Override equality để so sánh messages dựa trên ID
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

**Lợi ích:**
- So sánh messages chính xác hơn
- Có thể dùng `==` thay vì `.any((m) => m.id == message.id)`
- Tương thích với Set, Map operations

---

## 🧪 Testing

### Test Case 1: Customer gửi tin
**Steps:**
1. Mở Staff App → Vào chat với customer
2. Mở Customer App → Gửi tin "Hello"
3. Kiểm tra Staff App

**Expected:**
- ✅ Hiển thị 1 tin "Hello" duy nhất
- ❌ KHÔNG hiển thị duplicate

**Console log:**
```
[ChatService] 📩 New message: {id: 1, noi_dung: "Hello", ...}
[ChatDetailScreen] Message added: ID 1
[ChatService] 📩 New message: {id: 1, noi_dung: "Hello", ...}  ← Lần 2
[ChatDetailScreen] ⚠️ Duplicate message ignored: ID 1         ← BỊ CHẶN
```

---

### Test Case 2: Staff gửi tin
**Steps:**
1. Staff App → Nhập "Hi there" → Gửi
2. Kiểm tra UI

**Expected:**
- ✅ Hiển thị 1 tin "Hi there" duy nhất
- ❌ KHÔNG hiển thị duplicate

---

### Test Case 3: Conversations list update
**Steps:**
1. Mở Staff App → Màn hình conversations list
2. Customer gửi tin mới
3. Kiểm tra last_message update

**Expected:**
- ✅ Last message cập nhật 1 lần duy nhất
- ✅ Conversation di chuyển lên đầu 1 lần
- ❌ KHÔNG bị update nhiều lần

---

## 📊 Flow Diagram

### Trước khi fix (BUG):
```
Customer gửi "hello"
    ↓
Backend emit → staff_room
    ↓
Flutter: _onNewMessage(message_id_1)
    ↓
_messages.add(message_id_1)  ✅ OK
    ↓
Backend emit → customer_6
    ↓
Flutter: _onNewMessage(message_id_1)  ← Lần 2 với CÙNG ID
    ↓
_messages.add(message_id_1)  ❌ DUPLICATE!
    ↓
UI render: ["hello", "hello"]  ← 2 items
```

### Sau khi fix (FIXED):
```
Customer gửi "hello"
    ↓
Backend emit → staff_room
    ↓
Flutter: _onNewMessage(message_id_1)
    ↓
Check: exists = _messages.any((m) => m.id == 1)  → false
    ↓
_messages.add(message_id_1)  ✅ OK
    ↓
Backend emit → customer_6
    ↓
Flutter: _onNewMessage(message_id_1)  ← Lần 2 với CÙNG ID
    ↓
Check: exists = _messages.any((m) => m.id == 1)  → TRUE ⚠️
    ↓
Skip add!  ✅ BLOCKED
    ↓
UI render: ["hello"]  ← 1 item duy nhất
```

---

## 🎯 Alternative Solutions (Not Used)

### Option A: Backend emit chỉ 1 lần (KHÔNG DÙNG)
**Ưu điểm:** Giải quyết từ gốc
**Nhược điểm:** 
- Phải sửa backend (phức tạp hơn)
- Ảnh hưởng đến customer app
- Staff sẽ không nhận được tin khi ở room khác

### Option B: Dùng Set thay vì List (KHÔNG DÙNG)
```dart
Set<ChatMessage> _messages = {};  // Set tự động loại duplicate
```
**Ưu điểm:** Tự động deduplicate
**Nhược điểm:**
- Phải maintain insertion order thủ công
- Phức tạp hơn với ListView.builder

### Option C: Debounce events (KHÔNG DÙNG)
```dart
Timer? _debounceTimer;

void _onNewMessage(ChatMessage message) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 100), () {
    // Process message
  });
}
```
**Ưu điểm:** Giảm số lần xử lý
**Nhược điểm:**
- Vẫn có thể duplicate nếu 2 events cách nhau > 100ms
- Delay response time

---

## ✅ Checklist

- [x] Thêm duplicate check trong `ChatDetailScreen._onNewMessage()`
- [x] Thêm duplicate check trong `ConversationsListScreen._onNewMessage()`
- [x] Override `==` và `hashCode` trong `ChatMessage`
- [x] Test với customer gửi tin
- [x] Test với staff gửi tin
- [x] Test conversation list update
- [x] Verify console logs không còn duplicate

---

## 🚀 Deployment

### Trước khi deploy:
1. ✅ Test trên local environment
2. ✅ Kiểm tra console logs
3. ✅ Verify UI không còn duplicate
4. ✅ Test với nhiều conversations

### Sau khi deploy:
1. Monitor logs cho warning "Duplicate message ignored"
2. Nếu thấy quá nhiều warnings → Xem xét tối ưu backend rooms

---

## 📝 Notes

### Tại sao backend emit nhiều lần?
**Thiết kế hợp lý cho 2 mục đích:**

1. **staff_room**: Để tất cả staff (kể cả staff đang ở màn hình list) nhận được tin
2. **customer_{id}**: Để staff đang trong chat với customer đó nhận tin real-time

**Trade-off:**
- ✅ Real-time notification cho tất cả staff
- ❌ Duplicate events (nhưng đã fix ở client side)

### Message ID làm unique identifier
- ✅ Database auto-increment, guaranteed unique
- ✅ Immutable sau khi tạo
- ✅ Đơn giản, reliable

---

## 🔧 Future Improvements

### 1. Backend optimization (optional)
```python
# Chỉ emit tới 1 room dựa trên context
if staff_in_chat_screen:
    sio.emit('new_message', data, room=f"customer_{id}")
else:
    sio.emit('new_message', data, room='staff_room')
```

### 2. Client-side message queue (advanced)
```dart
class MessageQueue {
  final Set<int> _processedIds = {};
  
  bool shouldProcess(int messageId) {
    if (_processedIds.contains(messageId)) return false;
    _processedIds.add(messageId);
    return true;
  }
}
```

---

## 📞 Support

Nếu vẫn thấy duplicate messages:

1. **Check console logs:**
   ```
   [ChatDetailScreen] ⚠️ Duplicate message ignored: ID xxx
   ```
   Nếu thấy log này → Fix đang hoạt động

2. **Check message IDs:**
   ```dart
   print('Message IDs: ${_messages.map((m) => m.id).toList()}');
   ```
   Nếu có IDs trùng nhau → Vẫn còn bug

3. **Force reload:**
   ```dart
   await _loadMessages();  // Reload from API
   ```

---

**Status:** ✅ **FIXED**  
**Version:** 1.0  
**Date:** 2025-11-04  
**Author:** AI Assistant
