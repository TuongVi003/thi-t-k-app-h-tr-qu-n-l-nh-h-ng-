from django.db import models
from django.contrib.auth.models import AbstractUser



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
    chuc_vu = models.CharField(max_length=50, choices=VAI_TRO, default='customer')
    
    def __str__(self):
        return f"{self.ho_ten} - {self.loai_nguoi_dung}"


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
    danh_muc = models.ForeignKey(DanhMuc, on_delete=models.CASCADE)
    available = models.BooleanField(default=True, help_text="Có sẵn để gọi món")
    hinh_anh = models.CharField(max_length=255, blank=True, null=True)

    def __str__(self):
        return f"{self.ten_mon} - {self.gia} VND"


# Đơn đặt bàn
class DonHang(models.Model):
    khach_hang = models.ForeignKey(NguoiDung, on_delete=models.CASCADE, null=True, related_name='reservations')
    khach_vang_lai = models.ForeignKey(KhachVangLai, on_delete=models.CASCADE, null=True, related_name='reservations')
    ban_an = models.ForeignKey(BanAn, on_delete=models.SET_NULL, null=True, blank=True)
    STATUS_CHOICES = (
        ('pending', 'Chờ xác nhận'),
        ('confirmed', 'Đã xác nhận'),
        ('canceled', 'Đã hủy'),
    )
    trang_thai = models.CharField(max_length=50, choices=STATUS_CHOICES)
    ngay_dat = models.DateTimeField()

    def __str__(self):
        return f"Đơn #{self.id} - {self.khach_hang.ho_ten}"


# Chi tiết đơn hàng (món ăn trong đơn)
class Order(models.Model):
    ban_an = models.ForeignKey(BanAn, on_delete=models.CASCADE)
    khach_hang = models.ForeignKey(NguoiDung, on_delete=models.CASCADE, related_name='orders', null=True)
    khach_vang_lai = models.ForeignKey(KhachVangLai, on_delete=models.SET_NULL, null=True, related_name='orders')
    nhan_vien = models.ForeignKey(NguoiDung, on_delete=models.SET_NULL, null=True, blank=True)
    order_time = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Order #{self.id} - Bàn {self.ban_an.so_ban}'
    

class ChiTietOrder(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    mon_an = models.ForeignKey(MonAn, on_delete=models.CASCADE)
    so_luong = models.IntegerField()
    gia = models.IntegerField()

    TrangThaiMonAn = (
        ('dang-doi', 'Chờ chế biến'),
        ('dang-lam', 'Đang làm'),
        ('hoan-thanh', 'Hoàn thành')
    )
    trang_thai = models.CharField(max_length=30, choices=TrangThaiMonAn, default='dang-doi')


    def __str__(self):
        return f"{self.so_luong} x {self.mon_an.ten_mon} (Order #{self.order.id})"


class HoaDon(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE)
    tong_tien = models.DecimalField(max_digits=10, decimal_places=2)
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
    mon_an = models.ForeignKey(MonAn, on_delete=models.SET_NULL, null=True, blank=True)
    loai = models.CharField(max_length=50, choices=(('nhap', 'Nhập kho'), ('su_dung', 'Sử dụng'), ('huy', 'Hủy bỏ')))

    def __str__(self):
        return f"Log #{self.id} - {self.nguyen_lieu.ten_nguyen_lieu}"
