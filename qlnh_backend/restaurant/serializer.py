from rest_framework import serializers
from rest_framework.serializers import ModelSerializer
from .models import NguoiDung, BanAn, DonHang, Order, ChiTietOrder, MonAn, DanhMuc, \
AboutUs
from .utils import get_table_status


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
        today = timezone.now().date()
        
        # Check active reservations in DonHang first
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
        
        # If no reservation, check active orders in Order (dine-in only)
        order = Order.objects.filter(
            ban_an=obj,
            loai_order='dine_in',
            trang_thai__in=['pending', 'confirmed', 'cooking', 'ready']
        ).first()
        
        if order:
            if order.khach_hang:
                return {
                    'type': 'registered',
                    'name': order.khach_hang.ho_ten,
                    'phone': order.khach_hang.so_dien_thoai
                }
            elif order.khach_vang_lai:
                return {
                    'type': 'guest',
                    'name': order.khach_vang_lai.ho_ten,
                    'phone': order.khach_vang_lai.so_dien_thoai
                }
        
        return None

    def get_status(self, obj):
        return get_table_status(obj)

    class Meta:
        model = BanAn
        fields = '__all__'


class BanAnForReservationSerializer(ModelSerializer):
    status = serializers.SerializerMethodField()

    def get_status(self, obj):
        return get_table_status(obj)
    
    class Meta:
        model = BanAn
        fields = '__all__'



class DonHangSerializer(ModelSerializer):
    # declare these as explicit serializer fields so they are accepted from request body
    ban_an_id = serializers.IntegerField(write_only=True)
    khach_hang = UserSerializer(read_only=True)
    ban_an = BanAnSerializer(read_only=True)

    def create(self, validated_data):
        # copy validated_data so we can modify before creating DonHang
        data = validated_data.copy()
        print(data)

        # extract the helper fields passed in request body
        ban_an_id = data.pop('ban_an_id', None)

        # validation
        if ban_an_id is None:
            raise serializers.ValidationError({ 'ban_an_id': "Trường 'ban_an_id' là bắt buộc" })

        ngay_dat = data.get('ngay_dat')
        if not ngay_dat:
            raise serializers.ValidationError({ 'ngay_dat': "Trường 'ngay_dat' là bắt buộc" })

        try:
            ban_an = BanAn.objects.get(id=ban_an_id)
        except BanAn.DoesNotExist:
            raise serializers.ValidationError({ 'ban_an_id': "Bàn ăn không tồn tại" })

        # Check if table is available on this date
        from django.utils import timezone
        today = timezone.now().date()
        
        # Check active reservations in DonHang
        active_reservations_donhang = DonHang.objects.filter(
            ban_an=ban_an,
            trang_thai__in=['pending', 'confirmed'],
            ngay_dat__date=ngay_dat.date()
        ).exists()
        
        # Check active orders in Order (dine-in only)
        active_orders = Order.objects.filter(
            ban_an=ban_an,
            loai_order='dine_in',
            trang_thai__in=['pending', 'confirmed', 'cooking', 'ready']
        ).exists()
        
        if active_reservations_donhang or active_orders:
            raise serializers.ValidationError({ 'non_field_errors': ["Bàn ăn đã được đặt hoặc đang sử dụng vào ngày này"] })

        # Table is available
        data['ban_an'] = ban_an

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
        print(validated_data.get('thoi_gian_lay_mon'))
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


class AboutUsSerializer(ModelSerializer):
    class Meta:
        model = AboutUs
        fields = '__all__'
