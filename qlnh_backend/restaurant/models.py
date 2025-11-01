from django.db import models
from django.contrib.auth.models import AbstractUser
import math
from decimal import Decimal, InvalidOperation
from django.core.exceptions import ObjectDoesNotExist



class NguoiDung(AbstractUser):
    ho_ten = models.CharField(max_length=100)
    so_dien_thoai = models.CharField(max_length=15, unique=True,)
    NGUOIDUNG_TYPE = (
        ('khach_hang', 'Khách hàng'),
        ('nhan_vien', 'Nhân viên'),
    )
    loai_nguoi_dung = models.CharField(max_length=50, choices=NGUOIDUNG_TYPE, default='khach_hang')
    VAI_TRO = (
        ('customer', 'Khách hàng'),
        ('waiter', 'Phục vụ'),
        ('manager', 'Quản lý'),
        ('chef', 'Đầu bếp'),
        ('cashier', 'Thu ngân'),
    )
    CA_LAM = (
        ('sang', 'Ca sáng (8:00-14:00)'),
        ('chieu', 'Ca chiều (14:00-20:00)'),
        ('dem', 'Ca đêm (20:00-24:00)'),
    )
    chuc_vu = models.CharField(max_length=50, choices=VAI_TRO, default='customer')
    ca_lam = models.CharField(max_length=20, choices=CA_LAM, null=True, blank=True)
    dang_lam_viec = models.BooleanField(default=False, help_text="Nhân viên có đang trong ca làm việc")
    
    def __str__(self):
        return f"{self.ho_ten} - {self.loai_nguoi_dung}"


class FCMDevice(models.Model):
    user = models.ForeignKey(NguoiDung, on_delete=models.CASCADE, null=True, blank=True)
    token = models.CharField(max_length=255, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)


class KhachVangLai(models.Model):
    ho_ten = models.CharField(max_length=100)
    so_dien_thoai = models.CharField(max_length=15, unique=True)

    def __str__(self):
        return self.ho_ten


# Bàn ăn
class BanAn(models.Model):
    so_ban = models.IntegerField(unique=True)
    suc_chua = models.IntegerField()
    KHU_VUC = (
        ('inside', 'Trong nhà'),
        ('outside', 'Ngoài trời'),
        ('private-room', 'VIP'),
    )
    khu_vuc = models.CharField(max_length=50, choices=KHU_VUC, default='inside')

    def __str__(self):
        return f"Bàn {self.so_ban} (tối đa {self.suc_chua} người)"


#Danh mục
class DanhMuc(models.Model):
    ten_danh_muc = models.CharField(max_length=100)

    def __str__(self):
        return self.ten_danh_muc


# Món ăn
class MonAn(models.Model):
    ten_mon = models.CharField(max_length=100)
    gia = models.DecimalField(max_digits=10, decimal_places=2)
    mo_ta = models.TextField(blank=True, null=True)
    danh_muc = models.ForeignKey(DanhMuc, on_delete=models.CASCADE, related_name='mon_an', null=True, blank=True)
    available = models.BooleanField(default=True, help_text="Có sẵn để gọi món")
    hinh_anh = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return f"{self.ten_mon} - {self.gia} VND"


# Đơn đặt bàn
class DonHang(models.Model):
    khach_hang = models.ForeignKey(NguoiDung, on_delete=models.CASCADE, null=True, blank=True, related_name='reservations')
    khach_vang_lai = models.ForeignKey(KhachVangLai, on_delete=models.CASCADE, null=True, blank=True, related_name='reservations')
    ban_an = models.ForeignKey(BanAn, on_delete=models.SET_NULL, null=True, blank=True)
    STATUS_CHOICES = (
        ('pending', 'Chờ xác nhận'),
        ('confirmed', 'Đã xác nhận'),
        ('completed', 'Đã hoàn thành'),
        ('canceled', 'Đã hủy'),
    )
    trang_thai = models.CharField(max_length=50, choices=STATUS_CHOICES)
    ngay_dat = models.DateTimeField()

    def __str__(self):
        return f"Đơn #{self.id} - {self.khach_hang.ho_ten}"


# Chi tiết đơn hàng (món ăn trong đơn)
class Order(models.Model):
    ban_an = models.ForeignKey(BanAn, on_delete=models.CASCADE, null=True, blank=True)
    khach_hang = models.ForeignKey(NguoiDung, on_delete=models.CASCADE, related_name='orders', null=True, blank=True)
    khach_vang_lai = models.ForeignKey(KhachVangLai, on_delete=models.SET_NULL, null=True, blank=True, related_name='orders')
    nhan_vien = models.ForeignKey(NguoiDung, on_delete=models.SET_NULL, null=True, blank=True, related_name='orders_handled')
    order_time = models.DateTimeField(auto_now_add=True)
    LOAI_ORDER = (
        ('dine_in', 'Ăn tại chỗ'),
        ('takeaway', 'Mang về'),
    )
    loai_order = models.CharField(max_length=20, choices=LOAI_ORDER, default='dine_in')
    ORDER_STATUS = (
        ('pending', 'Chờ xác nhận'),
        ('confirmed', 'Đã xác nhận'),
        ('cooking', 'Đang nấu'),
        ('ready', 'Sẵn sàng'),
        ('completed', 'Hoàn thành'),
        ('canceled', 'Đã hủy'),
    )
    trang_thai = models.CharField(max_length=20, choices=ORDER_STATUS, default='pending')
    thoi_gian_khach_lay =models.DateTimeField(null=True)
    thoi_gian_lay = models.IntegerField(null=True, blank=True, help_text="Thời gian ước tính lấy món (phút)")
    thoi_gian_san_sang = models.DateTimeField(null=True, blank=True, help_text="Thời gian món sẵn sàng")
    
    # Phương thức giao hàng cho đơn takeaway
    PHUONG_THUC_GIAO_HANG = (
        ('Tự đến lấy', 'Tự đến lấy'),
        ('Giao hàng tận nơi', 'Giao hàng tận nơi'),
    )
    phuong_thuc_giao_hang = models.CharField(
        max_length=20, 
        choices=PHUONG_THUC_GIAO_HANG, 
        null=True, 
        blank=True,
        help_text="Phương thức giao hàng (chỉ áp dụng cho đơn takeaway)"
    )
    dia_chi_giao_hang = models.TextField(
        blank=True, 
        null=True,
        help_text="Địa chỉ giao hàng (chỉ áp dụng khi chọn giao hàng tận nơi)"
    )
    
    ghi_chu = models.TextField(blank=True, null=True)
    latitude = models.DecimalField(max_digits=16, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=16, decimal_places=6, null=True, blank=True)

    def __str__(self):
        if self.loai_order == 'takeaway':
            return f'Takeaway Order #{self.id}'
        return f'Order #{self.id} - Bàn {self.ban_an.so_ban if self.ban_an else "N/A"}'
    
    def get_restaurant_coords(self):
        """Return (latitude, longitude) for restaurant from AboutUs (keys 'latitude' and 'longitude').

        Returns (float, float) or (None, None) if values are missing or invalid.
        """
        try:
            lat_entry = AboutUs.objects.get(key='latitude')
            lng_entry = AboutUs.objects.get(key='longitude')
            lat = lat_entry.noi_dung
            lng = lng_entry.noi_dung
            return float(lat), float(lng)
        except (AboutUs.DoesNotExist, ValueError, TypeError):
            return None, None

    def calculate_distance_km(self):
        """Calculate haversine distance (in kilometers) between restaurant coords (AboutUs) and this Order's coords.

        Returns float (km) or None if coordinates are missing/invalid.
        """
        if self.latitude is None or self.longitude is None:
            return None

        rest_lat, rest_lng = self.get_restaurant_coords()
        if rest_lat is None or rest_lng is None:
            return None

        # Haversine formula
        R = 6371.0  # Earth radius in kilometers
        lat1 = math.radians(float(rest_lat))
        lon1 = math.radians(float(rest_lng))
        lat2 = math.radians(float(self.latitude))
        lon2 = math.radians(float(self.longitude))

        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

    def calculate_shipping_fee(self):
        """Calculate shipping fee for delivery orders.

        Shipping fee per km is stored in AboutUs with key 'shipping_fee' (in numeric form in `noi_dung`).
        Returns a Decimal rounded to 2 decimal places, Decimal('0.00') when not applicable, or None if data missing/invalid.
        """
        
        # Only apply when delivery method is "Giao hàng tận nơi"
        if not self.phuong_thuc_giao_hang or self.phuong_thuc_giao_hang != 'Giao hàng tận nơi':
            print("Shipping fee not applicable")
            return Decimal('0.00')

        distance = self.calculate_distance_km()
        if distance is None:
            return None

        try:
            fee_entry = AboutUs.objects.get(key='shipping_fee')
            fee_per_km = Decimal(str(fee_entry.noi_dung))
            print(f"Fee per km: {fee_per_km}, Distance: {distance}")
        except (AboutUs.DoesNotExist, InvalidOperation, TypeError, ValueError):
            return None

        fee = fee_per_km * Decimal(str(distance))
        # round to 2 decimal places
        return fee.quantize(Decimal('0.01'))
    

class ChiTietOrder(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    mon_an = models.ForeignKey(MonAn, on_delete=models.CASCADE)
    so_luong = models.IntegerField()
    gia = models.IntegerField()

    def __str__(self):
        return f"{self.so_luong} x {self.mon_an.ten_mon} (Order #{self.order.id})"


class HoaDon(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    tong_tien = models.DecimalField(max_digits=10, decimal_places=2)
    phi_giao_hang = models.DecimalField(max_digits=10, decimal_places=2, default=0, help_text="Phí giao hàng (nếu có)")
    ngay_tao = models.DateTimeField(auto_now_add=True)
    payment_method = models.CharField(max_length=50, choices=(('cash', 'Tiền mặt'), ('card', 'Thẻ')))

    def __str__(self):
        return f"Hóa đơn #{self.id} - Order #{self.order.id}"


# Kho nguyên liệu
class NguyenLieu(models.Model):
    ten_nguyen_lieu = models.CharField(max_length=100)
    so_luong = models.FloatField()
    don_vi = models.CharField(max_length=50)  # Ví dụ: kg, lít, cái
    threshold = models.FloatField(default=0, help_text="Mức cảnh báo khi số lượng dưới mức này")

    def __str__(self):
        return f"{self.ten_nguyen_lieu} - {self.so_luong} {self.don_vi}"


# Log thay đổi nguyên liệu
class NguyenLieuLog(models.Model):
    nguyen_lieu = models.ForeignKey(NguyenLieu, on_delete=models.CASCADE)
    so_luong_thay_doi = models.FloatField()
    loai = models.CharField(max_length=50, choices=(('nhap', 'Nhập kho'), ('su_dung', 'Sử dụng'), ('huy', 'Hủy bỏ')))

    def __str__(self):
        return f"Log #{self.id} - {self.nguyen_lieu.ten_nguyen_lieu}"


class AboutUs(models.Model):
    key = models.CharField(max_length=50, unique=True)
    noi_dung = models.TextField()
    public = models.BooleanField(default=True, help_text="Có hiển thị nội dung này trên ứng dụng không")
    content_type = models.CharField(max_length=255, choices=(('text', 'Văn bản'), ('image', 'Hình ảnh'), ('html', 'HTML'), ('json', 'JSON')), default='text')

    def __str__(self):
        return f"About Us Content - {self.key}"


class ChatMessage(models.Model):
    sender = models.ForeignKey(NguoiDung, on_delete=models.CASCADE, related_name='sent_messages')
    receiver = models.ForeignKey(NguoiDung, on_delete=models.CASCADE, related_name='received_messages')
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
