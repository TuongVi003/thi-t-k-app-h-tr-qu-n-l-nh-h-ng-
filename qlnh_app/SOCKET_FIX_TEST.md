# 🧪 Socket.IO User ID Fix - Testing Guide

## ✅ Fix đã áp dụng

### 1. ChatService.dart
- ✅ `.disableAutoConnect()` - Ngăn socket tự động kết nối
- ✅ `.disableReconnection()` - Ngăn socket tự động reconnect
- ✅ `unique_id` trong auth payload
- ✅ `_forceCleanup()` với delay 1.2s
- ✅ `connect()` ALWAYS cleanup trước khi tạo socket mới

### 2. ChatScreen.dart
- ✅ `_ensureCleanConnection()` với delay 200ms
- ✅ Cleanup trước khi initialize

### 3. AuthService.dart
- ✅ `loginWithApi()` await disconnect trước login
- ✅ `logout()` await disconnect

### 4. UI Screens
- ✅ home_screen.dart - await logout
- ✅ profile_page.dart - await logout

---

## 📋 Test Procedure

### Test Case 1: Login → Chat → Logout → Login mới → Chat

#### Bước 1: Clean Start
```bash
# Kill app hoàn toàn
adb shell am force-stop com.example.qlnh_app

# Xóa cache (optional)
adb shell pm clear com.example.qlnh_app

# Run lại
fvm flutter run
```

#### Bước 2: Login User 9
```
1. Mở app
2. Login với user 9
3. Check logs:
   [AuthService] 🔐 Login attempt for: user9
   [AuthService] 🧹 Cleaning up old socket connection...
   [ChatService] 🧹 FORCE CLEANUP (user: null, socket: null)...
   [ChatService] ✅ Force cleanup complete
   [AuthService] ✅ Old connection cleaned
   [AuthService] ✅ Login successful
```

#### Bước 3: Vào ChatScreen (User 9)
```
1. Nhấn vào "Chat hỗ trợ"
2. Check logs:
   [ChatScreen] 🧹 Ensuring clean connection state...
   [ChatService] 🧹 FORCE CLEANUP (user: null)...
   [ChatService] ⏳ Waiting 1.2s for backend cleanup...
   [ChatService] ✅ Force cleanup complete
   [ChatScreen] ✅ Clean state ensured, now initializing...
   [ChatScreen] 🔍 Fetching current user...
   [ChatScreen] ✅ Current user fetched:
   [ChatScreen]    ID: 9
   [ChatService] 📞 connect() called with userId: 9
   [ChatService] 🆕 Creating BRAND NEW socket for user_id: 9
   [ChatService] 🔑 unique_id: 9-1731148123456-123456
   [ChatService] 🚀 Socket connection initiated
   [ChatService] ✅ CONNECTED! User ID: 9, Socket ID: abc123
```

#### Bước 4: Gửi tin nhắn (User 9)
```
1. Gửi tin nhắn: "Test message from user 9"
2. Check logs:
   [ChatScreen] 📤 Preparing to send message...
   [ChatScreen]    Current user: 9 (User Nine)
   [ChatScreen]    Expected nguoi_goi_id: 9
   [ChatService] 📤 SENDING MESSAGE:
   [ChatService]    From user_id: 9
   [ChatService]    Socket ID: abc123

3. Check backend logs:
   [DEBUG] send_message - SID: abc123, user_id from connected_users: 9
   [DEBUG] Sender: 9 - User Nine (khach_hang)
   [DEBUG] Created message 123: nguoi_goi_id=9 ✓

4. Check database:
   SELECT id, noi_dung, nguoi_goi_id FROM chat_message ORDER BY id DESC LIMIT 1;
   Expected: nguoi_goi_id = 9 ✓
```

#### Bước 5: Logout
```
1. Nhấn Profile → Đăng xuất
2. Check logs:
   [AuthService] 🚪 Logging out...
   [AuthService] 🧹 Disconnecting socket...
   [ChatService] 🧹 FORCE CLEANUP (user: 9, socket: abc123)...
   [ChatService] ⏳ Waiting 1.2s for backend cleanup...
   [ChatService] ✅ Force cleanup complete (was user: 9)
   [AuthService] ✅ Socket disconnected
   [AuthService] 🗑️ Session cleared
   [AuthService] ✅ Logout complete

3. Check backend logs:
   [DISCONNECT] ==================== DISCONNECT ====================
   [DISCONNECT] Client abc123 (user 9) disconnected
   [DISCONNECT] Removing from connected_users
```

#### Bước 6: **QUAN TRỌNG - Đợi 2 giây!**
```
⏳ Đợi ít nhất 2 giây để backend cleanup hoàn toàn
```

#### Bước 7: Login User 11
```
1. Login với user 11
2. Check logs:
   [AuthService] 🔐 Login attempt for: user11
   [AuthService] 🧹 Cleaning up old socket connection...
   [ChatService] 🧹 FORCE CLEANUP (user: null, socket: null)...
   [ChatService] ⏳ Waiting 1.2s for backend cleanup...
   [ChatService] ✅ Force cleanup complete
   [AuthService] ✅ Old connection cleaned, proceeding with login...
   [AuthService] ✅ Login successful, access token: eyJ0eXB...
```

#### Bước 8: Vào ChatScreen (User 11) - **TEST CRITICAL**
```
1. Nhấn vào "Chat hỗ trợ"
2. Check logs - CỰC KỲ QUAN TRỌNG:
   [ChatScreen] 🧹 Ensuring clean connection state...
   [ChatService] 🧹 FORCE CLEANUP (user: null, socket: null)...
   [ChatService] ⏳ Waiting 1.2s for backend cleanup...
   [ChatService] ✅ Force cleanup complete
   [ChatScreen] ✅ Clean state ensured, now initializing...
   [ChatScreen] 🔍 Fetching current user...
   [ChatScreen] ✅ Current user fetched:
   [ChatScreen]    ID: 11  ⭐ MUST BE 11, NOT 9
   [ChatService] 📞 connect() called with userId: 11
   [ChatService] 🆕 Creating BRAND NEW socket for user_id: 11
   [ChatService] 🔑 unique_id: 11-1731148523789-789012  ⭐ DIFFERENT from user 9
   [ChatService] 🚀 Socket connection initiated
   [ChatService] ✅ CONNECTED! User ID: 11, Socket ID: xyz789  ⭐ NEW socket ID

3. Check backend logs:
   [CONNECT] ==================== NEW CONNECTION ====================
   [CONNECT] Socket ID: xyz789  ⭐ DIFFERENT from abc123
   [CONNECT] Auth received: {'user_id': 11, 'timestamp': 1731148523789, 'unique_id': '11-1731148523789-789012'}
   [CONNECT] Auth age: 0.5s (fresh)
   [CONNECT] ✅ User ... (11) connected as xyz789  ⭐ MUST BE 11
   [CONNECT] 📝 Mapped: connected_users['xyz789'] = 11  ⭐ CRITICAL
```

#### Bước 9: Gửi tin nhắn (User 11) - **MOMENT OF TRUTH** 🎯
```
1. Gửi tin nhắn: "Test message from user 11"
2. Check logs:
   [ChatScreen] 📤 Preparing to send message...
   [ChatScreen]    Current user: 11 (User Eleven)  ⭐ MUST BE 11
   [ChatScreen]    Expected nguoi_goi_id: 11  ⭐ CRITICAL
   [ChatService] 📤 SENDING MESSAGE:
   [ChatService]    From user_id: 11  ⭐ MUST BE 11
   [ChatService]    Socket ID: xyz789

3. Check backend logs - **ĐÂY LÀ KIỂM TRA CUỐI CÙNG**:
   [DEBUG] send_message - SID: xyz789, user_id from connected_users: 11  ✅ MUST BE 11, NOT 9
   [DEBUG] Sender: 11 - User Eleven (khach_hang)  ✅ CORRECT
   [DEBUG] Created message 124: nguoi_goi_id=11  ✅ ✅ ✅ SUCCESS!

4. Check database - **FINAL VERIFICATION**:
   SELECT id, noi_dung, nguoi_goi_id FROM chat_message ORDER BY id DESC LIMIT 1;
   
   Expected result:
   | id  | noi_dung                   | nguoi_goi_id |
   |-----|----------------------------|--------------|
   | 124 | Test message from user 11  | 11           | ✅ ✅ ✅
   
   ❌ FAIL if nguoi_goi_id = 9
   ✅ PASS if nguoi_goi_id = 11
```

---

## 🔍 Debugging - Nếu vẫn lỗi

### Scenario A: Backend nhận user_id = 9 thay vì 11

**Logs sẽ như thế này:**
```
[DEBUG] send_message - SID: xyz789, user_id from connected_users: 9  ❌ WRONG
```

**Nguyên nhân:** Engine.IO vẫn đang cache session

**Giải pháp:**
1. Verify Flutter có `.disableAutoConnect()` VÀ `.disableReconnection()`
2. Check xem có log "FORCE CLEANUP" TRƯỚC connect không
3. Kill app hoàn toàn và clear cache:
   ```bash
   adb shell am force-stop com.example.qlnh_app
   adb shell pm clear com.example.qlnh_app
   fvm flutter run
   ```

### Scenario B: Backend log "STALE SESSION DETECTED"

**Logs sẽ như thế này:**
```
[CONNECT] ⚠️ STALE SESSION DETECTED
[CONNECT] Expected: {..., 'user_id': 11}
[CONNECT] Got: {..., 'user_id': 9}
```

**Nguyên nhân:** Flutter reconnect quá nhanh, backend chưa cleanup xong

**Giải pháp:**
1. Tăng delay trong `_forceCleanup()` lên 1.5s hoặc 2s
2. Tăng delay trong `_ensureCleanConnection()` lên 300ms

### Scenario C: Socket không kết nối được

**Logs sẽ như thế này:**
```
[ChatService] ❌ Error connecting: ...
```

**Giải pháp:**
1. Check backend có đang chạy không
2. Check URL: `ws://192.168.1.x:8000`
3. Check firewall/network

---

## ✅ Success Criteria

### Phải PASS tất cả các điều kiện sau:

1. ✅ Flutter log: `Creating BRAND NEW socket for user_id: 11`
2. ✅ Flutter log: `unique_id: 11-...` (khác với user 9)
3. ✅ Backend log: `Auth received: {'user_id': 11, ...}`
4. ✅ Backend log: `connected_users['xyz789'] = 11` (không phải 9)
5. ✅ Backend log: `send_message - SID: xyz789, user_id from connected_users: 11`
6. ✅ Backend log: `Created message ...: nguoi_goi_id=11`
7. ✅ Database: `nguoi_goi_id = 11` (không phải 9)

### Nếu TẤT CẢ đều PASS → Fix thành công! 🎉

---

## 🎯 Key Takeaways

**Vấn đề gốc:**
- Engine.IO cache auth payload trong session
- Socket.IO client tự động reconnect với auth cũ
- Backend không thể phân biệt connection mới vs cũ

**Giải pháp:**
1. **Frontend:** `.disableAutoConnect()` + `.disableReconnection()` + `unique_id`
2. **Frontend:** Force cleanup (1.2s delay) trước EVERY connection
3. **Frontend:** Await logout/disconnect ở mọi nơi
4. **Backend:** Validate timestamp + expected_auth tracking (đã fix)

**Critical Points:**
- ⭐ **NEVER** auto-reconnect
- ⭐ **ALWAYS** cleanup before connect
- ⭐ **ALWAYS** wait for cleanup to complete
- ⭐ **UNIQUE** identifier for each connection
