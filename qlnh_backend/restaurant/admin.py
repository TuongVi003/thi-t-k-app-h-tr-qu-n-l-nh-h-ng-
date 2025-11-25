from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import MonAn , DanhMuc, BanAn, DonHang, NguoiDung, Order, ChiTietOrder, \
    AboutUs, HoaDon, Conversation, ChatMessage, NguyenLieu, KhachVangLai, KhuyenMai
from django.urls import path
from django.shortcuts import render
from django.db.models import Sum, Count, Avg, Q, F
from django.db.models.functions import TruncDate, TruncMonth
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal


class NguoiDungAdmin(UserAdmin):
    list_display = ('username', 'ho_ten', 'so_dien_thoai', 'loai_nguoi_dung', 'dang_lam_viec')
    list_filter = ('loai_nguoi_dung', 'dang_lam_viec', )
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


class HoaDonAdmin(admin.ModelAdmin):
    list_display = ('order', 'tong_tien', 'formatted_phi_giao_hang', 'payment_method', )


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

class ChatMessageInline(admin.TabularInline):
    """Inline để hiển thị messages trong Conversation"""
    model = ChatMessage
    extra = 0
    readonly_fields = ('nguoi_goi', 'noi_dung', 'thoi_gian', 'nguoi_goi_display_name')
    fields = ('nguoi_goi_display_name', 'noi_dung', 'thoi_gian')
    can_delete = False
    
    def nguoi_goi_display_name(self, obj):
        return obj.nguoi_goi_display() if obj.id else '-'
    nguoi_goi_display_name.short_description = 'Người gửi'


class ConversationAdmin(admin.ModelAdmin):
    """Admin cho Conversation"""
    list_display = ('id', 'customer_name', 'is_staff_group', 'message_count', 'last_message_at', 'created_at')
    list_filter = ('is_staff_group', 'created_at')
    search_fields = ('customer__ho_ten', 'customer__username', 'customer__so_dien_thoai')
    readonly_fields = ('created_at', 'last_message_at', 'message_count')
    inlines = [ChatMessageInline]
    
    def customer_name(self, obj):
        return obj.customer.ho_ten if obj.customer else '-'
    customer_name.short_description = 'Khách hàng'
    customer_name.admin_order_field = 'customer__ho_ten'
    
    def message_count(self, obj):
        return obj.messages.count()
    message_count.short_description = 'Số tin nhắn'


class ChatMessageAdmin(admin.ModelAdmin):
    """Admin cho ChatMessage"""
    list_display = ('id', 'conversation_id', 'nguoi_goi_display_name', 'noi_dung_preview', 'thoi_gian')
    list_filter = ('thoi_gian', 'conversation__is_staff_group')
    search_fields = ('noi_dung', 'nguoi_goi__ho_ten', 'nguoi_goi__username')
    readonly_fields = ('thoi_gian', 'nguoi_goi_display_name')
    date_hierarchy = 'thoi_gian'
    
    def conversation_id(self, obj):
        return f"#{obj.conversation.id}" if obj.conversation else '-'
    conversation_id.short_description = 'Conversation'
    conversation_id.admin_order_field = 'conversation'
    
    def nguoi_goi_display_name(self, obj):
        return obj.nguoi_goi_display()
    nguoi_goi_display_name.short_description = 'Người gửi'
    
    def noi_dung_preview(self, obj):
        return obj.noi_dung[:50] + '...' if len(obj.noi_dung) > 50 else obj.noi_dung
    noi_dung_preview.short_description = 'Nội dung'


class StatisticsAdminSite(admin.AdminSite):
    """Custom Admin Site với trang thống kê"""
    
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('statistics/', self.admin_view(self.statistics_view), name='statistics'),
        ]
        return custom_urls + urls
    
    def statistics_view(self, request):
        """View hiển thị trang thống kê tổng quan"""
        
        # Thời gian
        today = timezone.now()
        last_30_days = today - timedelta(days=30)
        last_7_days = today - timedelta(days=7)
        
        # === THỐNG KÊ DOANH THU ===
        total_revenue = HoaDon.objects.aggregate(total=Sum('tong_tien'))['total'] or Decimal('0')
        revenue_today = HoaDon.objects.filter(ngay_tao__date=today.date()).aggregate(total=Sum('tong_tien'))['total'] or Decimal('0')
        revenue_30days = HoaDon.objects.filter(ngay_tao__gte=last_30_days).aggregate(total=Sum('tong_tien'))['total'] or Decimal('0')
        
        # Doanh thu theo ngày (30 ngày gần nhất)
        revenue_by_day = HoaDon.objects.filter(ngay_tao__gte=last_30_days)\
            .annotate(date=TruncDate('ngay_tao'))\
            .values('date')\
            .annotate(total=Sum('tong_tien'))\
            .order_by('date')
        
        # Doanh thu theo tháng (12 tháng gần nhất)
        last_12_months = today - timedelta(days=365)
        revenue_by_month = HoaDon.objects.filter(ngay_tao__gte=last_12_months)\
            .annotate(month=TruncMonth('ngay_tao'))\
            .values('month')\
            .annotate(total=Sum('tong_tien'))\
            .order_by('month')
        
        # Phí giao hàng
        total_shipping_fee = HoaDon.objects.aggregate(total=Sum('phi_giao_hang'))['total'] or Decimal('0')
        
        # === THỐNG KÊ ĐỎN HÀNG ===
        total_orders = Order.objects.count()
        orders_today = Order.objects.filter(order_time__date=today.date()).count()
        orders_30days = Order.objects.filter(order_time__gte=last_30_days).count()
        
        # Đơn hàng theo trạng thái
        orders_by_status = Order.objects.values('trang_thai').annotate(count=Count('id'))
        
        # Đơn hàng theo loại
        orders_by_type = Order.objects.values('loai_order').annotate(count=Count('id'))
        
        # Đơn hàng theo phương thức giao hàng
        orders_by_delivery = Order.objects.filter(loai_order='takeaway')\
            .values('phuong_thuc_giao_hang')\
            .annotate(count=Count('id'))
        
        # Thời gian chuẩn bị trung bình
        avg_prep_time = Order.objects.filter(thoi_gian_lay__isnull=False)\
            .aggregate(avg=Avg('thoi_gian_lay'))['avg']
        
        # === THỐNG KÊ MÓN ĂN ===
        total_dishes = MonAn.objects.count()
        available_dishes = MonAn.objects.filter(available=True).count()
        unavailable_dishes = MonAn.objects.filter(available=False).count()
        
        # Món bán chạy nhất
        top_dishes = ChiTietOrder.objects.values('mon_an__ten_mon')\
            .annotate(total_sold=Sum('so_luong'), revenue=Sum(F('so_luong') * F('gia')))\
            .order_by('-total_sold')[:10]
        
        # Món bán chạy 7 ngày gần nhất
        top_dishes_7days_raw = ChiTietOrder.objects.filter(order__order_time__gte=last_7_days)\
            .values('mon_an__ten_mon')\
            .annotate(total_sold=Sum('so_luong'))\
            .order_by('-total_sold')[:5]
        
        # Tính phần trăm cho progress bar
        top_dishes_7days = list(top_dishes_7days_raw)
        if top_dishes_7days:
            max_sold = top_dishes_7days[0]['total_sold']
            for dish in top_dishes_7days:
                dish['percentage'] = int((dish['total_sold'] / max_sold * 100)) if max_sold > 0 else 0
        
        # Danh mục có nhiều món nhất
        categories_stats = DanhMuc.objects.annotate(dish_count=Count('mon_an')).order_by('-dish_count')
        
        # === THỐNG KÊ BÀN ĂN ===
        total_tables = BanAn.objects.count()
        
        # Bàn theo khu vực
        tables_by_area = BanAn.objects.values('khu_vuc').annotate(count=Count('id'))
        
        # Tổng sức chứa
        total_capacity = BanAn.objects.aggregate(total=Sum('suc_chua'))['total'] or 0
        
        # Bàn đang có đơn (active)
        active_tables = Order.objects.filter(
            trang_thai__in=['pending', 'confirmed', 'cooking', 'ready'],
            ban_an__isnull=False
        ).values_list('ban_an_id', flat=True).distinct().count()
        
        # === THỐNG KÊ NHÂN VIÊN ===
        total_staff = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien').count()
        staff_working = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien', dang_lam_viec=True).count()
        
        # Nhân viên theo chức vụ
        staff_by_role = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien')\
            .values('chuc_vu')\
            .annotate(count=Count('id'))
        
        # Nhân viên theo ca làm
        staff_by_shift = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien')\
            .values('ca_lam')\
            .annotate(count=Count('id'))
        
        # Top nhân viên xử lý nhiều đơn nhất
        top_staff = Order.objects.filter(nhan_vien__isnull=False)\
            .values('nhan_vien__ho_ten')\
            .annotate(order_count=Count('id'))\
            .order_by('-order_count')[:10]
        
        # === THỐNG KÊ KHÁCH HÀNG ===
        total_customers = NguoiDung.objects.filter(loai_nguoi_dung='khach_hang').count()
        total_khach_vang_lai = KhachVangLai.objects.count()
        
        # Khách hàng có đơn hàng
        customers_with_orders = Order.objects.filter(khach_hang__isnull=False)\
            .values('khach_hang').distinct().count()
        
        # Top khách hàng
        top_customers = Order.objects.filter(khach_hang__isnull=False)\
            .values('khach_hang__ho_ten', 'khach_hang__so_dien_thoai')\
            .annotate(order_count=Count('id'))\
            .order_by('-order_count')[:10]
        
        # === THỐNG KÊ NGUYÊN LIỆU ===
        total_ingredients = NguyenLieu.objects.count()
        
        # Nguyên liệu dưới ngưỡng cảnh báo
        low_stock = NguyenLieu.objects.filter(
            Q(so_luong__lte=F('threshold')) & Q(threshold__gt=0)
        ).count()
        
        # Danh sách nguyên liệu cần nhập
        ingredients_need_restock = NguyenLieu.objects.filter(
            Q(so_luong__lte=F('threshold')) & Q(threshold__gt=0)
        ).order_by('so_luong')[:10]
        
        # === THỐNG KÊ CHAT ===
        total_conversations = Conversation.objects.count()
        total_messages = ChatMessage.objects.count()
        messages_today = ChatMessage.objects.filter(thoi_gian__date=today.date()).count()
        messages_7days = ChatMessage.objects.filter(thoi_gian__gte=last_7_days).count()
        
        # Conversation hoạt động gần đây
        recent_conversations = Conversation.objects.filter(last_message_at__isnull=False)\
            .order_by('-last_message_at')[:5]
        
        # === THỐNG KÊ ĐẶT BÀN ===
        total_reservations = DonHang.objects.count()
        reservations_by_status = DonHang.objects.values('trang_thai').annotate(count=Count('id'))
        
        context = {
            'site_title': 'Thống kê Nhà hàng',
            'site_header': 'Thống kê Tổng quan',
            
            # Doanh thu
            'total_revenue': total_revenue,
            'revenue_today': revenue_today,
            'revenue_30days': revenue_30days,
            'revenue_by_day': list(revenue_by_day),
            'revenue_by_month': list(revenue_by_month),
            'total_shipping_fee': total_shipping_fee,
            
            # Đơn hàng
            'total_orders': total_orders,
            'orders_today': orders_today,
            'orders_30days': orders_30days,
            'orders_by_status': list(orders_by_status),
            'orders_by_type': list(orders_by_type),
            'orders_by_delivery': list(orders_by_delivery),
            'avg_prep_time': avg_prep_time,
            
            # Món ăn
            'total_dishes': total_dishes,
            'available_dishes': available_dishes,
            'unavailable_dishes': unavailable_dishes,
            'top_dishes': list(top_dishes),
            'top_dishes_7days': list(top_dishes_7days),
            'categories_stats': categories_stats,
            
            # Bàn ăn
            'total_tables': total_tables,
            'tables_by_area': list(tables_by_area),
            'total_capacity': total_capacity,
            'active_tables': active_tables,
            
            # Nhân viên
            'total_staff': total_staff,
            'staff_working': staff_working,
            'staff_by_role': list(staff_by_role),
            'staff_by_shift': list(staff_by_shift),
            'top_staff': list(top_staff),
            
            # Khách hàng
            'total_customers': total_customers,
            'total_khach_vang_lai': total_khach_vang_lai,
            'customers_with_orders': customers_with_orders,
            'top_customers': list(top_customers),
            
            # Nguyên liệu
            'total_ingredients': total_ingredients,
            'low_stock': low_stock,
            'ingredients_need_restock': ingredients_need_restock,
            
            # Chat
            'total_conversations': total_conversations,
            'total_messages': total_messages,
            'messages_today': messages_today,
            'messages_7days': messages_7days,
            'recent_conversations': recent_conversations,
            
            # Đặt bàn
            'total_reservations': total_reservations,
            'reservations_by_status': list(reservations_by_status),
        }
        
        return render(request, 'admin/statistics.html', context)
    
    def index(self, request, extra_context=None):
        """Override index để thêm link tới trang thống kê"""
        extra_context = extra_context or {}
        extra_context['show_statistics_link'] = True
        return super().index(request, extra_context)


class KhuyenMaiAdmin(admin.ModelAdmin):
    list_display = ('ten_khuyen_mai', 'loai_giam_gia', 'gia_tri', 'ngay_bat_dau', 'ngay_ket_thuc', 'active', 'banner_image')
    list_filter = ('loai_giam_gia', 'active', 'ngay_bat_dau', 'ngay_ket_thuc')
    search_fields = ('ten_khuyen_mai', 'mo_ta')
    readonly_fields = ('image_preview', 'banner_image')
    
    def get_form(self, request, obj=None, **kwargs):
        from django import forms
        
        class KhuyenMaiAdminForm(forms.ModelForm):
            image_upload = forms.FileField(
                required=False,
                label='Upload ảnh banner',
                help_text='Chọn ảnh để upload (JPG, PNG, tối đa 5MB)'
            )
            
            class Meta:
                model = KhuyenMai
                fields = '__all__'
        
        kwargs['form'] = KhuyenMaiAdminForm
        return super().get_form(request, obj, **kwargs)
    
    def image_preview(self, obj):
        if obj.banner_image:
            from django.utils.html import format_html
            return format_html(
                '<img src="/images/{}" width="200" height="200" style="object-fit: cover;" /><br>Đường dẫn: {}',
                obj.banner_image, obj.banner_image
            )
        return "Chưa có ảnh"
    image_preview.short_description = "Xem trước ảnh banner"
    
    def save_model(self, request, obj, form, change):
        # Xử lý upload ảnh
        image_upload = form.cleaned_data.get('image_upload')
        
        if image_upload:
            # Import các thư viện cần thiết
            import os
            from django.core.files.storage import default_storage
            
            # Tạo tên file unique
            file_extension = os.path.splitext(image_upload.name)[1]
            file_name = f"khuyen_mai_{obj.id if obj.id else 'new'}_{image_upload.name}"
            
            # Xóa ảnh cũ nếu có
            if obj.banner_image and default_storage.exists(obj.banner_image):
                default_storage.delete(obj.banner_image)
            
            # Lưu ảnh mới
            file_path = default_storage.save(file_name, image_upload)
            obj.banner_image = file_path
        
        super().save_model(request, obj, form, change)


# Sử dụng custom admin site
admin_site = StatisticsAdminSite(name='admin')
admin.site = admin_site

admin.site.register(NguoiDung, NguoiDungAdmin)
admin.site.register(MonAn, MonAnAdmin)
admin.site.register(DanhMuc)
admin.site.register(BanAn)
admin.site.register(DonHang, DonHangAdmin)
admin.site.register(Order, OrderAdmin)
admin.site.register(AboutUs, AboutUsAdmin)
admin.site.register(HoaDon, HoaDonAdmin)
admin.site.register(Conversation, ConversationAdmin)
# admin.site.register(ChatMessage, ChatMessageAdmin)
admin.site.register(KhuyenMai, KhuyenMaiAdmin)
