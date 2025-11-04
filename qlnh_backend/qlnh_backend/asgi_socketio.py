"""
ASGI config for qlnh_backend project với Socket.IO integration
"""
import os
from django.core.asgi import get_asgi_application
from restaurant.socket_handlers import sio
import socketio

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'qlnh_backend.settings')

# Initialize Django ASGI application
django_asgi_app = get_asgi_application()

# Combine Socket.IO with Django ASGI
application = socketio.ASGIApp(
    sio,
    django_asgi_app,
    socketio_path='socket.io'  # Đường dẫn socket.io endpoint
)
