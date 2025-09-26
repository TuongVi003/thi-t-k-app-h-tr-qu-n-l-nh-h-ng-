from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import MonAn , DanhMuc, BanAn, DonHang, NguoiDung


class NguoiDungAdmin(UserAdmin):
    list_display = ('username', 'ho_ten', 'so_dien_thoai', 'loai_nguoi_dung',)
    fieldsets = UserAdmin.fieldsets + (
        ('Thông tin bổ sung', {'fields': ('ho_ten', 'so_dien_thoai', 'loai_nguoi_dung', 'chuc_vu')}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Thông tin bổ sung', {'fields': ('ho_ten', 'so_dien_thoai', 'loai_nguoi_dung', 'chuc_vu')}),
    )


admin.site.register(NguoiDung, NguoiDungAdmin)
admin.site.register(MonAn)
admin.site.register(DanhMuc)
admin.site.register(BanAn)
admin.site.register(DonHang)
