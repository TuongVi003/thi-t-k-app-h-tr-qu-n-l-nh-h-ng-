"""
Simple Socket.IO server runner
Chạy: python run_simple.py
Yêu cầu: pip install python-socketio aiohttp
"""
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'qlnh_backend.settings')
django.setup()

from aiohttp import web
from restaurant.socket_handlers import sio

# Tạo aiohttp app
app = web.Application()
sio.attach(app)

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 Socket.IO Chat Server (aiohttp)")
    print("=" * 60)
    print("Server: http://localhost:8000")
    print("Socket.IO: ws://localhost:8000/socket.io/")
    print("=" * 60)
    print("Tip: Mở test_chat.html hoặc dùng Postman")
    print("=" * 60)
    
    web.run_app(app, host='0.0.0.0', port=8000)
