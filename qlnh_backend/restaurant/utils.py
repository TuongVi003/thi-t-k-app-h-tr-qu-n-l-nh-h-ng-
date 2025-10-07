from .models import FCMDevice
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