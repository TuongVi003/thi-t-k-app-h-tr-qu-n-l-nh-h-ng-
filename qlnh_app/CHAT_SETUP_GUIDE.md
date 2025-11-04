# Hướng dẫn cài đặt và chạy chức năng Chat với Socket.IO

## Tổng quan
Chức năng chat đã được tích hợp vào ứng dụng Flutter với:
- Socket.IO client để real-time messaging
- REST API fallback cho tin nhắn
- Floating Action Button trên trang chủ để truy cập chat

## Các file đã tạo

### Flutter App (qlnh_app)
1. **models/conversation.dart** - Model cho conversation
2. **models/chat_message.dart** - Model cho chat message  
3. **services/chat_service.dart** - Service quản lý Socket.IO và API
4. **presentations/chat/chat_screen.dart** - Giao diện chat
5. **constants/app_routes.dart** - Đã thêm route '/chat'

### Thay đổi
- **home_tab.dart** - Đã thêm FloatingActionButton để mở chat

## Cài đặt Backend (qlnh_backend)

### 1. Cài đặt dependencies
```bash
pip install python-socketio
pip install eventlet
```

### 2. Tạo file run_socketio.py
Tạo file `run_socketio.py` trong thư mục `qlnh_backend` với nội dung:

```python
"""
Socket.IO server cho tính năng chat
Chạy trên port 8001 song song với Django server (port 8000)
"""
import eventlet
eventlet.monkey_patch()

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'qlnh_backend.settings')
django.setup()

from restaurant.socket_handlers_wsgi import sio

if __name__ == '__main__':
    print("Starting Socket.IO server on port 8001...")
    print("URL: http://localhost:8001")
    
    # Wrap the socket.io server with eventlet WSGI
    app = sio
    
    # Listen on port 8001
    eventlet.wsgi.server(
        eventlet.listen(('0.0.0.0', 8001)),
        app,
        log_output=True
    )
```

## Cách chạy

### Terminal 1: Django REST API Server
```powershell
cd d:\repos\QuanLyNhaHang\qlnh_backend
python manage.py runserver
```
Server chạy tại: http://localhost:8000

### Terminal 2: Socket.IO Server  
```powershell
cd d:\repos\QuanLyNhaHang\qlnh_backend
python run_socketio.py
```
Server chạy tại: http://localhost:8001

## Cấu hình

### Cập nhật API endpoints (nếu cần)
File: `qlnh_app/lib/constants/api.dart`

```dart
static const String socketUrl = 'http://localhost:8001';
// hoặc URL của bạn
```

### Cấu hình CORS (trong settings.py nếu cần)
Đảm bảo CORS_ALLOWED_ORIGINS cho phép kết nối từ Flutter app.

## Cách sử dụng

1. **Đăng nhập** vào ứng dụng
2. Trên **trang chủ**, nhấn vào **nút chat** (floating button màu xanh góc dưới bên phải)
3. Gửi tin nhắn để trò chuyện với nhân viên
4. Tin nhắn sẽ được gửi real-time qua Socket.IO

## Kiến trúc

### Socket.IO Events

**Client → Server:**
- `connect` - Kết nối với auth {user_id}
- `send_message` - Gửi tin {noi_dung, customer_id?}
- `typing` - Đang gõ {is_typing, customer_id?}
- `join_conversation` - Join room {customer_id}

**Server → Client:**
- `new_message` - Tin nhắn mới
- `user_typing` - Người dùng đang gõ
- `error` - Lỗi từ server

### REST API Endpoints

- `GET /api/conversations/my_conversation/` - Lấy conversation của customer
- `GET /api/conversations/` - Lấy tất cả conversations (staff)
- `GET /api/conversations/{id}/messages/` - Lấy messages
- `POST /api/conversations/{id}/send_message/` - Gửi message qua API

## Xử lý lỗi

### Socket không kết nối được
1. Kiểm tra Socket.IO server đang chạy trên port 8001
2. Kiểm tra URL trong api.dart
3. Xem logs trong console

### Không nhận được tin nhắn
1. Kiểm tra kết nối Socket.IO (hiển thị trên AppBar)
2. Kiểm tra logs backend về rooms và emit events
3. Thử refresh lại màn hình chat

## Testing

### Test Socket.IO connection
Có thể dùng socket.io client test tool hoặc:

```javascript
const io = require('socket.io-client');
const socket = io('http://localhost:8001', {
  auth: { user_id: 1 }
});

socket.on('connect', () => {
  console.log('Connected!');
  socket.emit('send_message', { noi_dung: 'Test message' });
});

socket.on('new_message', (data) => {
  console.log('New message:', data);
});
```

## Lưu ý

1. **Port conflicts**: Đảm bảo port 8001 không bị sử dụng bởi app khác
2. **Authentication**: User phải đăng nhập trước khi sử dụng chat
3. **Database**: Conversation và ChatMessage được lưu trong database
4. **Real-time**: Socket.IO cho phép nhận tin nhắn ngay lập tức không cần refresh

## Troubleshooting

### Lỗi "eventlet not found"
```bash
pip install eventlet
```

### Lỗi "python-socketio not found"
```bash
pip install python-socketio
```

### Port 8001 đã được sử dụng
Đổi port trong:
- `run_socketio.py`: eventlet.listen(('0.0.0.0', YOUR_PORT))
- `api.dart`: static const String socketUrl = 'http://localhost:YOUR_PORT';

## Tính năng nâng cao (tùy chọn)

- [ ] Đánh dấu tin đã đọc/chưa đọc
- [ ] Push notification khi có tin mới
- [ ] Upload hình ảnh trong chat
- [ ] Typing indicator animation
- [ ] Message reactions (emoji)
- [ ] Voice messages
