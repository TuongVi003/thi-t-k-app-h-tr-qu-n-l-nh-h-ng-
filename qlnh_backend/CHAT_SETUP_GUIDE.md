# Hướng dẫn tích hợp Socket.IO Chat cho hệ thống nhà hàng

## Kiến trúc
- **Conversation**: Kênh chat giữa 1 khách hàng và toàn bộ nhân viên
- **ChatMessage**: Tin nhắn trong conversation
- **Socket.IO**: Real-time messaging
- **REST API**: Lấy lịch sử chat, gửi tin qua HTTP (fallback)

## Cài đặt

### 1. Đã cài đặt (theo bạn)
```bash
pip install python-socketio
pip install eventlet
```

### 2. Cấu trúc files đã tạo
- `restaurant/socket_handlers.py` - Socket.IO event handlers
- `qlnh_backend/asgi_socketio.py` - ASGI app với Socket.IO
- `restaurant/chat_serializers.py` - Serializers cho chat
- `restaurant/chat_views.py` - REST API views

### 3. Cập nhật URLs

Thêm vào `restaurant/urls.py`:
```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .chat_views import ConversationViewSet, ChatMessageViewSet

router = DefaultRouter()
router.register(r'conversations', ConversationViewSet, basename='conversation')
router.register(r'messages', ChatMessageViewSet, basename='message')

urlpatterns = [
    # ... existing urls
    path('api/chat/', include(router.urls)),
]
```

### 4. Chạy migrations
```powershell
python manage.py makemigrations
python manage.py migrate
```

### 5. Chạy server với Socket.IO

**Option A: Sử dụng uvicorn (khuyến nghị)**
```powershell
pip install uvicorn
uvicorn qlnh_backend.asgi_socketio:application --host 0.0.0.0 --port 8000 --reload
```

**Option B: Sử dụng eventlet**
```powershell
# Tạo file run_socketio.py ở thư mục gốc
```

## Cách sử dụng

### Socket.IO Events

#### 1. Connect (Client -> Server)
```javascript
// JavaScript client example
const socket = io('http://localhost:8000', {
    auth: {
        user_id: 123  // ID của user đăng nhập
    }
});

socket.on('connect', () => {
    console.log('Connected to server');
});
```

#### 2. Send Message (Client -> Server)
```javascript
// Khách hàng gửi tin
socket.emit('send_message', {
    noi_dung: 'Xin chào, tôi muốn đặt bàn'
});

// Nhân viên gửi tin (cần customer_id)
socket.emit('send_message', {
    noi_dung: 'Dạ, chúng tôi sẽ hỗ trợ anh/chị ngay',
    customer_id: 123
});
```

#### 3. Nhận tin nhắn mới (Server -> Client)
```javascript
socket.on('new_message', (data) => {
    console.log('New message:', data);
    // data = {
    //     id: 1,
    //     conversation_id: 5,
    //     nguoi_goi_id: 123,
    //     nguoi_goi_name: 'Nhân viên' or 'Nguyễn Văn A',
    //     noi_dung: 'Nội dung tin nhắn',
    //     thoi_gian: '2025-11-03T10:30:00'
    // }
});
```

#### 4. Typing indicator (Optional)
```javascript
// Khi user đang gõ
socket.emit('typing', {
    is_typing: true,
    customer_id: 123  // nếu là staff
});

// Nhận thông báo typing
socket.on('user_typing', (data) => {
    console.log(`${data.user_name} đang gõ...`);
});
```

#### 5. Error handling
```javascript
socket.on('error', (error) => {
    console.error('Socket error:', error);
});
```

### REST API Endpoints

#### 1. Lấy danh sách conversations (Staff)
```http
GET /api/chat/conversations/
Authorization: Bearer {token}
```

Response:
```json
[
    {
        "id": 1,
        "customer": 123,
        "customer_info": {
            "id": 123,
            "username": "customer1",
            "ho_ten": "Nguyễn Văn A",
            "loai_nguoi_dung": "khach_hang"
        },
        "is_staff_group": true,
        "created_at": "2025-11-03T10:00:00",
        "last_message_at": "2025-11-03T10:30:00",
        "last_message": {
            "id": 5,
            "noi_dung": "Cảm ơn nhà hàng",
            "thoi_gian": "2025-11-03T10:30:00",
            "nguoi_goi_name": "Nguyễn Văn A"
        },
        "unread_count": 0
    }
]
```

#### 2. Lấy conversation của khách hàng
```http
GET /api/chat/conversations/my_conversation/
Authorization: Bearer {token}
```

#### 3. Lấy messages trong conversation
```http
GET /api/chat/conversations/{id}/messages/?limit=50&offset=0
Authorization: Bearer {token}
```

#### 4. Gửi message qua HTTP (fallback)
```http
POST /api/chat/conversations/{id}/send_message/
Authorization: Bearer {token}
Content-Type: application/json

{
    "noi_dung": "Xin chào"
}
```

## Flow hoạt động

### Khách hàng gửi tin
1. Customer connect socket với `user_id`
2. Socket auto join room `customer_{user_id}`
3. Customer emit `send_message` với `noi_dung`
4. Server:
   - Tạo/lấy Conversation cho customer
   - Lưu ChatMessage vào DB
   - Emit `new_message` tới `staff_room` (tất cả staff nhận)
   - Emit `new_message` tới `customer_{id}` (customer thấy tin mình gửi)

### Nhân viên trả lời
1. Staff connect socket với `user_id`
2. Socket auto join `staff_room` và tất cả `customer_{id}` rooms
3. Staff emit `send_message` với `noi_dung` và `customer_id`
4. Server:
   - Lấy Conversation của customer đó
   - Lưu ChatMessage
   - Emit `new_message` tới `customer_{id}` (customer nhận)
   - Emit `new_message` tới `staff_room` (staff khác cũng thấy)

### Rooms logic
- `staff_room`: Tất cả nhân viên
- `customer_{id}`: Mỗi khách hàng có 1 room riêng
- Staff tự động join tất cả customer rooms để nhận tin real-time

## Testing

### Test với Python client
```python
import socketio

sio = socketio.Client()

@sio.on('connect')
def on_connect():
    print('Connected')

@sio.on('new_message')
def on_new_message(data):
    print('New message:', data)

# Connect
sio.connect('http://localhost:8000', auth={'user_id': 123})

# Send message
sio.emit('send_message', {'noi_dung': 'Hello from Python'})

# Keep running
sio.wait()
```

### Test với JavaScript (Browser)
```html
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
</head>
<body>
    <input id="messageInput" type="text" />
    <button onclick="sendMessage()">Send</button>
    <div id="messages"></div>

    <script>
        const socket = io('http://localhost:8000', {
            auth: { user_id: 123 }
        });

        socket.on('new_message', (data) => {
            const div = document.getElementById('messages');
            div.innerHTML += `<p><b>${data.nguoi_goi_name}:</b> ${data.noi_dung}</p>`;
        });

        function sendMessage() {
            const input = document.getElementById('messageInput');
            socket.emit('send_message', {
                noi_dung: input.value
            });
            input.value = '';
        }
    </script>
</body>
</html>
```

## Push Notifications (Optional)

Để gửi push notifications khi có tin nhắn mới, implement các functions trong `socket_handlers.py`:

```python
from firebase_admin import messaging

async def send_push_to_staff(message):
    """Gửi push tới tất cả staff devices"""
    devices = await sync_to_async(list)(
        FCMDevice.objects.filter(user__loai_nguoi_dung='nhan_vien')
    )
    
    for device in devices:
        try:
            messaging.send(messaging.Message(
                notification=messaging.Notification(
                    title=f'Tin nhắn mới từ {message.nguoi_goi.ho_ten}',
                    body=message.noi_dung[:100]
                ),
                token=device.token
            ))
        except Exception as e:
            print(f'Push error: {e}')
```

## Production Deployment

### 1. Sử dụng Redis adapter cho multiple workers
```python
# pip install aioredis
import socketio

mgr = socketio.AsyncRedisManager('redis://localhost:6379')
sio = socketio.AsyncServer(
    client_manager=mgr,
    async_mode='asgi',
    cors_allowed_origins=['https://yourdomain.com']
)
```

### 2. Nginx configuration
```nginx
location /socket.io/ {
    proxy_pass http://localhost:8000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
}
```

### 3. Systemd service
```ini
[Unit]
Description=Restaurant Chat Socket.IO
After=network.target

[Service]
User=www-data
WorkingDirectory=/path/to/qlnh_backend
ExecStart=/path/to/venv/bin/uvicorn qlnh_backend.asgi_socketio:application --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

## Troubleshooting

### Socket không kết nối được
- Kiểm tra CORS settings trong `socket_handlers.py`
- Kiểm tra port 8000 có đang chạy không
- Kiểm tra auth payload có đúng không

### Message không gửi được
- Kiểm tra user_id trong connected_users
- Kiểm tra customer_id khi staff gửi tin
- Xem logs trong console

### Staff không nhận được tin từ customer
- Kiểm tra staff đã join staff_room chưa
- Kiểm tra emit có đúng room không

## Lưu ý bảo mật

1. **Authentication**: Validate token trong auth payload
2. **Authorization**: Kiểm tra quyền truy cập conversation
3. **Rate limiting**: Giới hạn số message/phút
4. **Input validation**: Sanitize noi_dung để tránh XSS
5. **CORS**: Chỉ cho phép domain cụ thể trong production
