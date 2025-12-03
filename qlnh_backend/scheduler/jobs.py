from datetime import datetime
from django.utils import timezone
from restaurant.models import DonHang
from restaurant.utils import send_to_user

def notify_reservations():
    now = datetime.now()
    print("Cron job chạy lúc", now)

    # Only check upcoming reservations (not in the past)
    don_hangs = DonHang.objects.filter(trang_thai__in=['pending', 'confirmed'], ngay_dat__gt=now)
    print(f"Found {don_hangs.count()} active reservations to check for notifications.")
    for dh in don_hangs:
        if not dh.khach_hang:
            # nếu không có khách hàng liên kết, bỏ qua vì không thể gửi thông báo
            continue

        time_delta = dh.ngay_dat - now
        minutes_left = int(time_delta.total_seconds() // 60)
        user = dh.khach_hang

        try:
            # Use a small window to account for scheduling fuzziness (job runs ~every minute)
            if minutes_left in (60, 59) and not dh.notified_1_hour:
                title = "Nhắc: sắp đến giờ đặt bàn (1 giờ)"
                body = f"Đơn đặt bàn của bạn sẽ bắt đầu vào {dh.ngay_dat.strftime('%H:%M %d/%m/%Y')} (còn 1 giờ)."
                print(f"Sending 1-hour reminder to user {user.id} for DonHang {dh.id}")
                send_to_user(user, title, body, data={"reservation_id": str(dh.id)})
                dh.notified_1_hour = True
                dh.save(update_fields=['notified_1_hour'])
            elif minutes_left in (30, 29) and not dh.notified_30_min:
                title = "Nhắc: sắp đến giờ đặt bàn (30 phút)"
                body = f"Đơn đặt bàn của bạn sẽ bắt đầu vào {dh.ngay_dat.strftime('%H:%M %d/%m/%Y')} (còn 30 phút)."
                print(f"Sending 30-minute reminder to user {user.id} for DonHang {dh.id}")
                send_to_user(user, title, body, data={"reservation_id": str(dh.id)})
                dh.notified_30_min = True
                dh.save(update_fields=['notified_30_min'])
            elif minutes_left in (10, 9) and not dh.notified_10_min:
                title = "Nhắc: sắp đến giờ đặt bàn (10 phút)"
                body = f"Đơn đặt bàn của bạn sẽ bắt đầu vào {dh.ngay_dat.strftime('%H:%M %d/%m/%Y')} (còn 10 phút)."
                print(f"Sending 10-minute reminder to user {user.id} for DonHang {dh.id}")
                send_to_user(user, title, body, data={"reservation_id": str(dh.id)})
                dh.notified_10_min = True
                dh.save(update_fields=['notified_10_min'])
        except Exception as e:
            # Don't break the loop if sending fails for some reservation
            print(f"❌ Failed sending reminder for DonHang {dh.id}: {e}")
