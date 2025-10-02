from rest_framework import serializers
from rest_framework.serializers import ModelSerializer
from .models import NguoiDung, BanAn, DonHang, Order, ChiTietOrder, MonAn, DanhMuc


class UserSerializer(ModelSerializer):

    def create(self, validated_data):
        data = validated_data.copy()
        u = NguoiDung(**data)
        u.set_password(u.password)
        u.save()

        return u

    class Meta:
        model = NguoiDung
        fields = '__all__'
        extra_kwargs = {
            'password': {'write_only': True}
        }


class BanAnSerializer(ModelSerializer):
    status = serializers.SerializerMethodField()
    current_customer = serializers.SerializerMethodField()

    def get_current_customer(self, obj):
        from django.utils import timezone
        request = self.context.get('request')
        slot = request.GET.get('slot') if request else None
        
        today = timezone.now().date()
        now = timezone.now()
        
        if slot:
            # Define time slots
            slots = {
                'morning': (8, 14),
                'afternoon': (14, 20),
                'evening': (20, 24)
            }
            if slot not in slots:
                return None
            
            start_hour, end_hour = slots[slot]
            
            # Get active reservation in this slot
            reservation = DonHang.objects.filter(
                ban_an=obj, 
                trang_thai__in=['pending', 'confirmed'],
                ngay_dat__date=today,
                ngay_dat__hour__gte=start_hour,
                ngay_dat__hour__lt=end_hour if end_hour != 24 else 24
            ).first()
        else:
            # Get any active reservation from today onwards
            reservation = DonHang.objects.filter(
                ban_an=obj, 
                trang_thai__in=['pending', 'confirmed'],
                ngay_dat__date__gte=today
            ).first()
        
        if reservation:
            if reservation.khach_hang:
                return {
                    'type': 'registered',
                    'name': reservation.khach_hang.ho_ten,
                    'phone': reservation.khach_hang.so_dien_thoai
                }
            elif reservation.khach_vang_lai:
                return {
                    'type': 'guest',
                    'name': reservation.khach_vang_lai.ho_ten,
                    'phone': reservation.khach_vang_lai.so_dien_thoai
                }
        return None

    def get_status(self, obj):
        from django.utils import timezone
        request = self.context.get('request')
        slot = request.GET.get('slot') if request else None
        
        today = timezone.now().date()
        now = timezone.now()
        
        if slot:
            # Define time slots
            slots = {
                'morning': (8, 14),
                'afternoon': (14, 20),
                'evening': (20, 24)  # Evening from 20:00 to 24:00
            }
            if slot not in slots:
                return 'available'  # Invalid slot, default to available
            
            start_hour, end_hour = slots[slot]
            # For evening, if end_hour == 24, check until next day 02:00
            if end_hour == 24:
                end_time = timezone.now().replace(hour=2, minute=0, second=0, microsecond=0) + timezone.timedelta(days=1)
            else:
                end_time = now.replace(hour=end_hour, minute=0, second=0, microsecond=0)
            start_time = now.replace(hour=start_hour, minute=0, second=0, microsecond=0)
            
            # Check if table has reservations overlapping with this slot today
            active_reservations = DonHang.objects.filter(
                ban_an=obj, 
                trang_thai__in=['pending', 'confirmed'],
                ngay_dat__date=today,
                ngay_dat__hour__gte=start_hour,
                ngay_dat__hour__lt=end_hour if end_hour != 24 else 24
            ).exists()
            return 'occupied' if active_reservations else 'available'
        else:
            # Default logic: occupied if any active reservation from today onwards
            active_reservations = DonHang.objects.filter(
                ban_an=obj, 
                trang_thai__in=['pending', 'confirmed'],
                ngay_dat__date__gte=today
            ).exists()
            return 'occupied' if active_reservations else 'available'

    class Meta:
        model = BanAn
        fields = '__all__'



class DonHangSerializer(ModelSerializer):
    # declare these as explicit serializer fields so they are accepted from request body
    suc_chua = serializers.IntegerField(write_only=True)
    khu_vuc = serializers.ChoiceField(choices=BanAn.KHU_VUC, default='inside', write_only=True)
    khach_hang = UserSerializer(read_only=True)
    ban_an = BanAnSerializer(read_only=True)

    def create(self, validated_data):
        # copy validated_data so we can modify before creating DonHang
        data = validated_data.copy()
        print(data)

        # extract the helper fields passed in request body
        suc_chua = data.pop('suc_chua', None)
        khu_vuc = data.pop('khu_vuc', 'inside')

        # validation
        if suc_chua is None:
            raise serializers.ValidationError({ 'suc_chua': "Trường 'suc_chua' là bắt buộc" })

        ngay_dat = data.get('ngay_dat')
        if not ngay_dat:
            raise serializers.ValidationError({ 'ngay_dat': "Trường 'ngay_dat' là bắt buộc" })

        # Determine slot based on hour
        hour = ngay_dat.hour
        if 8 <= hour < 14:
            slot = 'morning'
            start_hour, end_hour = 8, 14
        elif 14 <= hour < 20:
            slot = 'afternoon'
            start_hour, end_hour = 14, 20
        elif 20 <= hour < 24:
            slot = 'evening'
            start_hour, end_hour = 20, 24
        else:
            raise serializers.ValidationError({ 'ngay_dat': "Thời gian đặt phải trong khoảng 8:00 - 24:00" })

        # find a matching table
        available_tables = BanAn.objects.filter(suc_chua__gte=suc_chua, khu_vuc__exact=khu_vuc)
        for ban_an in available_tables.order_by('suc_chua'):
            # Check if table is available in this slot
            active_reservations = DonHang.objects.filter(
                ban_an=ban_an, 
                trang_thai__in=['pending', 'confirmed'],
                ngay_dat__date=ngay_dat.date(),
                ngay_dat__hour__gte=start_hour,
                ngay_dat__hour__lt=end_hour if end_hour != 24 else 24
            ).exists()
            if not active_reservations:
                # Found available table
                data['ban_an'] = ban_an
                break
        else:
            raise serializers.ValidationError({ 'non_field_errors': ["Không tìm thấy bàn ăn phù hợp hoặc bàn đã được đặt trong khung giờ này"] })

        khach_hang = self.context['request'].user   # object NguoiDung
        data['khach_hang'] = khach_hang

        dh = DonHang(**data)
        dh.save()

        return dh

    class Meta:
        model = DonHang
        fields = '__all__'


class MonAnSerializer(ModelSerializer):
    danh_muc_ten = serializers.CharField(source='danh_muc.ten_danh_muc', read_only=True)
    
    class Meta:
        model = MonAn
        fields = '__all__'


class ChiTietOrderSerializer(ModelSerializer):
    mon_an_detail = MonAnSerializer(source='mon_an', read_only=True)
    
    class Meta:
        model = ChiTietOrder
        fields = '__all__'


class OrderSerializer(ModelSerializer):
    chi_tiet_order = ChiTietOrderSerializer(many=True, read_only=True, source='chitietorder_set')
    khach_hang_detail = UserSerializer(source='khach_hang', read_only=True)
    nhan_vien_detail = UserSerializer(source='nhan_vien', read_only=True)
    tong_tien = serializers.SerializerMethodField()
    
    def get_tong_tien(self, obj):
        return sum([item.so_luong * item.gia for item in obj.chitietorder_set.all()])
    
    class Meta:
        model = Order
        fields = '__all__'


class TakeawayOrderCreateSerializer(ModelSerializer):
    id = serializers.IntegerField(read_only=True)
    mon_an_list = serializers.ListField(write_only=True)

    class Meta:
        model = Order
        fields = ['id', 'ghi_chu', 'mon_an_list']
    
    def create(self, validated_data):
        from django.utils import timezone
        
        mon_an_list = validated_data.pop('mon_an_list')
        
        # Tạo order takeaway
        order = Order.objects.create(
            khach_hang=self.context['request'].user,
            loai_order='takeaway',
            trang_thai='pending',
            order_time=timezone.now(),
            **validated_data
        )
        
        # Tạo chi tiết order
        for item in mon_an_list:
            mon_an = MonAn.objects.get(id=item['mon_an_id'])
            ChiTietOrder.objects.create(
                order=order,
                mon_an=mon_an,
                so_luong=item['so_luong'],
                gia=mon_an.gia
            )
        
        return order


class OrderStatusUpdateSerializer(serializers.Serializer):
    trang_thai = serializers.ChoiceField(choices=Order.ORDER_STATUS)
    thoi_gian_lay = serializers.IntegerField(required=False)
    ghi_chu = serializers.CharField(required=False, allow_blank=True)



class DanhMucSerializer(ModelSerializer):
    class Meta:
        model = DanhMuc
        fields = '__all__'

