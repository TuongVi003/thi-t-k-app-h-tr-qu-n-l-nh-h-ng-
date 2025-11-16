from .models import KhuyenMai
from django.utils import timezone

def is_promotion_active(promotion, check_datetime):
    """
    Kiểm tra xem khuyến mãi có đang hoạt động tại thời điểm check_datetime không.
    """
    return promotion.active and promotion.ngay_bat_dau <= check_datetime <= promotion.ngay_ket_thuc


def discounted_price(original_price):
    """
    Tính toán giá sau khi áp dụng khuyến mãi.
    Trả về tuple: (giá sau giảm, danh sách khuyến mãi đã áp dụng)
    """
    now_time = timezone.now()
    promotions = KhuyenMai.objects.filter(active=True, ngay_bat_dau__lte=now_time, ngay_ket_thuc__gte=now_time)
    
    if not promotions:
        print("No active promotion found.")
        return original_price, []
    
    print("Promotion found:", promotions)
    discount_amount = 0
    applied_promotions = []
    # khuyến mãi nào cũng áp dụng trên tổng giá trị đơn hàng, chứ không phải giảm giá kép
    # tức là không áp dụng khuyến mãi sau khi đã giảm giá bởi khuyến mãi trước
    for promo in promotions:
        if promo.loai_giam_gia == 'percentage':
            discount_amount += original_price * (promo.gia_tri / 100)
            applied_promotions.append(promo)
        elif promo.loai_giam_gia == 'fixed_amount':
            discount_amount += promo.gia_tri
            applied_promotions.append(promo)

    final_price = original_price - discount_amount
    return max(final_price, 0), applied_promotions


