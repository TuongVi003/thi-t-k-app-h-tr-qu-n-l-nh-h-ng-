# 📡 Chat API Documentation

## Base URL
```
http://localhost:8000/api/
```

## Authentication
Tất cả endpoints yêu cầu authentication token trong header:
```
Authorization: Bearer {token}
```

---

## 📋 Endpoints Overview

| Method | Endpoint | Khách hàng | Nhân viên | Mô tả |
|--------|----------|------------|-----------|-------|
| GET | `/api/conversations/` | ✅ 1 conversation | ✅ Tất cả conversations | Danh sách conversations |
| GET | `/api/conversations/{id}/` | ✅ Chỉ của mình | ✅ Bất kỳ | Chi tiết conversation |
| GET | `/api/conversations/my_conversation/` | ✅ | ❌ | Lấy conversation của customer |
| GET | `/api/conversations/{id}/messages/` | ✅ | ✅ | Lấy tin nhắn trong conversation |
| POST | `/api/conversations/{id}/send_message/` | ✅ | ✅ | Gửi tin nhắn (HTTP fallback) |
| GET | `/api/messages/` | ✅ Chỉ của mình | ✅ Tất cả | Danh sách messages |

---

## 1️⃣ GET `/conversations/` - Lấy danh sách conversations

### Khách hàng (Customer)
Trả về **1 conversation duy nhất** của khách hàng với staff group.

**Request:**
```http
GET /api/conversations/
Authorization: Bearer {customer_token}
```

**Response:**
```json
[
    {
        "id": 5,
        "customer": 123,
        "customer_info": {
            "id": 123,
            "username": "customer1",
            "ho_ten": "Nguyễn Văn A",
            "loai_nguoi_dung": "khach_hang",
            "chuc_vu": "customer"
        },
        "is_staff_group": true,
        "created_at": "2025-11-03T10:30:00Z",
        "last_message_at": "2025-11-03T11:45:00Z",
        "last_message": {
            "id": 25,
            "noi_dung": "Cảm ơn nhà hàng",
            "thoi_gian": "2025-11-03T11:45:00Z",
            "nguoi_goi_name": "Nguyễn Văn A"
        },
        "unread_count": 0
    }
]
```

### Nhân viên (Staff)
Trả về **TẤT CẢ conversations** của tất cả khách hàng.

**Request:**
```http
GET /api/conversations/
Authorization: Bearer {staff_token}
```

**Response:**
```json
[
    {
        "id": 5,
        "customer": 123,
        "customer_info": {
            "id": 123,
            "username": "customer1",
            "ho_ten": "Nguyễn Văn A",
            "loai_nguoi_dung": "khach_hang",
            "chuc_vu": "customer"
        },
        "is_staff_group": true,
        "created_at": "2025-11-03T10:30:00Z",
        "last_message_at": "2025-11-03T11:45:00Z",
        "last_message": {
            "id": 25,
            "noi_dung": "Cảm ơn nhà hàng",
            "thoi_gian": "2025-11-03T11:45:00Z",
            "nguoi_goi_name": "Nguyễn Văn A"
        },
        "unread_count": 0
    },
    {
        "id": 6,
        "customer": 124,
        "customer_info": {
            "id": 124,
            "username": "customer2",
            "ho_ten": "Trần Thị B",
            "loai_nguoi_dung": "khach_hang",
            "chuc_vu": "customer"
        },
        "is_staff_group": true,
        "created_at": "2025-11-03T09:00:00Z",
        "last_message_at": "2025-11-03T10:20:00Z",
        "last_message": {
            "id": 18,
            "noi_dung": "Tôi muốn đặt bàn",
            "thoi_gian": "2025-11-03T10:20:00Z",
            "nguoi_goi_name": "Trần Thị B"
        },
        "unread_count": 0
    }
]
```

**Notes:**
- Sắp xếp theo `last_message_at` giảm dần (mới nhất lên đầu)
- Tất cả staff đều thấy chung tất cả conversations
- Không phân chia conversation theo staff cụ thể

---

## 2️⃣ GET `/conversations/{id}/` - Lấy chi tiết conversation

### Request:
```http
GET /api/conversations/5/
Authorization: Bearer {token}
```

### Response:
```json
{
    "id": 5,
    "customer": 123,
    "customer_info": {
        "id": 123,
        "username": "customer1",
        "ho_ten": "Nguyễn Văn A",
        "loai_nguoi_dung": "khach_hang",
        "chuc_vu": "customer"
    },
    "is_staff_group": true,
    "created_at": "2025-11-03T10:30:00Z",
    "last_message_at": "2025-11-03T11:45:00Z",
    "last_message": {
        "id": 25,
        "noi_dung": "Cảm ơn nhà hàng",
        "thoi_gian": "2025-11-03T11:45:00Z",
        "nguoi_goi_name": "Nguyễn Văn A"
    },
    "unread_count": 0,
    "messages": [
        {
            "id": 20,
            "conversation": 5,
            "nguoi_goi": 123,
            "nguoi_goi_name": "Nguyễn Văn A",
            "nguoi_goi_display": "Nguyễn Văn A",
            "nguoi_goi_info": {
                "id": 123,
                "username": "customer1",
                "ho_ten": "Nguyễn Văn A",
                "loai_nguoi_dung": "khach_hang",
                "chuc_vu": "customer"
            },
            "noi_dung": "Xin chào, tôi muốn đặt bàn",
            "thoi_gian": "2025-11-03T10:30:00Z"
        },
        {
            "id": 21,
            "conversation": 5,
            "nguoi_goi": 2,
            "nguoi_goi_name": "Lê Văn C",
            "nguoi_goi_display": "Nhân viên",
            "nguoi_goi_info": {
                "id": 2,
                "username": "staff1",
                "ho_ten": "Lê Văn C",
                "loai_nguoi_dung": "nhan_vien",
                "chuc_vu": "waiter"
            },
            "noi_dung": "Dạ, chúng tôi sẽ hỗ trợ anh ngay",
            "thoi_gian": "2025-11-03T10:35:00Z"
        }
    ]
}
```

**Authorization:**
- ✅ Customer: Chỉ truy cập conversation của chính mình
- ✅ Staff: Truy cập bất kỳ conversation nào

---

## 3️⃣ GET `/conversations/my_conversation/` - Customer lấy conversation của mình

**Chỉ dành cho khách hàng.** Tự động lấy hoặc tạo conversation duy nhất.

### Request:
```http
GET /api/conversations/my_conversation/
Authorization: Bearer {customer_token}
```

### Response:
```json
{
    "id": 5,
    "customer": 123,
    "customer_info": {
        "id": 123,
        "username": "customer1",
        "ho_ten": "Nguyễn Văn A",
        "loai_nguoi_dung": "khach_hang",
        "chuc_vu": "customer"
    },
    "is_staff_group": true,
    "created_at": "2025-11-03T10:30:00Z",
    "last_message_at": "2025-11-03T11:45:00Z",
    "last_message": {...},
    "unread_count": 0,
    "messages": [...]
}
```

**Use case:**
- App khách hàng mở chat lần đầu → gọi endpoint này
- Nếu chưa có conversation → tự động tạo
- Nếu đã có → trả về conversation hiện tại

---

## 4️⃣ GET `/conversations/{id}/messages/` - Lấy tin nhắn trong conversation

Lấy danh sách messages với pagination.

### Request:
```http
GET /api/conversations/5/messages/?limit=50&offset=0
Authorization: Bearer {token}
```

**Query Parameters:**
- `limit`: Số message lấy (default: 50)
- `offset`: Offset cho pagination (default: 0)

### Response:
```json
[
    {
        "id": 20,
        "conversation": 5,
        "nguoi_goi": 123,
        "nguoi_goi_name": "Nguyễn Văn A",
        "nguoi_goi_display": "Nguyễn Văn A",
        "nguoi_goi_info": {
            "id": 123,
            "username": "customer1",
            "ho_ten": "Nguyễn Văn A",
            "loai_nguoi_dung": "khach_hang",
            "chuc_vu": "customer"
        },
        "noi_dung": "Xin chào",
        "thoi_gian": "2025-11-03T10:30:00Z"
    },
    {
        "id": 21,
        "conversation": 5,
        "nguoi_goi": 2,
        "nguoi_goi_name": "Lê Văn C",
        "nguoi_goi_display": "Nhân viên",
        "nguoi_goi_info": {
            "id": 2,
            "username": "staff1",
            "ho_ten": "Lê Văn C",
            "loai_nguoi_dung": "nhan_vien",
            "chuc_vu": "waiter"
        },
        "noi_dung": "Dạ, chúng tôi hỗ trợ ngay",
        "thoi_gian": "2025-11-03T10:35:00Z"
    }
]
```

**Notes:**
- Messages được sắp xếp theo thời gian tăng dần (cũ → mới)
- `nguoi_goi_display`: Hiển thị "Nhân viên" nếu là staff trong staff_group
- Pagination: Dùng `offset` để load thêm tin cũ hơn

---

## 5️⃣ POST `/conversations/{id}/send_message/` - Gửi tin nhắn (HTTP)

**Fallback method** khi không dùng Socket.IO.

### Request:
```http
POST /api/conversations/5/send_message/
Authorization: Bearer {token}
Content-Type: application/json

{
    "noi_dung": "Xin chào, tôi cần hỗ trợ"
}
```

### Response (Success):
```json
{
    "id": 26,
    "conversation": 5,
    "nguoi_goi": 123,
    "nguoi_goi_name": "Nguyễn Văn A",
    "nguoi_goi_display": "Nguyễn Văn A",
    "nguoi_goi_info": {
        "id": 123,
        "username": "customer1",
        "ho_ten": "Nguyễn Văn A",
        "loai_nguoi_dung": "khach_hang",
        "chuc_vu": "customer"
    },
    "noi_dung": "Xin chào, tôi cần hỗ trợ",
    "thoi_gian": "2025-11-03T12:00:00Z"
}
```

### Response (Error):
```json
{
    "error": "Nội dung tin nhắn không được để trống"
}
```

**Authorization:**
- ✅ Customer: Chỉ gửi trong conversation của mình
- ✅ Staff: Gửi trong bất kỳ conversation nào

**Note:** Nên dùng Socket.IO để gửi tin real-time thay vì endpoint này.

---

## 6️⃣ GET `/messages/` - Lấy danh sách messages

### Khách hàng:
```http
GET /api/messages/
Authorization: Bearer {customer_token}
```
→ Trả về messages trong conversation của khách hàng đó

### Nhân viên:
```http
GET /api/messages/
Authorization: Bearer {staff_token}
```
→ Trả về TẤT CẢ messages của tất cả conversations

**Response format:** Giống như `/conversations/{id}/messages/`

---

## 🔐 Authorization Matrix

| Endpoint | Khách hàng | Nhân viên | Notes |
|----------|------------|-----------|-------|
| `GET /conversations/` | ✅ 1 conv | ✅ All convs | Staff thấy tất cả |
| `GET /conversations/{id}/` | ✅ Chỉ của mình | ✅ Bất kỳ | 403 nếu customer truy cập conv khác |
| `GET /conversations/my_conversation/` | ✅ | ❌ 403 | Chỉ dành cho customer |
| `GET /conversations/{id}/messages/` | ✅ Chỉ của mình | ✅ Bất kỳ | |
| `POST /conversations/{id}/send_message/` | ✅ Chỉ của mình | ✅ Bất kỳ | |
| `GET /messages/` | ✅ Chỉ của mình | ✅ Tất cả | |

---

## 📱 Integration Examples

### React/Vue - Customer App

```javascript
// 1. Lấy conversation của customer khi mở chat
const getMyConversation = async () => {
    const response = await fetch('/api/conversations/my_conversation/', {
        headers: {
            'Authorization': `Bearer ${token}`
        }
    });
    const conversation = await response.json();
    return conversation;
};

// 2. Load messages
const loadMessages = async (conversationId, offset = 0) => {
    const response = await fetch(
        `/api/conversations/${conversationId}/messages/?limit=50&offset=${offset}`,
        {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        }
    );
    const messages = await response.json();
    return messages;
};

// 3. Gửi tin (HTTP fallback)
const sendMessage = async (conversationId, content) => {
    const response = await fetch(
        `/api/conversations/${conversationId}/send_message/`,
        {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ noi_dung: content })
        }
    );
    const message = await response.json();
    return message;
};
```

### React/Vue - Staff App

```javascript
// 1. Lấy tất cả conversations
const getAllConversations = async () => {
    const response = await fetch('/api/conversations/', {
        headers: {
            'Authorization': `Bearer ${token}`
        }
    });
    const conversations = await response.json();
    return conversations;
};

// 2. Xem chi tiết conversation của customer cụ thể
const getConversationDetail = async (conversationId) => {
    const response = await fetch(`/api/conversations/${conversationId}/`, {
        headers: {
            'Authorization': `Bearer ${token}`
        }
    });
    const conversation = await response.json();
    return conversation;
};

// 3. Gửi tin cho customer
const replyToCustomer = async (conversationId, content) => {
    const response = await fetch(
        `/api/conversations/${conversationId}/send_message/`,
        {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ noi_dung: content })
        }
    );
    return await response.json();
};
```

---

## 🔄 Real-time với Socket.IO

**Khuyến nghị:** Dùng Socket.IO để gửi/nhận tin real-time thay vì HTTP API.

**HTTP API chỉ dùng cho:**
- Load lịch sử chat khi mở app
- Load thêm tin cũ (scroll up)
- Fallback khi WebSocket fail

**Socket.IO dùng cho:**
- Gửi tin nhắn mới
- Nhận tin real-time
- Typing indicator
- Online status

---

## 🧪 Testing với cURL

### Customer - Lấy conversation
```bash
curl -X GET http://localhost:8000/api/conversations/my_conversation/ \
  -H "Authorization: Bearer {customer_token}"
```

### Staff - Lấy tất cả conversations
```bash
curl -X GET http://localhost:8000/api/conversations/ \
  -H "Authorization: Bearer {staff_token}"
```

### Gửi tin nhắn
```bash
curl -X POST http://localhost:8000/api/conversations/5/send_message/ \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"noi_dung":"Hello from cURL"}'
```

---

## ⚠️ Important Notes

### 1. Mỗi khách hàng chỉ có 1 conversation
- ✅ Auto-create khi customer nhắn tin lần đầu
- ✅ Sử dụng `Conversation.get_or_create_for_customer(user)`
- ❌ KHÔNG tạo nhiều conversation cho 1 customer

### 2. Tất cả nhân viên chung 1 luồng
- ✅ Tất cả staff thấy tất cả conversations
- ✅ Bất kỳ staff nào cũng có thể trả lời
- ✅ `is_staff_group=True` cho tất cả conversations
- ❌ KHÔNG phân chia conversation cho staff riêng lẻ

### 3. Hiển thị tên nhân viên
- Trong conversation detail: `nguoi_goi_display` = "Nhân viên" (chung)
- Trong logs/admin: Vẫn lưu tên staff cụ thể
- Customer chỉ thấy "Nhân viên", không biết staff nào trả lời

### 4. Performance
- Dùng `select_related('customer')` khi query
- Dùng `prefetch_related('messages')` nếu cần
- Pagination cho messages (50 messages/lần)
- Index trên `last_message_at` cho sorting nhanh

---

## 📞 Support

Nếu gặp vấn đề:
1. Check authentication token
2. Check `loai_nguoi_dung` của user
3. Check permissions (403 errors)
4. Check server logs

**Endpoints summary:**
- Base: `http://localhost:8000/api/`
- Conversations: `/conversations/`
- Messages: `/messages/`
- Socket.IO: `ws://localhost:8001/socket.io/`
