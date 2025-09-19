from django.contrib import admin
from .models import MonAn , DanhMuc, BanAn, DonHang, NguoiDung

# Register your models here.
admin.site.register(NguoiDung)
admin.site.register(MonAn)
admin.site.register(DanhMuc)
admin.site.register(BanAn)
admin.site.register(DonHang)
