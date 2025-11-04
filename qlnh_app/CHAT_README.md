# Chức năng Chat - Quick Start

## 🚀 Cài đặt nhanh

### Backend Setup
```bash
# Di chuyển đến thư mục backend
cd d:\repos\QuanLyNhaHang\qlnh_backend

# Cài đặt dependencies
pip install python-socketio eventlet

# Copy file run_socketio.py từ template
# File template: d:\repos\QuanLyNhaHang\qlnh_app\run_socketio.py.template
# Copy vào: d:\repos\QuanLyNhaHang\qlnh_backend\run_socketio.py
```

### Chạy Servers

**Terminal 1 - Django REST API:**
```powershell
cd d:\repos\QuanLyNhaHang\qlnh_backend
python manage.py runserver
```

**Terminal 2 - Socket.IO Server:**
```powershell
cd d:\repos\QuanLyNhaHang\qlnh_backend
python run_socketio.py
```

## 📱 Sử dụng

1. Mở app và đăng nhập
2. Trên trang chủ, nhấn nút **chat** (floating button màu xanh góc dưới phải)
3. Gửi tin nhắn để trò chuyện với nhân viên

## 🔧 Cấu hình

File `lib/constants/api.dart`:
```dart
static const String socketUrl = 'http://localhost:8001';
```

Nếu dùng tunnel/ngrok, thay đổi URL tương ứng.

## ✅ Hoàn thành

- ✅ Models (Conversation, ChatMessage)
- ✅ ChatService với Socket.IO
- ✅ Chat Screen UI
- ✅ FloatingActionButton trên Home
- ✅ Real-time messaging

Xem chi tiết: [CHAT_SETUP_GUIDE.md](CHAT_SETUP_GUIDE.md)
