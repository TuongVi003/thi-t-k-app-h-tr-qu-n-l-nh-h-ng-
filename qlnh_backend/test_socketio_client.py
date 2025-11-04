"""
Script test Socket.IO connection
Chạy file này để test kết nối Socket.IO từ Python client
"""
import socketio
import time

# Create a Socket.IO client
sio = socketio.Client()

# Event handlers
@sio.event
def connect():
    print('✅ Connected to Socket.IO server')
    print('Connection ID:', sio.sid)

@sio.event
def disconnect():
    print('❌ Disconnected from Socket.IO server')

@sio.event
def new_message(data):
    print(f'\n📨 New message received:')
    print(f'  From: {data.get("nguoi_goi_name")}')
    print(f'  Content: {data.get("noi_dung")}')
    print(f'  Time: {data.get("thoi_gian")}')

@sio.on('error')
def on_error(data):
    print(f'⚠️ Error: {data}')

@sio.event
def user_typing(data):
    print(f'⌨️ {data.get("user_name")} is {"typing" if data.get("is_typing") else "stopped typing"}...')

def test_connection():
    """Test Socket.IO connection"""
    print('=' * 60)
    print('🧪 Testing Socket.IO Connection')
    print('=' * 60)
    
    # Change this to your Socket.IO server URL
    server_url = 'http://localhost:8001'
    
    # Change this to a valid user_id from your database
    test_user_id = 1  # Staff user ID
    
    try:
        print(f'\n📡 Connecting to: {server_url}')
        print(f'👤 User ID: {test_user_id}')
        
        # Connect with authentication
        sio.connect(
            server_url,
            auth={'user_id': test_user_id},
            transports=['websocket', 'polling']
        )
        
        print('\n✅ Connection successful!')
        print('\n📬 Waiting for messages... (Press Ctrl+C to stop)')
        
        # Keep the connection alive
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print('\n\n👋 Disconnecting...')
            sio.disconnect()
            
    except socketio.exceptions.ConnectionError as e:
        print(f'\n❌ Connection failed: {e}')
        print('\n💡 Tips:')
        print('  1. Make sure Socket.IO server is running on port 8001')
        print('  2. Run: python run_socketio.py')
        print('  3. Check if user_id exists in database')
    except Exception as e:
        print(f'\n❌ Error: {e}')

def test_send_message():
    """Test sending a message"""
    server_url = 'http://localhost:8001'
    test_user_id = 1  # Staff user ID
    customer_id = 2  # Customer to send message to
    
    try:
        sio.connect(
            server_url,
            auth={'user_id': test_user_id},
            transports=['websocket', 'polling']
        )
        
        print('✅ Connected! Sending test message...')
        
        # Send a test message
        sio.emit('send_message', {
            'noi_dung': 'Test message from Python client',
            'customer_id': customer_id
        })
        
        print('✅ Message sent!')
        
        # Wait a bit for response
        time.sleep(2)
        
        sio.disconnect()
        
    except Exception as e:
        print(f'❌ Error: {e}')

if __name__ == '__main__':
    print('\n🧪 Socket.IO Test Client')
    print('=' * 60)
    print('\nChoose test mode:')
    print('1. Test connection (listen for messages)')
    print('2. Test sending message')
    print('3. Exit')
    
    choice = input('\nEnter choice (1-3): ').strip()
    
    if choice == '1':
        test_connection()
    elif choice == '2':
        test_send_message()
    elif choice == '3':
        print('👋 Goodbye!')
    else:
        print('❌ Invalid choice!')
