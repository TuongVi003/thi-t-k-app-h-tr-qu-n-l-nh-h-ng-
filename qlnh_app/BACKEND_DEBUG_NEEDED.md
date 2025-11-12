# 🚨 Backend Debug Required

## ❌ Problem Identified

**Flutter sends CORRECT data:**
- Current user: 6 (hieu)
- Socket ID: kVZzWi0lO239ObF3AAAR
- Expected nguoi_goi_id: 6

**Backend returns WRONG data:**
- nguoi_goi_id: 11 (user3 - old user)
- nguoi_goi_name: user3

**Conclusion: BACKEND IS NOT UPDATING `connected_users` dict correctly!**

---

## 🔍 What to Check in Backend

### 1. Check `connect` event handler in `socket_handlers.py`

```python
@sio.on('connect')
async def connect(sid, environ, auth):
    print(f'[CONNECT] ==================== NEW CONNECTION ====================')
    print(f'[CONNECT] Socket ID: {sid}')
    print(f'[CONNECT] Auth received: {auth}')
    
    # ⭐ CRITICAL: Get user_id from auth payload
    user_id = auth.get('user_id')
    
    if not user_id:
        print(f'[CONNECT] ❌ No user_id in auth payload!')
        return False
    
    # ⭐ CRITICAL: Save to connected_users dict
    connected_users[sid] = user_id
    print(f'[CONNECT] 📝 Mapped: connected_users[\'{sid}\'] = {user_id}')
    
    # Verify the mapping
    print(f'[CONNECT] ✅ User ... ({user_id}) connected as {sid}')
```

**Expected output when user1 (id=6) connects:**
```
[CONNECT] ==================== NEW CONNECTION ====================
[CONNECT] Socket ID: kVZzWi0lO239ObF3AAAR
[CONNECT] Auth received: {'user_id': 6, 'token': '...', 'timestamp': 1731223555000, 'unique_id': '6-1731223555000-123456'}
[CONNECT] 📝 Mapped: connected_users['kVZzWi0lO239ObF3AAAR'] = 6
[CONNECT] ✅ User ... (6) connected as kVZzWi0lO239ObF3AAAR
```

**❌ If you see:**
```
[CONNECT] Auth received: {'user_id': 11, ...}  # WRONG - still user3
```
→ **Flutter auth payload is being cached** (but logs show it's correct, so unlikely)

**❌ If you DON'T see any CONNECT logs:**
→ **Backend is not receiving connect event** (Socket.IO routing issue)

---

### 2. Check `send_message` handler

```python
@sio.on('send_message')
async def send_message(sid, data):
    print(f'[DEBUG] ==================== SEND MESSAGE ====================')
    print(f'[DEBUG] send_message - SID: {sid}')
    print(f'[DEBUG] send_message - Data: {data}')
    
    # ⭐ CRITICAL: Get user_id from connected_users dict
    user_id = connected_users.get(sid)
    print(f'[DEBUG] Looking up user_id in connected_users...')
    print(f'[DEBUG] connected_users[\'{sid}\'] = {user_id}')
    
    if not user_id:
        print(f'[DEBUG] ❌ User not found in connected_users!')
        return
    
    # Get user from database
    user = await sync_to_async(User.objects.get)(id=user_id)
    print(f'[DEBUG] Sender: {user.id} - {user.ho_ten} ({user.role})')
    
    # Create message
    message = ChatMessage(
        conversation_id=conversation_id,
        nguoi_goi_id=user_id,  # ⭐ MUST use user_id from connected_users
        noi_dung=data['noi_dung']
    )
    await sync_to_async(message.save)()
    print(f'[DEBUG] Created message {message.id}: nguoi_goi_id={message.nguoi_goi_id}')
```

**Expected output when user1 (id=6) sends message:**
```
[DEBUG] ==================== SEND MESSAGE ====================
[DEBUG] send_message - SID: kVZzWi0lO239ObF3AAAR
[DEBUG] send_message - Data: {'noi_dung': 'toi LA user 1'}
[DEBUG] Looking up user_id in connected_users...
[DEBUG] connected_users['kVZzWi0lO239ObF3AAAR'] = 6  ⭐ MUST BE 6
[DEBUG] Sender: 6 - hieu (khach_hang)
[DEBUG] Created message 58: nguoi_goi_id=6
```

**❌ If you see:**
```
[DEBUG] connected_users['kVZzWi0lO239ObF3AAAR'] = 11  # WRONG!
```
→ **Backend didn't update connected_users when user1 connected**

---

### 3. Check `disconnect` handler

```python
@sio.on('disconnect')
async def disconnect(sid):
    print(f'[DISCONNECT] ==================== DISCONNECT ====================')
    print(f'[DISCONNECT] Socket ID: {sid}')
    
    user_id = connected_users.get(sid)
    print(f'[DISCONNECT] Client {sid} (user {user_id}) disconnected')
    
    # ⭐ CRITICAL: Remove from connected_users
    if sid in connected_users:
        del connected_users[sid]
        print(f'[DISCONNECT] Removed from connected_users')
    
    print(f'[DISCONNECT] ✅ Cleanup complete')
```

**Expected output when user3 logs out:**
```
[DISCONNECT] ==================== DISCONNECT ====================
[DISCONNECT] Socket ID: <old-socket-id>
[DISCONNECT] Client <old-socket-id> (user 11) disconnected
[DISCONNECT] Removed from connected_users
[DISCONNECT] ✅ Cleanup complete
```

---

## 🎯 Most Likely Issues

### Issue 1: Backend not receiving `connect` event

**Symptom:** No CONNECT logs when user1 opens ChatScreen

**Cause:** 
- Socket.IO server config issue
- Namespace mismatch
- CORS blocking

**Fix:** Check Socket.IO server initialization:
```python
sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins='*',
    logger=True,  # Enable logging
    engineio_logger=True  # Enable Engine.IO logging
)
```

---

### Issue 2: `connected_users` dict not being updated

**Symptom:** CONNECT logs show user_id=6 but send_message uses user_id=11

**Cause:**
- `connect()` handler not saving to `connected_users`
- Using wrong variable name
- Dict being reset somewhere

**Fix:** Add debug print in ALL places where `connected_users` is modified:
```python
connected_users[sid] = user_id
print(f'[DEBUG] connected_users updated: {connected_users}')
```

---

### Issue 3: Session persistence in Engine.IO

**Symptom:** New connection reuses old session data

**Cause:**
- Engine.IO cookie still active
- Backend cache/session middleware

**Fix:** Force new session on connect:
```python
@sio.on('connect')
async def connect(sid, environ, auth):
    # Clear any existing mapping for this user
    for old_sid, uid in list(connected_users.items()):
        if uid == auth.get('user_id') and old_sid != sid:
            del connected_users[old_sid]
            print(f'[CONNECT] Removed old session {old_sid} for user {uid}')
    
    # Add new mapping
    connected_users[sid] = auth.get('user_id')
```

---

## 📊 Debug Checklist

When user1 (id=6) logs in and sends message, verify:

- [ ] Flutter log: `Current user: 6 (hieu)` ✅
- [ ] Flutter log: `Expected nguoi_goi_id: 6` ✅
- [ ] Flutter log: `From user_id: 6` ✅
- [ ] Backend log: `CONNECT ... Socket ID: kVZzWi0lO239ObF3AAAR`
- [ ] Backend log: `Auth received: {'user_id': 6, ...}`
- [ ] Backend log: `connected_users['kVZzWi0lO239ObF3AAAR'] = 6`
- [ ] Backend log: `send_message - connected_users[...] = 6`
- [ ] Backend log: `Created message ...: nguoi_goi_id=6`
- [ ] Database: `SELECT * FROM chat_message WHERE id=58` → `nguoi_goi_id=6`

---

## 🚀 Quick Fix to Try

Add this to backend `connect()` handler:

```python
@sio.on('connect')
async def connect(sid, environ, auth):
    user_id = auth.get('user_id')
    unique_id = auth.get('unique_id')
    
    print(f'[CONNECT] ========================================')
    print(f'[CONNECT] NEW CONNECTION')
    print(f'[CONNECT] SID: {sid}')
    print(f'[CONNECT] Auth user_id: {user_id}')
    print(f'[CONNECT] Auth unique_id: {unique_id}')
    print(f'[CONNECT] ========================================')
    
    # ⭐ FORCE update connected_users
    connected_users[sid] = user_id
    
    # Verify immediately
    verify = connected_users.get(sid)
    print(f'[CONNECT] Verification: connected_users[\'{sid}\'] = {verify}')
    
    if verify != user_id:
        print(f'[CONNECT] ❌❌❌ CRITICAL: Mapping failed! Expected {user_id}, got {verify}')
    else:
        print(f'[CONNECT] ✅ Mapping successful')
    
    return True
```

Then restart Django server and test again!

---

## 📝 Share These Logs

Please share the **complete backend logs** from:
1. When user3 logs out
2. When user1 logs in
3. When user1 opens ChatScreen
4. When user1 sends message

This will help identify exactly where the issue is!
