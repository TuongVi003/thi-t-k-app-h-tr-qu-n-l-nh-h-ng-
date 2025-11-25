"""
Socket.IO handlers cho tính năng chat (WSGI version cho eventlet)
Xử lý real-time messaging giữa khách hàng và nhân viên
"""
import socketio
import eventlet
import os
from restaurant.models import Conversation, ChatMessage, NguoiDung, FCMDevice

# Configurable maximum auth age (milliseconds). Increase if clients have clock skew or network delay.
AUTH_MAX_AGE_MS = int(os.getenv('AUTH_MAX_AGE_MS', '30000'))  # default 30s

# Tạo Socket.IO server instance cho WSGI (sync mode)
sio = socketio.Server(
    async_mode='eventlet',
    cors_allowed_origins='*',  # Thay đổi theo domain của bạn trong production
    logger=True,
    engineio_logger=True,
    # CRITICAL: Prevent reconnection with stale auth
    ping_timeout=10,
    ping_interval=5,
    always_connect=True,
    cookie=None,  # Force new session every time
)

# Track connected users: {sid: user_id}
connected_users = {}

# Track expected auth: {sid: {'user_id': int, 'timestamp': int}}
expected_auth = {}

# Room naming convention:
# - Customer joins: f"customer_{customer_id}"
# - Staff joins: "staff_room" + all f"customer_{id}" rooms


def cleanup_session(sid):
    """Helper to completely clean up a session"""
    connected_users.pop(sid, None)
    expected_auth.pop(sid, None)
    print(f"[CLEANUP] Removed session {sid} from all tracking dicts")


def _post_connect_setup(sid, user_id, timestamp, unique_id):
    """Run DB lookups and room joins in background to avoid blocking connect()"""
    try:
        # Verify user exists in DB
        user = NguoiDung.objects.get(id=user_id)

        # expected_auth already set in connect(), no need to update here
        print(f"[POST_CONNECT] ✅ Verified user {user.ho_ten} ({user_id}) for sid {sid}")

        # Auto join rooms based on user type (can be slow, done in background)
        if user.loai_nguoi_dung == 'khach_hang':
            room = f"customer_{user_id}"
            try:
                sio.enter_room(sid, room)
                print(f"[JOIN] Customer {user_id} joined room: {room}")
            except Exception as e:
                print(f"[POST_CONNECT] Error joining room {room}: {e}")

        elif user.loai_nguoi_dung == 'nhan_vien':
            try:
                sio.enter_room(sid, 'staff_room')
                print(f"[JOIN] Staff {user_id} joined staff_room")
            except Exception as e:
                print(f"[POST_CONNECT] Error joining staff_room: {e}")

            # Join active customer rooms
            try:
                conversations = list(Conversation.objects.filter(is_staff_group=True).select_related('customer'))
                for conv in conversations:
                    if conv.customer:
                        customer_room = f"customer_{conv.customer.id}"
                        try:
                            sio.enter_room(sid, customer_room)
                            print(f"[JOIN] Staff {user_id} joined {customer_room}")
                        except Exception:
                            pass
            except Exception as e:
                print(f"[POST_CONNECT] Error fetching conversations: {e}")

    except NguoiDung.DoesNotExist:
        print(f"[POST_CONNECT] ❌ User {user_id} not found, cleaning up sid {sid}")
        cleanup_session(sid)
        try:
            sio.disconnect(sid)
        except Exception as e:
            print(f"[POST_CONNECT] Error disconnecting sid {sid}: {e}")
    except Exception as e:
        print(f"[POST_CONNECT] Unexpected error for sid {sid}: {e}")
        cleanup_session(sid)
        try:
            sio.disconnect(sid)
        except Exception:
            pass


# Helper function to manually cleanup user sessions (called from views)
def force_cleanup_user_sessions(user_id):
    """Force cleanup all sessions for a specific user (called when user logs out)"""
    sids_to_remove = [sid for sid, uid in connected_users.items() if uid == user_id]
    for sid in sids_to_remove:
        print(f"[FORCE_CLEANUP] Removing session {sid} for user {user_id}")
        cleanup_session(sid)
    print(f"[FORCE_CLEANUP] Cleaned up {len(sids_to_remove)} sessions for user {user_id}")
    return len(sids_to_remove)


@sio.event
def connect(sid, environ, auth):
    """
    Xử lý khi client kết nối
    Auth payload: {'user_id': int, 'token': str (optional)}
    """
    print(f"[CONNECT] ==================== NEW CONNECTION ====================")
    print(f"[CONNECT] Socket ID: {sid}")
    print(f"[CONNECT] Auth received: {auth}")
    print(f"[CONNECT] Expected auth: {expected_auth.get(sid, 'NONE')}")
    print(f"[CONNECT] Current connected_users: {connected_users}")
    
    # CRITICAL: Check if this is a stale reconnection
    if sid not in expected_auth and sid in connected_users:
        old_user_id = connected_users[sid]
        new_user_id = auth.get('user_id') if auth else None
        print(f"[CONNECT] 🚨 STALE SESSION DETECTED!")
        print(f"[CONNECT] 🚨 SID {sid} has old user {old_user_id} but no expected_auth")
        print(f"[CONNECT] 🚨 New auth claims user {new_user_id}")
        print(f"[CONNECT] 🚨 REJECTING to force fresh connection")
        cleanup_session(sid)
        return False
    
    # CRITICAL: Always check if this sid was previously connected with a DIFFERENT user
    if sid in connected_users:
        old_user_id = connected_users[sid]
        new_user_id = auth.get('user_id') if auth else None
        if old_user_id != new_user_id:
            print(f"[CONNECT] ⚠️ WARNING: SID {sid} was previously user {old_user_id}, now requesting {new_user_id}")
            print(f"[CONNECT] 🧹 Cleaning up old connection...")
            cleanup_session(sid)
    
    if not auth or 'user_id' not in auth:
        print(f"[CONNECT] ❌ Rejected: No user_id in auth")
        cleanup_session(sid)
        return False
    
    user_id = auth.get('user_id')
    
    # Extra validation: Check timestamp and unique_id
    timestamp = auth.get('timestamp')
    unique_id = auth.get('unique_id')
    print(f"[CONNECT] Auth timestamp: {timestamp}, user_id: {user_id}, unique_id: {unique_id}")
    
    # CRITICAL: Check if auth is recent (within last 10 seconds)
    if timestamp:
        try:
            import time
            current_time = int(time.time() * 1000)
            auth_age = current_time - int(timestamp)
            print(f"[CONNECT] Auth age: {auth_age}ms")
            
            if auth_age > AUTH_MAX_AGE_MS:
                print(f"[CONNECT] 🚨 AUTH TOO OLD! Age: {auth_age}ms > {AUTH_MAX_AGE_MS}ms")
                print(f"[CONNECT] 🚨 REJECTING stale authentication")
                cleanup_session(sid)
                return False
        except (ValueError, TypeError) as e:
            print(f"[CONNECT] ⚠️ Could not validate timestamp: {e}")
    
    # Validate against expected_auth if exists
    if sid in expected_auth:
        expected = expected_auth[sid]
        if expected['user_id'] != user_id:
            print(f"[CONNECT] 🚨 MISMATCH! Expected user {expected['user_id']}, got {user_id}")
            print(f"[CONNECT] 🚨 REJECTING connection")
            cleanup_session(sid)
            return False
        print(f"[CONNECT] ✅ Auth matches expected user {user_id}")
    
    # Lightweight accept: set mapping and expected_auth IMMEDIATELY, defer DB/room work to background
    try:
        connected_users[sid] = user_id
        # CRITICAL: Set expected_auth NOW (not in background) so send_message won't reject
        expected_auth[sid] = {
            'user_id': user_id,
            'timestamp': timestamp,
            'unique_id': unique_id,
        }
        print(f"[CONNECT] ↪ Accepted provisional mapping: connected_users['{sid}'] = {user_id}")
        print(f"[CONNECT] ↪ Set expected_auth['{sid}'] = user {user_id}")
        # Spawn background worker to verify user and perform room joins
        try:
            eventlet.spawn_n(_post_connect_setup, sid, user_id, timestamp, unique_id)
        except Exception as e:
            print(f"[CONNECT] ⚠️ Could not spawn background post-connect worker: {e}")
        return True
    except Exception as e:
        print(f"[CONNECT] Error during provisional accept: {e}")
        cleanup_session(sid)
        return False


@sio.event
def disconnect(sid):
    """Xử lý khi client ngắt kết nối"""
    user_id = connected_users.get(sid)
    cleanup_session(sid)
    
    # CRITICAL: Force disconnect from server side
    try:
        sio.disconnect(sid)
    except Exception as e:
        print(f"[DISCONNECT] Error forcing disconnect: {e}")
    
    if user_id:
        print(f"[DISCONNECT] ✅ Client {sid} (user {user_id}) disconnected and cleaned up")
    else:
        print(f"[DISCONNECT] ⚠️ Client {sid} disconnected but was NOT in connected_users dict")
    print(f"[DISCONNECT] 📊 Remaining connected users: {len(connected_users)}")
    print(f"[DISCONNECT] 📊 Remaining expected_auth: {len(expected_auth)}")


@sio.event
def send_message(sid, data):
    """
    Gửi tin nhắn
    Payload: {
        'noi_dung': str,
        'customer_id': int (bắt buộc nếu staff gửi)
    }
    """
    try:
        user_id = connected_users.get(sid)
        print(f"[DEBUG] send_message - SID: {sid}, user_id from connected_users: {user_id}")
        
        # CRITICAL: Validate this is not a stale session
        if sid not in expected_auth:
            print(f"[ERROR] 🚨 STALE SESSION! SID {sid} not in expected_auth but has user_id {user_id}")
            cleanup_session(sid)
            sio.emit('error', {'message': 'Session expired. Please reconnect.'}, room=sid)
            sio.disconnect(sid)
            return
        
        # CRITICAL: Also validate timestamp is recent (within last 5 minutes)
        expected = expected_auth[sid]
        auth_timestamp = expected.get('timestamp')
        if auth_timestamp:
            import time
            current_time = int(time.time() * 1000)
            age_seconds = (current_time - auth_timestamp) / 1000
            if age_seconds > 300:  # 5 minutes
                print(f"[ERROR] 🚨 AUTH TOO OLD! SID {sid} auth is {age_seconds:.1f} seconds old")
                cleanup_session(sid)
                sio.emit('error', {'message': 'Session expired. Please reconnect.'}, room=sid)
                sio.disconnect(sid)
                return
        
        if not user_id:
            sio.emit('error', {'message': 'Unauthorized'}, room=sid)
            return
        
        sender = NguoiDung.objects.get(id=user_id)
        noi_dung = data.get('noi_dung', '').strip()
        
        if not noi_dung:
            sio.emit('error', {'message': 'Nội dung tin nhắn trống'}, room=sid)
            return
        
        # Xác định conversation
        if sender.loai_nguoi_dung == 'khach_hang':
            # Khách hàng gửi -> conversation của chính họ
            conv = Conversation.get_or_create_for_customer(sender)
            target_room = 'staff_room'  # Gửi tới tất cả staff
            
        elif sender.loai_nguoi_dung == 'nhan_vien':
            # Nhân viên gửi -> cần customer_id
            customer_id = data.get('customer_id')
            if not customer_id:
                sio.emit('error', {'message': 'Thiếu customer_id'}, room=sid)
                return
            
            customer = NguoiDung.objects.get(id=customer_id)
            conv = Conversation.get_or_create_for_customer(customer)
            target_room = f"customer_{customer_id}"  # Gửi tới khách hàng đó
            
        else:
            sio.emit('error', {'message': 'Loại người dùng không hợp lệ'}, room=sid)
            return
        
        # Lưu message vào DB
        message = ChatMessage.objects.create(
            conversation=conv,
            nguoi_goi=sender,
            noi_dung=noi_dung
        )
        
        # ⭐ CẬP NHẬT conversation last_message_at để sort đúng
        conv.last_message_at = message.thoi_gian
        conv.save(update_fields=['last_message_at'])
        
        # Prepare response data (cho tin nhắn chat bubble)
        message_data = {
            'id': message.id,
            'conversation_id': conv.id,
            'nguoi_goi_id': sender.id,
            'nguoi_goi_name': message.nguoi_goi_display(),
            'noi_dung': message.noi_dung,
            'thoi_gian': message.thoi_gian.isoformat(),
            'conversation': {
                'id': conv.id,
                'customer_id': conv.customer_id,
                'customer_name': conv.customer.ho_ten if conv.customer else None,
                'customer_phone': conv.customer.so_dien_thoai if conv.customer else None,
                'last_message_at': conv.last_message_at.isoformat() if conv.last_message_at else None,
            }
        }
        
        # === BROADCAST LOGIC ===
        if sender.loai_nguoi_dung == 'khach_hang':
            is_new_conversation = conv.messages.count() == 1
            
            # 1. Gửi tin nhắn (Bubble chat)
            sio.emit('new_message', message_data, room='staff_room')
            sio.emit('new_message', message_data, room=f"customer_{sender.id}")
            
            # 2. Nếu là hội thoại mới tinh, báo sự kiện tạo mới
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

            # 3. [QUAN TRỌNG] Gửi event cập nhật danh sách (sort lên đầu) cho Staff
            # Phần này trước đây bị thiếu, khiến tin nhắn từ khách cũ không update list
            conversation_update_data = {
                'id': conv.id,
                'customer_id': sender.id,
                'customer_name': sender.ho_ten,
                'customer_phone': sender.so_dien_thoai,
                'last_message_at': conv.last_message_at.isoformat() if conv.last_message_at else None,
                'last_message': {
                    'id': message.id,
                    'conversation_id': conv.id,
                    'nguoi_goi_id': sender.id,
                    'nguoi_goi_name': message.nguoi_goi_display(),
                    'noi_dung': message.noi_dung,
                    'thoi_gian': message.thoi_gian.isoformat(),
                    'nguoi_goi_info': {
                        'id': sender.id,
                        'username': sender.username,
                        'ho_ten': sender.ho_ten,
                        'loai_nguoi_dung': sender.loai_nguoi_dung,
                        'chuc_vu': getattr(sender, 'chuc_vu', None),
                    }
                },
                'is_new': is_new_conversation,
            }
            sio.emit('conversation_updated', conversation_update_data, room='staff_room')
            print(f"[UPDATE] Sent conversation_updated to staff_room for Conv #{conv.id}")
            
            # 4. Gửi Push Notification
            send_push_to_staff(message)
            
        else:  # Staff gửi
            # 1. Gửi tin nhắn
            sio.emit('new_message', message_data, room=target_room)
            sio.emit('new_message', message_data, room='staff_room')
            
            # 2. Gửi event cập nhật danh sách cho các staff khác
            conversation_update_data = {
                'id': conv.id,
                'customer_id': customer_id,
                'customer_name': customer.ho_ten,
                'customer_phone': customer.so_dien_thoai,
                'last_message_at': conv.last_message_at.isoformat() if conv.last_message_at else None,
                'last_message': {
                    'id': message.id,
                    'conversation_id': conv.id,
                    'nguoi_goi_id': sender.id,
                    'nguoi_goi_name': message.nguoi_goi_display(),
                    'noi_dung': message.noi_dung,
                    'thoi_gian': message.thoi_gian.isoformat(),
                    'nguoi_goi_info': {
                        'id': sender.id,
                        'username': sender.username,
                        'ho_ten': sender.ho_ten,
                        'loai_nguoi_dung': sender.loai_nguoi_dung,
                        'chuc_vu': getattr(sender, 'chuc_vu', None),
                    }
                },
                'is_new': False,
            }
            sio.emit('conversation_updated', conversation_update_data, room='staff_room')
            
            # 3. Gửi Push Notification
            send_push_to_customer(message, customer)
        
    except NguoiDung.DoesNotExist:
        sio.emit('error', {'message': 'Người dùng không tồn tại'}, room=sid)
    except Exception as e:
        print(f"[ERROR] send_message: {e}")
        import traceback
        traceback.print_exc()
        sio.emit('error', {'message': str(e)}, room=sid)

@sio.event
def join_conversation(sid, data):
    """
    Staff join vào room của customer cụ thể (nếu chưa join)
    Payload: {'customer_id': int}
    """
    try:
        user_id = connected_users.get(sid)
        if not user_id:
            return
        
        user = NguoiDung.objects.get(id=user_id)
        if user.loai_nguoi_dung != 'nhan_vien':
            return
        
        customer_id = data.get('customer_id')
        if not customer_id:
            return
        
        customer_room = f"customer_{customer_id}"
        sio.enter_room(sid, customer_room)
        print(f"[JOIN] Staff {user_id} joined {customer_room}")
        
    except Exception as e:
        print(f"[ERROR] join_conversation: {e}")


@sio.event
def typing(sid, data):
    """
    Xử lý sự kiện đang gõ
    Payload: {'customer_id': int (nếu staff), 'is_typing': bool}
    """
    try:
        user_id = connected_users.get(sid)
        if not user_id:
            return
        
        user = NguoiDung.objects.get(id=user_id)
        is_typing = data.get('is_typing', False)
        
        typing_data = {
            'user_id': user_id,
            'user_name': user.ho_ten,
            'is_typing': is_typing
        }
        
        if user.loai_nguoi_dung == 'khach_hang':
            # Khách gõ -> thông báo staff
            sio.emit('user_typing', typing_data, room='staff_room', skip_sid=sid)
        else:
            # Staff gõ -> thông báo customer
            customer_id = data.get('customer_id')
            if customer_id:
                sio.emit('user_typing', typing_data, room=f"customer_{customer_id}", skip_sid=sid)
                
    except Exception as e:
        print(f"[ERROR] typing: {e}")


# Helper functions cho push notifications
def send_push_to_staff(message):
    """Gửi push notification tới tất cả staff devices"""
    from restaurant.utils import send_to_user
    
    try:
        # Lấy tất cả nhân viên
        staff_users = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien')
        
        for staff in staff_users:
            send_to_user(
                user=staff,
                title=f"💬 Tin nhắn mới từ {message.nguoi_goi.ho_ten}",
                body=message.noi_dung[:100],  # Giới hạn 100 ký tự
                data={
                    'type': 'chat',
                    'message_id': str(message.id),
                    'conversation_id': str(message.conversation.id),
                    'customer_id': str(message.conversation.customer_id),
                    'customer_name': message.conversation.customer.ho_ten if message.conversation.customer else '',
                }
            )
        print(f"[PUSH] Sent notification to {staff_users.count()} staff members")
    except Exception as e:
        print(f"[PUSH ERROR] Failed to send to staff: {e}")


def send_push_to_customer(message, customer):
    """Gửi push notification tới customer"""
    from restaurant.utils import send_to_user
    
    try:
        send_to_user(
            user=customer,
            title="💬 Nhân viên đã trả lời",
            body=message.noi_dung[:100],  # Giới hạn 100 ký tự
            data={
                'type': 'chat',
                'message_id': str(message.id),
                'conversation_id': str(message.conversation.id),
                'staff_id': str(message.nguoi_goi_id),
            }
        )
        print(f"[PUSH] Sent notification to customer {customer.id}")
    except Exception as e:
        print(f"[PUSH ERROR] Failed to send to customer {customer.id}: {e}")
