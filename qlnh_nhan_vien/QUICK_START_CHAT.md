# 🚀 Quick Start Guide - Chức năng Chat

## 📋 Tóm tắt nhanh

Chức năng chat real-time cho phép **nhân viên** chat với **khách hàng** qua Socket.IO.

## ⚡ Bắt đầu trong 3 bước

### Bước 1: Khởi động Backend (2 terminals)

**Terminal 1 - Django API (port 8000):**
```bash
cd d:\repos\QuanLyNhaHang\qlnh_backend
python manage.py runserver
```

**Terminal 2 - Socket.IO (port 8001):**
```bash
cd d:\repos\QuanLyNhaHang\qlnh_backend
python run_socketio.py
```

### Bước 2: Setup Flutter App

```bash
cd d:\repos\QuanLyNhaHang\qlnh_nhan_vien

# Cài đặt packages (chỉ lần đầu)
flutter pub get

# Chạy app
flutter run
```

### Bước 3: Sử dụng

1. **Login** với tài khoản nhân viên
2. Click vào **nút chat (FloatingActionButton)** ở góc dưới bên phải dashboard
3. Chọn conversation để chat với khách hàng
4. Gửi tin nhắn!

## 🎨 Giao diện

### Dashboard
```
┌─────────────────────────────┐
│      Quản lý Nhà hàng      │
├─────────────────────────────┤
│                             │
│   [Nội dung dashboard]      │
│                             │
│                             │
│                        [💬] │ ← FloatingActionButton (Chat)
└─────────────────────────────┘
```

### Danh sách Conversations
```
┌─────────────────────────────┐
│  Tin nhắn khách hàng    🔄 🟢│
├─────────────────────────────┤
│ [👤] Nguyễn Văn A           │
│     Xin chào...        10:30│ [2]
├─────────────────────────────┤
│ [👤] Trần Thị B             │
│     Cảm ơn...          09:15│
└─────────────────────────────┘
```

### Chat Chi tiết
```
┌─────────────────────────────┐
│ [👤] Nguyễn Văn A           │
│     Đang hoạt động          │
├─────────────────────────────┤
│                             │
│    [Xin chào ạ!]           │ ← Tin của khách
│                             │
│        [Chào bạn!] ←        │ ← Tin của nhân viên
│                             │
├─────────────────────────────┤
│ [Nhập tin nhắn...      ] [📤]│
└─────────────────────────────┘
```

## 🔧 Cấu hình URLs

Trong `lib/constants/api.dart`:

```dart
class ApiEndpoints {
  static const String baseUrl = 'https://your-domain-8000.devtunnels.ms';
  static const String socketUrl = 'https://your-domain-8001.devtunnels.ms';
  // ...
}
```

**Lưu ý:** Thay `your-domain` bằng domain thực tế của bạn.

## ✅ Checklist Setup

### Backend:
- [ ] Django server chạy trên port 8000
- [ ] Socket.IO server chạy trên port 8001
- [ ] Database có dữ liệu users (khách hàng và nhân viên)
- [ ] Models: `Conversation`, `ChatMessage` đã migrate

### Frontend:
- [ ] Đã chạy `flutter pub get`
- [ ] Cập nhật URLs trong `api.dart`
- [ ] App chạy thành công
- [ ] Login được với tài khoản nhân viên

## 🧪 Test Connection

### Test Socket.IO từ Python:
```bash
cd d:\repos\QuanLyNhaHang\qlnh_backend
python test_socketio_client.py
```

### Test trong Flutter:
1. Mở màn hình chat
2. Kiểm tra có đèn xanh (🟢) bên phải AppBar
3. Nếu có đèn xanh → đã kết nối thành công!

## 📂 Files quan trọng

### Frontend:
- `lib/models/chat_models.dart` - Models
- `lib/services/chat_service.dart` - Socket.IO service
- `lib/screens/chat_screen.dart` - UI screens
- `lib/constants/api.dart` - API URLs

### Backend:
- `restaurant/socket_handlers_wsgi.py` - Socket.IO handlers
- `restaurant/chat_views.py` - REST API
- `run_socketio.py` - Start Socket.IO server

## 🐛 Troubleshooting

### Socket.IO không kết nối?

**Kiểm tra:**
1. ✅ Server Socket.IO đã chạy chưa? → `python run_socketio.py`
2. ✅ URL đúng chưa? → Xem `ApiEndpoints.socketUrl`
3. ✅ Port 8001 có bị chặn không?

**Log mẫu khi thành công:**
```
[ChatService] Connecting to https://...
[ChatService] Connected to Socket.IO
```

### Không nhận tin nhắn?

**Kiểm tra:**
1. ✅ User đã login chưa?
2. ✅ Có conversation với khách hàng chưa?
3. ✅ Xem backend logs

### Lỗi compile Flutter?

```bash
flutter clean
flutter pub get
flutter run
```

## 📚 Tài liệu chi tiết

- **CHAT_SETUP.md** - Hướng dẫn chi tiết setup và cấu trúc
- **CHAT_SUMMARY.md** - Tổng quan tính năng và architecture

## 💡 Tips

1. **Real-time Updates:** Tin nhắn mới hiển thị ngay không cần refresh
2. **Auto-scroll:** Tin nhắn mới tự động scroll xuống dưới
3. **Connection Status:** Đèn xanh 🟢 = đã kết nối Socket.IO
4. **Badge:** Số tin chưa đọc hiển thị ở list conversations

## 🎯 Flow hoạt động

```
1. Nhân viên login
   ↓
2. ChatService.connect(userId) được gọi
   ↓
3. Socket.IO kết nối với server (port 8001)
   ↓
4. Nhân viên click vào FloatingActionButton
   ↓
5. Mở ConversationsListScreen
   ↓
6. Load danh sách conversations từ REST API
   ↓
7. Click vào 1 conversation
   ↓
8. Mở ChatDetailScreen
   ↓
9. Load messages từ REST API
   ↓
10. Gửi/nhận tin real-time qua Socket.IO
```

## 🎉 Hoàn thành!

Bây giờ bạn đã có chức năng chat real-time hoạt động!

**Enjoy chatting! 💬🚀**

---

*Nếu có vấn đề, xem `CHAT_SETUP.md` để biết thêm chi tiết.*
