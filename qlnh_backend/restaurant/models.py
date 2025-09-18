from django.db import models

# Khách hàng
class KhachHang(models.Model):
    ho_ten = models.CharField(max_length=100)
    so_dien_thoai = models.CharField(max_length=15, unique=True)

    def __str__(self):
        return self.ho_ten


# Nhân viên
class NhanVien(models.Model):
    so_dien_thoai = models.CharField(max_length=15, unique=True)
    mat_khau = models.CharField(max_length=255)
    ho_ten = models.CharField(max_length=100)
    VAI_TRO = (
        ('waiter', 'Phục vụ'),
        ('manager', 'Quản lý'),
        ('chef', 'Đầu bếp'),
        ('cashier', 'Thu ngân'),
    )
    chuc_vu = models.CharField(max_length=50, choices=VAI_TRO)
    

    def __str__(self):
        return f"{self.ho_ten} - {self.chuc_vu}"


# Bàn ăn
class BanAn(models.Model):
    so_ban = models.IntegerField(unique=True)
    suc_chua = models.IntegerField()

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
    danh_muc = models.ForeignKey(DanhMuc, on_delete=models.CASCADE),
    available = models.BooleanField(default=True, help_text="Có sẵn để gọi món")

    def __str__(self):
        return f"{self.ten_mon} - {self.gia} VND"


# Đơn đặt bàn
class DonHang(models.Model):
    khach_hang = models.ForeignKey(KhachHang, on_delete=models.CASCADE)
    ban_an = models.ForeignKey(BanAn, on_delete=models.SET_NULL, null=True, blank=True)
    STATUS_CHOICES = (
        ('pending', 'Chờ xác nhận'),
        ('confirmed', 'Đã xác nhận'),
        ('canceled', 'Đã hủy'),
    )
    trang_thai = models.CharField(max_length=50, choices=STATUS_CHOICES)
    ngay_dat = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Đơn #{self.id} - {self.khach_hang.ho_ten}"


# Chi tiết đơn hàng (món ăn trong đơn)
class Order(models.Model):
    ban_an = models.ForeignKey(BanAn, on_delete=models.CASCADE)
    khach_hang = models.ForeignKey(KhachHang, on_delete=models.CASCADE)
    nhan_vien = models.ForeignKey(NhanVien, on_delete=models.SET_NULL, null=True, blank=True)
    order_time = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Order #{self.id} - Bàn {self.ban_an.so_ban}'
    

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
