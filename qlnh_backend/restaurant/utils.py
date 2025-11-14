from .models import FCMDevice, Notification
from firebase_admin import messaging

def send_push_notification(token, title, body, data=None):
    """
    Gửi push notification đến 1 thiết bị cụ thể (qua fcm token)
    """
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        data=data or {},
        token=token,
    )

    try:
        response = messaging.send(message)
        print('✅ Successfully sent message:', response)
    except Exception as e:
        print('❌ Error sending message:', e)


# Gửi notification đến tất cả thiết bị (token) của 1 user
def send_to_user(user, title, body, data=None):
    """
    Gửi notification đến tất cả thiết bị (token) của 1 user
    """
    tokens = FCMDevice.objects.filter(user=user).values_list("token", flat=True)
    if user.loai_nguoi_dung == 'khach_hang':
        Notification.objects.create(title=title, message=body, user=user, image_url=data.get('image_url') if data else None)
    for token in tokens:
        print(f"Sending notification to token: {token}")
        send_push_notification(token, title, body, data)


# Gửi push notification đến nhiều thiết bị (qua fcm token)
# tokens: list of fcm tokens
def send_bulk_notification(tokens, title, body, data=None):
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        data=data or {},
        tokens=tokens,
    )
    response = messaging.send_multicast(message)
    print(f"✅ Sent {response.success_count} messages, {response.failure_count} failed.")


# Gửi notification đến tất cả thiết bị (token) trong hệ thống
def send_to_all(title, body):
    from .models import FCMDevice
    tokens = FCMDevice.objects.values_list("token", flat=True)
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        tokens=list(tokens),
    )
    messaging.send_multicast(message)


def get_table_status(obj):
    """
    Trả về trạng thái của bàn ăn (obj là instance của BanAn)
    - 'available': Bàn trống, có thể đặt
    - 'occupied': Bàn đang có khách (có đơn Order trạng thái pending, confirmed, cooking, ready)
    """
    from .models import DonHang, Order
    from django.utils import timezone

    today = timezone.now().date()
    print(f"Checking status for table {obj.so_ban} on {today}") 

    # Check active reservations in DonHang
    active_reservations_donhang = DonHang.objects.filter(
        ban_an=obj, 
        trang_thai__in=['pending', 'confirmed'],
        ngay_dat__date=today
    ).exists()
    
    # Check active orders in Order (dine-in only)
    active_orders = Order.objects.filter(
        ban_an=obj,
        loai_order='dine_in',
        order_time__date=today,
        trang_thai__in=['pending', 'confirmed', 'cooking', 'ready']
    ).exists()
    
    if active_reservations_donhang or active_orders:
        return 'occupied'
    else:
        return 'available'

def get_table_status_at(obj, date):
    """
    Trả về trạng thái của bàn ăn (obj là instance của BanAn)
    - 'available': Bàn trống, có thể đặt
    - 'occupied': Bàn đang có khách (có đơn Order trạng thái pending, confirmed, cooking, ready)
    """
    from .models import DonHang, Order
    from django.utils import timezone
    from datetime import datetime, date as date_type

    # Convert date parameter to date object
    if isinstance(date, datetime):
        date = timezone.localdate(date) if timezone.is_aware(date) else date.date()
    elif isinstance(date, date_type):
        pass  # already a date object
    else:
        date = timezone.localdate(date)

    # Check active reservations in DonHang
    active_reservations_donhang = DonHang.objects.filter(
        ban_an=obj,
        trang_thai__in=['pending', 'confirmed'],
        ngay_dat__date=date
    ).exists()

    # Check active orders in Order (dine-in only)
    active_orders = Order.objects.filter(
        ban_an=obj,
        loai_order='dine_in',
        order_time__date=date,
        trang_thai__in=['pending', 'confirmed', 'cooking', 'ready']
    ).exists()

    if active_reservations_donhang or active_orders:
        return 'occupied'
    else:
        return 'available'


def get_table_occupancy_info(obj, date=None):
    """
    Trả về thông tin chi tiết về việc chiếm dụng bàn (ngày, giờ)
    - Nếu bàn trống: return None
    - Nếu bàn bị chiếm: return dict với 'date', 'time', 'datetime' của khách sắp tới hoặc đang ăn
    """
    from .models import DonHang, Order
    from django.utils import timezone

    if date is None:
        check_date = timezone.now().date()
    else:
        check_date = timezone.localdate(date)

    # Check active reservations in DonHang first (priority)
    reservation = DonHang.objects.filter(
        ban_an=obj,
        trang_thai__in=['pending', 'confirmed'],
        ngay_dat__date=check_date
    ).first()
    
    if reservation:
        return {
            'type': 'reservation',
            'date': reservation.ngay_dat.date(),
            'time': reservation.ngay_dat.time(),
            'datetime': reservation.ngay_dat
        }
    
    # Check active orders in Order (dine-in only)
    order = Order.objects.filter(
        ban_an=obj,
        loai_order='dine_in',
        order_time__date=check_date,
        trang_thai__in=['pending', 'confirmed', 'cooking', 'ready']
    ).first()
    
    if order:
        return {
            'type': 'order',
            'date': order.order_time.date(),
            'time': order.order_time.time(),
            'datetime': order.order_time
        }
    
    return None


def format_donhang_status(trang_thai):
    status_dict = {
        'pending': 'Chờ xác nhận',
        'confirmed': 'Đã xác nhận',
        'completed': 'Đã hoàn thành',
        'canceled': 'Đã hủy',
    }
    return status_dict.get(trang_thai, 'Không xác định')

