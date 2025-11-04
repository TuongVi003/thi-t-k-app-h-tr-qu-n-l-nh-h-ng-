"""
Script để chạy Socket.IO server với eventlet
Chạy: python run_socketio.py
"""
import eventlet
eventlet.monkey_patch()

import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'qlnh_backend.settings')
django.setup()

from restaurant.socket_handlers_wsgi import sio
import socketio
import eventlet.wsgi

# Wrap ASGI app with eventlet
if __name__ == '__main__':
    # Import Django WSGI app (not ASGI for eventlet)
    from django.core.wsgi import get_wsgi_application
    django_app = get_wsgi_application()
    
    # Create combined WSGI app
    app = socketio.WSGIApp(sio, django_app)
    
    print("=" * 60)
    print("🚀 Socket.IO Chat Server Starting...")
    print("=" * 60)
    print("Server: http://localhost:8001")
    print("Socket.IO endpoint: ws://localhost:8001/socket.io/")
    print("=" * 60)
    print("Port 8000: Django REST API (python manage.py runserver)")
    print("Port 8001: Socket.IO Server (python run_socketio.py)")
    print("=" * 60)
    
    # Start server
    eventlet.wsgi.server(eventlet.listen(('0.0.0.0', 8001)), app)
