# Tính năng Chat Real-time - Hệ thống Quản lý Nhà hàng

## 📋 Tổng quan

Hệ thống chat cho phép khách hàng nhắn tin với nhân viên nhà hàng theo cơ chế:
- **Khách hàng gửi 1 tin** → **Tất cả nhân viên đều nhận được**
- **Nhân viên gửi 1 tin** → **Khách hàng đó nhận được** + **Tất cả nhân viên khác cũng thấy**

## 🏗️ Kiến trúc

### Models đã thay đổi

#### 1. **Conversation** (MỚI)
- Đại diện cho kênh chat giữa 1 khách hàng và nhóm nhân viên
- Mỗi khách hàng có 1 conversation riêng với staff
- Fields:
  - `customer`: FK đến NguoiDung (khách hàng)
  - `is_staff_group`: Boolean (True = conversation với nhóm staff)
  - `participants`: M2M với NguoiDung (tùy chọn, cho chat 1:1 tương lai)
  - `created_at`, `last_message_at`: Timestamps

#### 2. **ChatMessage** (ĐÃ CẬP NHẬT)
- Tin nhắn thuộc về một Conversation
- Fields thay đổi:
  - ✅ **MỚI**: `conversation`: FK đến Conversation
  - ✅ **GIỮ LẠI**: `nguoi_goi`: FK đến NguoiDung (người gửi)
  - ❌ **BỎ**: `nguoi_nhan` (không cần nữa, dùng conversation)
  - `noi_dung`: TextField
  - `thoi_gian`: DateTimeField
- Methods:
  - `nguoi_goi_display()`: Hiển thị "Nhân viên" nếu staff gửi trong staff_group
  - `recipients_qs()`: QuerySet người nhận (dùng cho push notification)

## 📁 Files đã tạo

```
qlnh_backend/
├── restaurant/
│   ├── models.py                    # ✅ Đã cập nhật
│   ├── admin.py                     # ✅ Đã cập nhật (thêm ConversationAdmin, ChatMessageAdmin)
│   ├── socket_handlers.py           # 🆕 Socket.IO event handlers
│   ├── chat_serializers.py          # 🆕 DRF serializers cho chat
│   └── chat_views.py                # 🆕 REST API endpoints
├── qlnh_backend/
│   └── asgi_socketio.py             # 🆕 ASGI app với Socket.IO
├── run_socketio.py                  # 🆕 Script chạy server với eventlet
├── test_chat_client.py              # 🆕 Python test client
├── test_chat.html                   # 🆕 HTML test client (UI đẹp)
├── CHAT_SETUP_GUIDE.md              # 🆕 Hướng dẫn chi tiết
└── CHAT_SUMMARY.md                  # 📄 File này
```

## 🚀 Cài đặt & Chạy

### 1. Migrations
```powershell
python manage.py makemigrations
python manage.py migrate
```

### 2. Cập nhật URLs

Thêm vào `restaurant/urls.py`:
```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .chat_views import ConversationViewSet, ChatMessageViewSet

router = DefaultRouter()
router.register(r'conversations', ConversationViewSet, basename='conversation')
router.register(r'messages', ChatMessageViewSet, basename='message')

urlpatterns = [
    # ... existing patterns
    path('api/chat/', include(router.urls)),
]
```

### 3. Chạy Server

**Option A: uvicorn (khuyến nghị)**
```powershell
pip install uvicorn
uvicorn qlnh_backend.asgi_socketio:application --host 0.0.0.0 --port 8000 --reload
```

**Option B: eventlet**
```powershell
python run_socketio.py
```

### 4. Test

**Web UI:**
```powershell
# Mở file test_chat.html trong browser
start test_chat.html
```

**Python client:**
```powershell
# Sửa USER_ID trong test_chat_client.py trước
python test_chat_client.py
```

## 🔌 Socket.IO Events

### Client → Server

#### 1. **connect**
```javascript
const socket = io('http://localhost:8000', {
    auth: { user_id: 123 }
});
```

#### 2. **send_message**
```javascript
// Khách hàng
socket.emit('send_message', {
    noi_dung: 'Xin chào'
});

// Nhân viên (cần customer_id)
socket.emit('send_message', {
    noi_dung: 'Dạ, em chào anh/chị',
    customer_id: 123
});
```

#### 3. **typing** (optional)
```javascript
socket.emit('typing', {
    is_typing: true,
    customer_id: 123  // nếu là staff
});
```

### Server → Client

#### 1. **new_message**
```javascript
socket.on('new_message', (data) => {
    // {
    //   id: 1,
    //   conversation_id: 5,
    //   nguoi_goi_id: 123,
    //   nguoi_goi_name: 'Nguyễn Văn A' hoặc 'Nhân viên',
    //   noi_dung: 'Nội dung tin nhắn',
    //   thoi_gian: '2025-11-03T10:30:00Z'
    // }
});
```

#### 2. **user_typing**
```javascript
socket.on('user_typing', (data) => {
    // { user_id: 123, user_name: 'Nguyễn Văn A', is_typing: true }
});
```

#### 3. **error**
```javascript
socket.on('error', (error) => {
    console.error(error.message);
});
```

## 🌐 REST API Endpoints

### 1. Lấy danh sách conversations (Staff)
```http
GET /api/chat/conversations/
Authorization: Bearer {token}
```

### 2. Lấy conversation của khách hàng
```http
GET /api/chat/conversations/my_conversation/
Authorization: Bearer {token}
```

### 3. Lấy messages trong conversation
```http
GET /api/chat/conversations/{id}/messages/?limit=50&offset=0
```

### 4. Gửi message (fallback HTTP)
```http
POST /api/chat/conversations/{id}/send_message/
Content-Type: application/json

{ "noi_dung": "Tin nhắn" }
```

## 🔄 Flow hoạt động

### Khách hàng gửi tin

```
Customer (ID: 123)
    ↓
emit 'send_message' { noi_dung: "Xin chào" }
    ↓
Server:
    ├─ Tạo/lấy Conversation (customer=123, is_staff_group=True)
    ├─ Lưu ChatMessage (conversation=conv, nguoi_goi=customer)
    └─ Broadcast:
         ├─ emit 'new_message' → room 'staff_room' (tất cả staff)
         └─ emit 'new_message' → room 'customer_123' (chính khách)
```

### Nhân viên trả lời

```
Staff (ID: 456)
    ↓
emit 'send_message' { noi_dung: "Dạ", customer_id: 123 }
    ↓
Server:
    ├─ Lấy Conversation của customer 123
    ├─ Lưu ChatMessage (conversation=conv, nguoi_goi=staff)
    └─ Broadcast:
         ├─ emit 'new_message' → room 'customer_123' (khách nhận)
         └─ emit 'new_message' → room 'staff_room' (staff khác cũng thấy)
```

## 🏠 Rooms Logic

| User Type | Auto-join Rooms |
|-----------|-----------------|
| Khách hàng | `customer_{user_id}` |
| Nhân viên | `staff_room` + TẤT CẢ `customer_{id}` rooms |

**Lý do:** Staff cần tự động join tất cả customer rooms để nhận tin real-time ngay khi customer gửi.

## 🔐 Bảo mật

### Hiện tại
- ✅ Auth bằng `user_id` trong socket connect
- ✅ Validate user tồn tại khi connect
- ✅ Check quyền gửi tin (staff cần customer_id)

### Cần bổ sung (Production)
- [ ] JWT token authentication thay vì user_id trần
- [ ] Rate limiting (giới hạn số tin/phút)
- [ ] Input sanitization (XSS prevention)
- [ ] CORS config cho domain cụ thể
- [ ] Encrypt sensitive data

## 📊 Django Admin

Đã thêm admin interface cho:

### ConversationAdmin
- List view: ID, tên khách, số tin nhắn, thời gian
- Detail view: Inline hiển thị tất cả messages
- Search: Tìm theo tên/SĐT khách hàng

### ChatMessageAdmin
- List view: ID conversation, người gửi, preview nội dung, thời gian
- Filter: Theo thời gian, loại conversation
- Search: Nội dung, tên người gửi

## 🔮 Tính năng mở rộng

### Có thể thêm
- [ ] Mark as read/unread
- [ ] Push notifications (FCM integration)
- [ ] File/image upload trong chat
- [ ] Emoji/sticker support
- [ ] Chat history export
- [ ] Auto-reply bot cho common questions
- [ ] Staff assignment (chỉ định staff chăm sóc khách cụ thể)
- [ ] Chat analytics (thời gian phản hồi, satisfaction rating)

## 🐛 Troubleshooting

### Socket không kết nối được
```
✅ Check: Server đang chạy ở port 8000
✅ Check: CORS settings trong socket_handlers.py
✅ Check: user_id có tồn tại trong DB không
```

### Tin nhắn không gửi được
```
✅ Check: connected_users có user_id không (console log)
✅ Check: Staff có điền customer_id khi gửi không
✅ Check: DB có lỗi không (console log)
```

### Staff không nhận tin từ customer
```
✅ Check: Staff đã join staff_room chưa (console log)
✅ Check: emit có đúng room không
```

## 📞 Support

Nếu gặp vấn đề:
1. Check console logs (cả server và client)
2. Test với `test_chat.html` hoặc `test_chat_client.py`
3. Xem Django Admin để verify data
4. Đọc `CHAT_SETUP_GUIDE.md` để biết chi tiết

## 📝 Notes

- Models đã được thiết kế để dễ mở rộng (M2M participants cho chat 1:1)
- REST API có thể dùng như fallback nếu WebSocket fail
- Typing indicator chỉ là optional feature
- Push notification helpers đã có template trong socket_handlers.py

---

**Status:** ✅ Ready for testing
**Version:** 1.0.0
**Date:** 2025-11-03
