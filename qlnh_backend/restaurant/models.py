from django.db import models

# Khách hàng
class KhachHang(models.Model):
    ho_ten = models.CharField(max_length=100)
    so_dien_thoai = models.CharField(max_length=15, unique=True)
    email = models.EmailField(blank=True, null=True)
    dia_chi = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.ho_ten


# Nhân viên
class NhanVien(models.Model):
    ho_ten = models.CharField(max_length=100)
    chuc_vu = models.CharField(max_length=50)
    so_dien_thoai = models.CharField(max_length=15, unique=True)

    def __str__(self):
        return f"{self.ho_ten} - {self.chuc_vu}"


# Bàn ăn
class BanAn(models.Model):
    so_ban = models.IntegerField(unique=True)
    suc_chua = models.IntegerField()

    def __str__(self):
        return f"Bàn {self.so_ban} (tối đa {self.suc_chua} người)"


# Món ăn
class MonAn(models.Model):
    ten_mon = models.CharField(max_length=100)
    gia = models.DecimalField(max_digits=10, decimal_places=2)
    mo_ta = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.ten_mon} - {self.gia} VND"


# Đơn hàng
class DonHang(models.Model):
    khach_hang = models.ForeignKey(KhachHang, on_delete=models.CASCADE)
    ban_an = models.ForeignKey(BanAn, on_delete=models.SET_NULL, null=True, blank=True)
    nhan_vien = models.ForeignKey(NhanVien, on_delete=models.SET_NULL, null=True, blank=True)
    ngay_dat = models.DateTimeField(auto_now_add=True)
    tong_tien = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    def __str__(self):
        return f"Đơn #{self.id} - {self.khach_hang.ho_ten}"


# Chi tiết đơn hàng (món ăn trong đơn)
class ChiTietDonHang(models.Model):
    don_hang = models.ForeignKey(DonHang, on_delete=models.CASCADE, related_name="chi_tiet")
    mon_an = models.ForeignKey(MonAn, on_delete=models.CASCADE)
    so_luong = models.IntegerField()
    thanh_tien = models.DecimalField(max_digits=12, decimal_places=2)

    def __str__(self):
        return f"{self.so_luong} x {self.mon_an.ten_mon} (ĐH {self.don_hang.id})"

