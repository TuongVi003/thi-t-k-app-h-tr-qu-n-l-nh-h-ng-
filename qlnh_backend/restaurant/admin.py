from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import MonAn , DanhMuc, BanAn, DonHang, NguoiDung, Order, ChiTietOrder, \
    AboutUs


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

class AboutUsAdmin(admin.ModelAdmin):
    list_display = ('key', 'noi_dung', 'public', 'content_type')
    readonly_fields = ('image_preview', 'content_type', 'key')

    def get_form(self, request, obj=None, **kwargs):
        from django import forms

        class AboutUsAdminForm(forms.ModelForm):
            image_upload = forms.FileField(
                required=False,
                label='Upload ảnh (dành cho content_type=image)',
                help_text='Chọn ảnh để upload (JPG, PNG, tối đa 5MB)'
            )

            # hidden field to expose raw content_type value to JS when content_type is readonly
            content_type_raw = forms.CharField(widget=forms.HiddenInput(), required=False)

            def __init__(self, *args, **kwargs):
                super().__init__(*args, **kwargs)
                # set initial value for content_type_raw from instance when editing
                if getattr(self, 'instance', None) and getattr(self.instance, 'content_type', None):
                    self.fields['content_type_raw'].initial = getattr(self.instance, 'content_type')

            def clean(self):
                cleaned = super().clean()
                image = cleaned.get('image_upload')
                content_type = cleaned.get('content_type') or getattr(self.instance, 'content_type', None)

                # If an image is uploaded, content_type must be 'image'
                if image and content_type != 'image':
                    from django.core.exceptions import ValidationError
                    raise ValidationError({'image_upload': 'Chỉ có thể upload ảnh khi content_type là "image".'})

                return cleaned

            class Meta:
                model = AboutUs
                fields = '__all__'

        kwargs['form'] = AboutUsAdminForm
        return super().get_form(request, obj, **kwargs)

    def image_preview(self, obj):
        # Hiển thị preview chỉ khi content_type là image và noi_dung chứa path ảnh
        if not obj or obj.content_type != 'image' or not obj.noi_dung:
            return "-"

        try:
            from django.utils.html import format_html
            from django.core.files.storage import default_storage

            # Try to get a URL for the stored file; fallback to the raw path
            try:
                url = default_storage.url(obj.noi_dung)
            except Exception:
                url = f"/images/{obj.noi_dung}"

            return format_html('<img src="{}" width="200" style="object-fit: cover;"/><br/>Đường dẫn: {}', url, obj.noi_dung)
        except Exception:
            return obj.noi_dung
    image_preview.short_description = "Xem trước ảnh"

    def save_model(self, request, obj, form, change):
        # Xử lý upload ảnh nếu có field image_upload
        image_upload = form.cleaned_data.get('image_upload')
        content_type = form.cleaned_data.get('content_type') or getattr(obj, 'content_type', None)

        # Only process upload when content_type == 'image'
        if image_upload and content_type == 'image':
            import os
            from django.core.files.storage import default_storage

            # Tạo tên file unique
            file_extension = os.path.splitext(image_upload.name)[1]
            # Use key to create nicer filename if available
            key_part = obj.key if getattr(obj, 'key', None) else 'aboutus'
            file_name = f"aboutus_{key_part}_{image_upload.name}"

            # Xóa ảnh cũ nếu có và dường dẫn cũ trỏ tới file lưu trữ
            if obj.noi_dung and default_storage.exists(obj.noi_dung):
                try:
                    default_storage.delete(obj.noi_dung)
                except Exception:
                    # ignore delete failure
                    pass

            # Lưu ảnh mới
            file_path = default_storage.save(file_name, image_upload)
            # Lưu đường dẫn vào field noi_dung để hiển thị/đọc lại
            obj.noi_dung = file_path

        else:
            # If an image_upload was provided but content_type isn't 'image', ignore upload (clean() should have prevented this).
            pass

        super().save_model(request, obj, form, change)

    def has_add_permission(self, request):
        """Disable adding new AboutUs entries from admin; only allow editing existing ones."""
        return False

    class Media:
        js = ('restaurant/admin_aboutus.js',)

admin.site.register(NguoiDung, NguoiDungAdmin)
admin.site.register(MonAn, MonAnAdmin)
admin.site.register(DanhMuc)
admin.site.register(BanAn)
admin.site.register(DonHang, DonHangAdmin)
admin.site.register(Order, OrderAdmin)
admin.site.register(AboutUs, AboutUsAdmin)
