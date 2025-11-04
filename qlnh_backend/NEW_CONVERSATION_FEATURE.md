# 🆕 Tính năng: Real-time Conversation List cho Staff

## Cập nhật mới

### Event mới: `new_conversation`

Khi có khách hàng mới nhắn tin lần đầu (tạo conversation mới), tất cả nhân viên sẽ nhận event này để cập nhật danh sách chat real-time.

## Event Details

### Server → Client: `new_conversation`

**Khi nào trigger:**
- Khách hàng gửi tin nhắn đầu tiên
- Tạo conversation mới trong database

**Ai nhận:**
- Tất cả staff đang online (room `staff_room`)

**Payload:**
```javascript
{
    "id": 5,                           // Conversation ID
    "customer_id": 123,                // ID khách hàng
    "customer_name": "Nguyễn Văn A",   // Tên khách hàng
    "customer_phone": "0901234567",    // SĐT khách hàng
    "created_at": "2025-11-03T10:30:00Z",
    "last_message": {
        "noi_dung": "Xin chào, tôi muốn đặt bàn",
        "thoi_gian": "2025-11-03T10:30:00Z"
    }
}
```

## Cách sử dụng (Client-side)

### JavaScript/React Example

```javascript
socket.on('new_conversation', (data) => {
    console.log('🆕 Khách hàng mới:', data.customer_name);
    
    // 1. Thêm conversation vào đầu danh sách
    setConversations(prev => [data, ...prev]);
    
    // 2. Hiển thị notification
    showNotification(`Khách hàng mới: ${data.customer_name}`);
    
    // 3. Play sound (optional)
    playNotificationSound();
    
    // 4. Update badge count
    updateUnreadCount();
});
```

### Vue.js Example

```javascript
socket.on('new_conversation', (data) => {
    // Thêm vào reactive array
    this.conversations.unshift(data);
    
    // Show toast notification
    this.$toast.info(`💬 ${data.customer_name} vừa nhắn tin`);
});
```

### React Native Example

```javascript
socket.on('new_conversation', async (data) => {
    // Update state
    dispatch(addNewConversation(data));
    
    // Show local notification
    await Notifications.scheduleNotificationAsync({
        content: {
            title: '💬 Khách hàng mới',
            body: `${data.customer_name}: ${data.last_message.noi_dung}`,
        },
        trigger: null,
    });
});
```

## Testing

### Test với HTML Demo

1. **Mở Staff Dashboard:**
```bash
start test_staff_dashboard.html
```
- Nhập Staff ID (ví dụ: 2)
- Đăng nhập

2. **Mở Customer Chat (tab khác):**
```bash
start test_chat.html
```
- Nhập Customer ID (ví dụ: 1)
- Đăng nhập
- Gửi tin nhắn

3. **Kết quả:**
- Staff dashboard sẽ thấy conversation mới xuất hiện ngay lập tức
- Có badge "MỚI" và highlight vàng
- Có notification popup (nếu cho phép)

### Test với Postman

**Terminal 1 - Staff:**
```
ws://localhost:8001/socket.io/?EIO=4&transport=websocket&auth=%7B%22user_id%22%3A2%7D
```
Listen for: `42["new_conversation",{...}]`

**Terminal 2 - Customer:**
```
ws://localhost:8001/socket.io/?EIO=4&transport=websocket&auth=%7B%22user_id%22%3A1%7D
```
Send: `42["send_message",{"noi_dung":"Hello"}]`

→ Terminal 1 sẽ nhận được event `new_conversation`

## Flow Diagram

```
Customer (ID: 1) gửi tin lần đầu
    ↓
Server: Tạo Conversation mới (ID: 5)
    ↓
Server: Lưu ChatMessage
    ↓
Server: Kiểm tra conversation.messages.count() == 1
    ↓ (Nếu true = tin đầu tiên)
Server: Emit 2 events:
    ├─ 'new_message' → staff_room + customer_1
    └─ 'new_conversation' → staff_room
         ↓
All Staff online nhận event
    ↓
Staff UI: Update conversation list
    ├─ Thêm conversation vào đầu list
    ├─ Hiển thị badge "MỚI"
    ├─ Highlight màu vàng
    └─ Show notification
```

## Backend Changes

### Files đã cập nhật:

1. **`restaurant/socket_handlers_wsgi.py`** (WSGI/eventlet)
   - Thêm logic kiểm tra `is_new_conversation`
   - Emit event `new_conversation` khi count == 1

2. **`restaurant/socket_handlers.py`** (ASGI/async)
   - Tương tự, version async với `sync_to_async`

### Code snippet quan trọng:

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

## UI/UX Best Practices

### 1. Visual Feedback
```javascript
// Thêm badge "MỚI"
<span class="badge">MỚI</span>

// Highlight màu
.conversation-item.new {
    background: #fef3c7;
    animation: highlight 1s ease;
}
```

### 2. Sound Notification
```javascript
const audio = new Audio('/sounds/notification.mp3');
audio.play();
```

### 3. Browser Notification
```javascript
if (Notification.permission === 'granted') {
    new Notification('Restaurant Chat', {
        body: `${data.customer_name} vừa nhắn tin`,
        icon: '/logo.png'
    });
}
```

### 4. Badge Count
```javascript
// Update số conversation chưa đọc
const unreadCount = conversations.filter(c => c.unread > 0).length;
document.title = `(${unreadCount}) Staff Dashboard`;
```

## Integration với Frontend

### React + Redux

```javascript
// actions/chatActions.js
export const handleNewConversation = (data) => ({
    type: 'ADD_NEW_CONVERSATION',
    payload: data
});

// reducers/chatReducer.js
case 'ADD_NEW_CONVERSATION':
    return {
        ...state,
        conversations: [action.payload, ...state.conversations],
        unreadCount: state.unreadCount + 1
    };

// components/ChatList.jsx
useEffect(() => {
    socket.on('new_conversation', (data) => {
        dispatch(handleNewConversation(data));
    });
    
    return () => {
        socket.off('new_conversation');
    };
}, []);
```

### Vue + Vuex

```javascript
// store/modules/chat.js
mutations: {
    ADD_NEW_CONVERSATION(state, conversation) {
        state.conversations.unshift(conversation);
    }
},
actions: {
    initSocket({ commit }) {
        socket.on('new_conversation', (data) => {
            commit('ADD_NEW_CONVERSATION', data);
        });
    }
}
```

## Production Considerations

### 1. Rate Limiting
Giới hạn số conversation mới mỗi khách hàng có thể tạo:
```python
# Trong socket_handlers.py
recent_convs = Conversation.objects.filter(
    customer=sender,
    created_at__gte=timezone.now() - timedelta(minutes=5)
).count()

if recent_convs > 3:
    sio.emit('error', {'message': 'Vui lòng chờ trước khi tạo conversation mới'})
    return
```

### 2. Offline Staff
Khi staff offline, lưu notification để họ thấy khi quay lại:
```python
# models.py
class StaffNotification(models.Model):
    staff = models.ForeignKey(NguoiDung, on_delete=models.CASCADE)
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
```

### 3. Scalability
Với nhiều staff, sử dụng Redis Pub/Sub:
```python
import socketio
mgr = socketio.AsyncRedisManager('redis://localhost:6379')
sio = socketio.AsyncServer(client_manager=mgr)
```

## Troubleshooting

### Event không nhận được
✅ Check: Staff đã join `staff_room` chưa
✅ Check: Console log có in "[NEW CONVERSATION]" không
✅ Check: user.loai_nguoi_dung == 'nhan_vien'

### Conversation duplicate
✅ Check: Logic `is_new_conversation` (count == 1)
✅ Check: Không gọi `get_or_create` nhiều lần

### Performance issue
✅ Optimize: Chỉ emit khi thực sự là conversation mới
✅ Optimize: Cache conversation list trong Redis
✅ Optimize: Pagination cho conversation list

---

**Files mới:**
- `test_staff_dashboard.html` - Demo UI cho staff

**Files cập nhật:**
- `restaurant/socket_handlers_wsgi.py`
- `restaurant/socket_handlers.py`

**Test:**
```bash
# Terminal 1
python run_socketio.py

# Browser 1 - Staff
start test_staff_dashboard.html

# Browser 2 - Customer
start test_chat.html
```
