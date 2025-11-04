"""
Test client cho Socket.IO chat
Chạy: python test_chat_client.py
"""
import socketio
import time

# Tạo socket client
sio = socketio.Client()

USER_ID = 1  # Thay bằng ID user test của bạn
USER_TYPE = 'khach_hang'  # hoặc 'nhan_vien'

@sio.on('connect')
def on_connect():
    print(f'✅ Connected to server as user {USER_ID}')
    print('=' * 60)

@sio.on('disconnect')
def on_disconnect():
    print('❌ Disconnected from server')

@sio.on('new_message')
def on_new_message(data):
    print('\n📨 New message received:')
    print(f"   From: {data['nguoi_goi_name']} (ID: {data['nguoi_goi_id']})")
    print(f"   Content: {data['noi_dung']}")
    print(f"   Time: {data['thoi_gian']}")
    print(f"   Conversation: {data['conversation_id']}")
    print('=' * 60)

@sio.on('user_typing')
def on_user_typing(data):
    if data['is_typing']:
        print(f'\n⌨️  {data["user_name"]} đang gõ...')
    else:
        print(f'\n   {data["user_name"]} đã dừng gõ')

@sio.on('error')
def on_error(data):
    print(f'\n❌ Error: {data}')
    print('=' * 60)

def send_message():
    """Gửi tin nhắn test"""
    if USER_TYPE == 'khach_hang':
        # Khách hàng gửi (không cần customer_id)
        message = input('\n💬 Nhập tin nhắn (hoặc "quit" để thoát): ')
        if message.lower() == 'quit':
            return False
        
        sio.emit('send_message', {
            'noi_dung': message
        })
        print('✅ Đã gửi tin nhắn')
        
    else:
        # Nhân viên gửi (cần customer_id)
        customer_id = input('\n👤 Nhập ID khách hàng: ')
        if customer_id.lower() == 'quit':
            return False
        
        message = input('💬 Nhập tin nhắn: ')
        if message.lower() == 'quit':
            return False
        
        sio.emit('send_message', {
            'noi_dung': message,
            'customer_id': int(customer_id)
        })
        print('✅ Đã gửi tin nhắn')
    
    return True

def send_typing(is_typing=True, customer_id=None):
    """Gửi trạng thái đang gõ"""
    data = {'is_typing': is_typing}
    if USER_TYPE == 'nhan_vien' and customer_id:
        data['customer_id'] = customer_id
    
    sio.emit('typing', data)

if __name__ == '__main__':
    print('=' * 60)
    print('🧪 Socket.IO Chat Test Client')
    print('=' * 60)
    print(f'User ID: {USER_ID}')
    print(f'User Type: {USER_TYPE}')
    print('=' * 60)
    
    try:
        # Kết nối với auth
        sio.connect('http://localhost:8000', auth={'user_id': USER_ID})
        
        # Wait for connection
        time.sleep(1)
        
        print('\n📝 Commands:')
        print('  - Nhập tin nhắn để gửi')
        print('  - Gõ "quit" để thoát')
        print('=' * 60)
        
        # Main loop
        while True:
            if not send_message():
                break
            time.sleep(0.5)
        
    except KeyboardInterrupt:
        print('\n\n👋 Đang ngắt kết nối...')
    except Exception as e:
        print(f'\n❌ Lỗi: {e}')
    finally:
        sio.disconnect()
        print('✅ Đã ngắt kết nối')
