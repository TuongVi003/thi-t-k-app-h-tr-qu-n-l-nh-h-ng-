from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import MonAn , DanhMuc, BanAn, DonHang, NguoiDung, Order, ChiTietOrder


class NguoiDungAdmin(UserAdmin):
    list_display = ('username', 'ho_ten', 'so_dien_thoai', 'loai_nguoi_dung', 'dang_lam_viec')
    fieldsets = UserAdmin.fieldsets + (
        ('Thông tin bổ sung', {'fields': ('ho_ten', 'so_dien_thoai', 'loai_nguoi_dung', 'chuc_vu', 'ca_lam')}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Thông tin bổ sung', {'fields': ('ho_ten', 'so_dien_thoai', 'loai_nguoi_dung', 'chuc_vu', 'ca_lam')}),
    )


class MonAnAdmin(admin.ModelAdmin):
    list_display = ('ten_mon', 'gia', 'danh_muc', 'available', 'hinh_anh')
    list_filter = ('danh_muc', 'available')
    search_fields = ('ten_mon',)
    readonly_fields = ('image_preview', 'hinh_anh')
    
    def get_form(self, request, obj=None, **kwargs):
        from django import forms
        
        class MonAnAdminForm(forms.ModelForm):
            image_upload = forms.FileField(
                required=False, 
                label='Upload ảnh mới',
                help_text='Chọn ảnh để upload (JPG, PNG, tối đa 5MB)'
            )
            
            class Meta:
                model = MonAn
                fields = '__all__'
        
        kwargs['form'] = MonAnAdminForm
        return super().get_form(request, obj, **kwargs)
    
    def image_preview(self, obj):
        if obj.hinh_anh:
            from django.utils.html import format_html
            return format_html(
                '<img src="/images/{}" width="200" height="200" style="object-fit: cover;" /><br>Đường dẫn: {}',
                obj.hinh_anh, obj.hinh_anh
            )
        return "Chưa có ảnh"
    image_preview.short_description = "Xem trước ảnh"
    
    def save_model(self, request, obj, form, change):
        # Xử lý upload ảnh
        image_upload = form.cleaned_data.get('image_upload')
        
        if image_upload:
            # Import các thư viện cần thiết
            import os
            from django.core.files.storage import default_storage
            from django.conf import settings
            
            # Tạo tên file unique
            file_extension = os.path.splitext(image_upload.name)[1]
            file_name = f"mon_an_{obj.id if obj.id else 'new'}_{image_upload.name}"
            
            # Xóa ảnh cũ nếu có
            if obj.hinh_anh and default_storage.exists(obj.hinh_anh):
                default_storage.delete(obj.hinh_anh)
            
            # Lưu ảnh mới
            file_path = default_storage.save(file_name, image_upload)
            obj.hinh_anh = file_path
        
        super().save_model(request, obj, form, change)


class DonHangAdmin(admin.ModelAdmin):
    list_display = ('id', 'khach_hang', 'trang_thai', 'ngay_dat')


class OrderAdmin(admin.ModelAdmin):
    list_display = ('khach_hang', 'khach_vang_lai', 'nhan_vien', 'order_time', 'trang_thai', 'thoi_gian_lay', 'thoi_gian_san_sang')


admin.site.register(NguoiDung, NguoiDungAdmin)
admin.site.register(MonAn, MonAnAdmin)
admin.site.register(DanhMuc)
admin.site.register(BanAn)
admin.site.register(DonHang, DonHangAdmin)
admin.site.register(Order, OrderAdmin)
