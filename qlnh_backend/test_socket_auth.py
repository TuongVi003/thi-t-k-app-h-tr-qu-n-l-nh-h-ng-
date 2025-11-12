"""
Script để test Socket.IO authentication với multiple users
Verify rằng khi switch user, backend nhận đúng user_id mới
"""
import asyncio
import socketio

# URL của Socket.IO server
SOCKET_URL = 'http://localhost:8000'

async def test_user_switch():
    """Test switching between users"""
    
    print("=== TEST 1: Connect User 9 ===")
    sio1 = socketio.AsyncClient()
    
    @sio1.event
    async def connect():
        print(f"✅ User 9 connected - Socket ID: {sio1.sid}")
    
    @sio1.event
    async def disconnect():
        print(f"❌ User 9 disconnected")
    
    # Connect as user 9
    await sio1.connect(SOCKET_URL, auth={'user_id': 9, 'timestamp': asyncio.get_event_loop().time()})
    await asyncio.sleep(2)
    
    # Send message as user 9
    print("📤 Sending message as User 9...")
    await sio1.emit('send_message', {'noi_dung': 'Test from User 9'})
    await asyncio.sleep(2)
    
    # Disconnect user 9
    print("🔌 Disconnecting User 9...")
    await sio1.disconnect()
    await asyncio.sleep(2)  # Wait for backend to process disconnect
    
    print("\n=== TEST 2: Connect User 11 ===")
    sio2 = socketio.AsyncClient()
    
    @sio2.event
    async def connect():
        print(f"✅ User 11 connected - Socket ID: {sio2.sid}")
    
    @sio2.event
    async def disconnect():
        print(f"❌ User 11 disconnected")
    
    # Connect as user 11 (DIFFERENT user)
    await sio2.connect(SOCKET_URL, auth={'user_id': 11, 'timestamp': asyncio.get_event_loop().time()})
    await asyncio.sleep(2)
    
    # Send message as user 11
    print("📤 Sending message as User 11...")
    await sio2.emit('send_message', {'noi_dung': 'Test from User 11'})
    await asyncio.sleep(2)
    
    # Check backend logs:
    # - Should see "User 11" in send_message handler, NOT "User 9"
    # - connected_users[sid] should be 11, not 9
    
    print("🔌 Disconnecting User 11...")
    await sio2.disconnect()
    
    print("\n✅ Test complete! Check backend logs:")
    print("   - Verify that messages show correct user_id (9 then 11)")
    print("   - Verify connected_users dict is updated correctly")

if __name__ == '__main__':
    asyncio.run(test_user_switch())
