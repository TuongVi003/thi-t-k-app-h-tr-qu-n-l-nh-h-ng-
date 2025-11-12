"""
Django Signals để tự động gửi email khi Order hoàn thành

Cách sử dụng:
1. Copy file này vào: restaurant/signals.py
2. Import trong restaurant/apps.py (xem hướng dẫn bên dưới)
3. Restart server
"""

from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from restaurant.models import Order
from restaurant.mail_service import send_order_completion_email
import logging

logger = logging.getLogger(__name__)


@receiver(pre_save, sender=Order)
def track_order_status_change(sender, instance, **kwargs):
    """
    Track trạng thái cũ của order để biết khi nào chuyển sang 'completed'
    """
    if instance.pk:  # Nếu đã tồn tại trong DB
        try:
            # Lấy instance cũ từ database
            old_instance = Order.objects.get(pk=instance.pk)
            # Lưu trạng thái cũ vào instance (để dùng trong post_save)
            instance._old_trang_thai = old_instance.trang_thai
        except Order.DoesNotExist:
            instance._old_trang_thai = None
    else:
        instance._old_trang_thai = None


@receiver(post_save, sender=Order)
def send_completion_email_on_status_change(sender, instance, created, **kwargs):
    """
    Tự động gửi email khi order chuyển sang trạng thái 'completed'
    
    - Chỉ gửi khi STATUS THAY ĐỔI từ trạng thái khác sang 'completed'
    - Không gửi nếu order được tạo mới với status 'completed' ngay từ đầu
    - Không gửi nhiều lần cho cùng một order
    """
    
    # Không gửi email nếu là order mới được tạo
    if created:
        logger.info(f"Order #{instance.id} created with status '{instance.trang_thai}' - No email sent")
        return
    
    # Check nếu trạng thái hiện tại là 'completed'
    if instance.trang_thai != 'completed':
        return
    
    # Check nếu trạng thái cũ KHÔNG phải 'completed' (tức là MỚI chuyển sang completed)
    old_status = getattr(instance, '_old_trang_thai', None)
    
    if old_status == 'completed':
        # Đã completed từ trước rồi, không gửi lại
        logger.info(f"Order #{instance.id} was already completed - No email sent")
        return
    
    # Trạng thái VỪA CHUYỂN sang 'completed' → GỬI EMAIL
    logger.info(f"Order #{instance.id} status changed: {old_status} → completed - Sending email...")
    
    try:
        success = send_order_completion_email(instance)
        
        if success:
            logger.info(f"✅ Email sent successfully for Order #{instance.id}")
        else:
            logger.warning(f"⚠️ Email not sent for Order #{instance.id} (customer may not have email)")
            
    except Exception as e:
        logger.error(f"❌ Failed to send email for Order #{instance.id}: {e}")
        # Không raise exception để không block việc save order
        import traceback
        traceback.print_exc()


# ========================================================================
# CÁC SIGNAL KHÁC (Optional)
# ========================================================================

@receiver(post_save, sender=Order)
def log_order_changes(sender, instance, created, **kwargs):
    """
    Log mọi thay đổi của order (for debugging)
    """
    if created:
        logger.info(f"📝 NEW ORDER created: #{instance.id}")
    else:
        old_status = getattr(instance, '_old_trang_thai', 'unknown')
        logger.info(f"📝 ORDER UPDATED: #{instance.id} - Status: {old_status} → {instance.trang_thai}")


# Bạn có thể thêm các signals khác tại đây:
# - Send email khi order confirmed
# - Send email khi order ready
# - Send SMS notifications
# - Update inventory
# - etc.
