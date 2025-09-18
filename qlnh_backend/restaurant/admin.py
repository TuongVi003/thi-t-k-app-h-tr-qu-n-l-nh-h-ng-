from django.contrib import admin
from .models import MonAn, KhachHang, DanhMuc, NhanVien, BanAn, DonHang

# Register your models here.
admin.site.register(MonAn)
admin.site.register(KhachHang)
admin.site.register(DanhMuc)
admin.site.register(NhanVien)
admin.site.register(BanAn)
admin.site.register(DonHang)
