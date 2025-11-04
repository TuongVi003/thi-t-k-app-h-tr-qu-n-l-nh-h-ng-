"""
Socket.IO handlers cho tính năng chat (WSGI version cho eventlet)
Xử lý real-time messaging giữa khách hàng và nhân viên
"""
import socketio
from restaurant.models import Conversation, ChatMessage, NguoiDung, FCMDevice

# Tạo Socket.IO server instance cho WSGI (sync mode)
sio = socketio.Server(
    async_mode='eventlet',
    cors_allowed_origins='*',  # Thay đổi theo domain của bạn trong production
    logger=True,
    engineio_logger=True
)

# Track connected users: {sid: user_id}
connected_users = {}

# Room naming convention:
# - Customer joins: f"customer_{customer_id}"
# - Staff joins: "staff_room" + all f"customer_{id}" rooms


@sio.event
def connect(sid, environ, auth):
    """
    Xử lý khi client kết nối
    Auth payload: {'user_id': int, 'token': str (optional)}
    """
    print(f"[CONNECT] Client {sid} connected")
    
    if not auth or 'user_id' not in auth:
        print(f"[CONNECT] Rejected: No user_id in auth")
        return False  # Từ chối kết nối
    
    user_id = auth.get('user_id')
    try:
        # Verify user exists
        user = NguoiDung.objects.get(id=user_id)
        connected_users[sid] = user_id
        print(f"[CONNECT] User {user.ho_ten} ({user_id}) connected as {sid}")
        
        # Auto join rooms based on user type
        if user.loai_nguoi_dung == 'khach_hang':
            # Customer joins their own room
            room = f"customer_{user_id}"
            sio.enter_room(sid, room)
            print(f"[JOIN] Customer {user_id} joined room: {room}")
            
        elif user.loai_nguoi_dung == 'nhan_vien':
            # Staff joins staff room
            sio.enter_room(sid, 'staff_room')
            print(f"[JOIN] Staff {user_id} joined staff_room")
            
            # Staff also joins all active customer rooms (để nhận tin mới)
            conversations = Conversation.objects.filter(is_staff_group=True).select_related('customer')
            for conv in conversations:
                if conv.customer:
                    customer_room = f"customer_{conv.customer.id}"
                    sio.enter_room(sid, customer_room)
                    print(f"[JOIN] Staff {user_id} joined {customer_room}")
        
        return True
        
    except NguoiDung.DoesNotExist:
        print(f"[CONNECT] Rejected: User {user_id} not found")
        return False
    except Exception as e:
        print(f"[CONNECT] Error: {e}")
        return False


@sio.event
def disconnect(sid):
    """Xử lý khi client ngắt kết nối"""
    user_id = connected_users.pop(sid, None)
    print(f"[DISCONNECT] Client {sid} (user {user_id}) disconnected")


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
        
        # Prepare response data
        message_data = {
            'id': message.id,
            'conversation_id': conv.id,
            'nguoi_goi_id': sender.id,
            'nguoi_goi_name': message.nguoi_goi_display(),
            'noi_dung': message.noi_dung,
            'thoi_gian': message.thoi_gian.isoformat(),
        }
        
        # Broadcast tin nhắn
        if sender.loai_nguoi_dung == 'khach_hang':
            # Kiểm tra xem có phải conversation mới không (tin nhắn đầu tiên)
            is_new_conversation = conv.messages.count() == 1  # Chỉ có 1 tin (tin vừa tạo)
            
            # Gửi tới staff_room và room của chính customer (để customer thấy tin mình gửi)
            sio.emit('new_message', message_data, room='staff_room')
            sio.emit('new_message', message_data, room=f"customer_{sender.id}")
            print(f"[MESSAGE] Customer {sender.id} -> staff_room")
            
            # Nếu là conversation mới, thông báo cho staff cập nhật conversation list
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
                print(f"[NEW CONVERSATION] Customer {sender.id} created new conversation #{conv.id}")
            
            # Gửi push notification tới staff (optional, nếu dùng FCM)
            # send_push_to_staff(message)
            
        else:  # staff
            # Gửi tới room của customer và staff_room (để staff khác cũng thấy)
            sio.emit('new_message', message_data, room=target_room)
            sio.emit('new_message', message_data, room='staff_room')
            print(f"[MESSAGE] Staff {sender.id} -> {target_room}")
            
            # Gửi push notification tới customer (optional)
            # send_push_to_customer(message, customer)
        
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


# Helper functions cho push notifications (optional - implement nếu cần)
def send_push_to_staff(message):
    """Gửi push notification tới tất cả staff devices"""
    # Implement FCM push logic here
    pass

def send_push_to_customer(message, customer):
    """Gửi push notification tới customer"""
    # Implement FCM push logic here
    pass
