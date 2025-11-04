from rest_framework import serializers
from rest_framework.serializers import ModelSerializer
from .models import NguoiDung, BanAn, DonHang, Order, ChiTietOrder, MonAn, DanhMuc, \
AboutUs, KhachVangLai
from .utils import get_table_status, get_table_status_at, get_table_occupancy_info


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


class CustomerUserUpdateSerializer(ModelSerializer):
    # allow the user to update password; if provided we must hash it
    password = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = NguoiDung
        exclude = ('dang_lam_viec', 'loai_nguoi_dung', 'chuc_vu', 'ca_lam', 'is_staff', 'is_superuser', 'groups')

    def update(self, instance, validated_data):
        # If password supplied, hash it and remove from validated_data so super() won't set it directly
        password = validated_data.pop('password', None)
        if password:
            instance.set_password(password)
        # Let ModelSerializer handle the rest of the fields
        instance = super().update(instance, validated_data)
        # If password was set above, ensure instance is saved
        if password:
            instance.save()
        return instance


class BanAnSerializer(ModelSerializer):
    status = serializers.SerializerMethodField()
    current_customer = serializers.SerializerMethodField()
    occupancy_time = serializers.SerializerMethodField()

    def get_current_customer(self, obj):
        from django.utils import timezone
        today = timezone.now().date()
        
        # Check active reservations in DonHang first
        reservation = DonHang.objects.filter(
            ban_an=obj, 
            trang_thai__in=['pending', 'confirmed'],
            ngay_dat__date=today
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
            trang_thai__in=['pending', 'confirmed', 'cooking', 'ready'],
            order_time__date=today
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

    def get_occupancy_time(self, obj):
        """Trả về thông tin ngày giờ khi bàn bị chiếm dụng"""
        occupancy_info = get_table_occupancy_info(obj)
        if occupancy_info:
            return {
                'type': occupancy_info['type'],
                'date': occupancy_info['date'].isoformat(),
                'time': occupancy_info['time'].isoformat(),
                'datetime': occupancy_info['datetime'].isoformat()
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
            order_time__date=ngay_dat.date(),
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
    chi_tiet_order = ChiTietOrderSerializer(many=True, read_only=True, source='chitietorder_set')
    tong_tien = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ['id', 'ghi_chu', 'mon_an_list', 'thoi_gian_khach_lay', 
                  'order_time', 'trang_thai', 'loai_order', 'chi_tiet_order', 'tong_tien',
                  'phuong_thuc_giao_hang', 'dia_chi_giao_hang', 'latitude', 'longitude']
    
    def get_tong_tien(self, obj):
        return sum([item.so_luong * item.gia for item in obj.chitietorder_set.all()])
    
    def create(self, validated_data):
        from django.utils import timezone
        
        mon_an_list = validated_data.pop('mon_an_list')
        
        # Validate delivery info
        phuong_thuc_giao_hang = validated_data.get('phuong_thuc_giao_hang')
        dia_chi_giao_hang = validated_data.get('dia_chi_giao_hang')
        
        # Nếu chọn giao hàng tận nơi, địa chỉ là bắt buộc
        if phuong_thuc_giao_hang == 'Giao hàng tận nơi' and not dia_chi_giao_hang:
            raise serializers.ValidationError({
                'dia_chi_giao_hang': 'Vui lòng cung cấp địa chỉ giao hàng'
            })
        
        # Nếu chọn tự đến lấy, không cần địa chỉ
        if phuong_thuc_giao_hang == 'Tự đến lấy':
            validated_data['dia_chi_giao_hang'] = None

        print('Latitude:', validated_data.get('latitude'))
        print('Longitude:', validated_data.get('longitude'))
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


class StaffTakeawayOrderSerializer(ModelSerializer):
    """Serializer dành cho nhân viên tạo đơn mang về cho khách tại bàn"""
    id = serializers.IntegerField(read_only=True)
    mon_an_list = serializers.ListField(write_only=True)
    ban_an_id = serializers.IntegerField(write_only=True, required=False, allow_null=True)
    khach_ho_ten = serializers.CharField(write_only=True, max_length=100, required=False)
    khach_so_dien_thoai = serializers.CharField(write_only=True, max_length=15, required=False)
    khach_hang_id = serializers.IntegerField(write_only=True, required=False)

    class Meta:
        model = Order
        fields = ['id', 'ghi_chu', 'mon_an_list', 'thoi_gian_khach_lay', 
                  'ban_an_id', 'khach_ho_ten', 'khach_so_dien_thoai', 'khach_hang_id',
                  'phuong_thuc_giao_hang', 'dia_chi_giao_hang', 'latitude', 'longitude',]
    
    def create(self, validated_data):
        from django.utils import timezone
        
        mon_an_list = validated_data.pop('mon_an_list')
        khach_ho_ten = validated_data.pop('khach_ho_ten', None)
        khach_so_dien_thoai = validated_data.pop('khach_so_dien_thoai', None)
        khach_hang_id = validated_data.pop('khach_hang_id', None)
        ban_an_id = validated_data.pop('ban_an_id', None)
        
        # Xác định bàn ăn (nếu có)
        ban_an = None
        if ban_an_id:
            try:
                ban_an = BanAn.objects.get(id=ban_an_id)
            except BanAn.DoesNotExist:
                raise serializers.ValidationError({'ban_an_id': 'Bàn ăn không tồn tại'})
        
        # Xác định khách hàng
        khach_hang = None
        khach_vang_lai = None
        
        if khach_hang_id:
            # Khách hàng đã có tài khoản
            try:
                khach_hang = NguoiDung.objects.get(id=khach_hang_id, loai_nguoi_dung='khach_hang')
            except NguoiDung.DoesNotExist:
                raise serializers.ValidationError({'khach_hang_id': 'Khách hàng không tồn tại'})
        elif khach_ho_ten and khach_so_dien_thoai:
            # Khách vãng lai
            khach_vang_lai, created = KhachVangLai.objects.get_or_create(
                so_dien_thoai=khach_so_dien_thoai,
                defaults={'ho_ten': khach_ho_ten}
            )
            if not created and khach_vang_lai.ho_ten != khach_ho_ten:
                khach_vang_lai.ho_ten = khach_ho_ten
                khach_vang_lai.save()
        else:
            raise serializers.ValidationError({
                'non_field_errors': 'Vui lòng cung cấp thông tin khách hàng (khach_hang_id hoặc khach_ho_ten + khach_so_dien_thoai)'
            })
        
        # Tạo order takeaway
        order = Order.objects.create(
            khach_hang=khach_hang,
            khach_vang_lai=khach_vang_lai,
            ban_an=ban_an,  # Lưu thông tin bàn (có thể null)
            nhan_vien=self.context['request'].user,
            loai_order='takeaway',
            trang_thai='pending',
            order_time=timezone.now(),
            **validated_data
        )
        
        # Tạo chi tiết order
        for item in mon_an_list:
            try:
                mon_an = MonAn.objects.get(id=item['mon_an_id'])
                ChiTietOrder.objects.create(
                    order=order,
                    mon_an=mon_an,
                    so_luong=item['so_luong'],
                    gia=mon_an.gia
                )
            except MonAn.DoesNotExist:
                raise serializers.ValidationError({'mon_an_list': f'Món ăn ID {item["mon_an_id"]} không tồn tại'})
        
        return order


class DanhMucSerializer(ModelSerializer):
    class Meta:
        model = DanhMuc
        fields = '__all__'


class AboutUsSerializer(ModelSerializer):
    class Meta:
        model = AboutUs
        fields = '__all__'


class HotlineReservationSerializer(ModelSerializer):
    """Serializer dành cho nhân viên đặt bàn qua hotline cho khách vãng lai"""
    ban_an_id = serializers.IntegerField(write_only=True)
    khach_ho_ten = serializers.CharField(write_only=True, max_length=100)
    khach_so_dien_thoai = serializers.CharField(write_only=True, max_length=15)
    
    # Return fields
    khach_vang_lai = serializers.SerializerMethodField(read_only=True)
    ban_an = BanAnSerializer(read_only=True)
    
    def get_khach_vang_lai(self, obj):
        if obj.khach_vang_lai:
            return {
                'id': obj.khach_vang_lai.id,
                'ho_ten': obj.khach_vang_lai.ho_ten,
                'so_dien_thoai': obj.khach_vang_lai.so_dien_thoai
            }
        return None

    def create(self, validated_data):
        from django.utils import timezone
        
        # Extract data
        ban_an_id = validated_data.pop('ban_an_id')
        khach_ho_ten = validated_data.pop('khach_ho_ten')
        khach_so_dien_thoai = validated_data.pop('khach_so_dien_thoai')
        
        # Validation
        if not ban_an_id:
            raise serializers.ValidationError({'ban_an_id': "Trường 'ban_an_id' là bắt buộc"})
        
        if not khach_ho_ten:
            raise serializers.ValidationError({'khach_ho_ten': "Vui lòng cung cấp tên khách hàng"})
        
        if not khach_so_dien_thoai:
            raise serializers.ValidationError({'khach_so_dien_thoai': "Vui lòng cung cấp số điện thoại khách hàng"})
        
        # Get table
        try:
            ban_an = BanAn.objects.get(id=ban_an_id)
        except BanAn.DoesNotExist:
            raise serializers.ValidationError({'ban_an_id': "Bàn ăn không tồn tại"})
        
        # Get reservation date
        ngay_dat = validated_data.get('ngay_dat')
        if not ngay_dat:
            raise serializers.ValidationError({'ngay_dat': "Trường 'ngay_dat' là bắt buộc"})
        
        if get_table_status_at(ban_an, ngay_dat) == 'occupied':
            raise serializers.ValidationError({'non_field_errors': ["Bàn ăn đã được đặt hoặc đang sử dụng vào ngày này"]})
        
        # Get or create guest
        khach_vang_lai, created = KhachVangLai.objects.get_or_create(
            so_dien_thoai=khach_so_dien_thoai,
            defaults={'ho_ten': khach_ho_ten}
        )
        
        # If guest exists but name is different, update the name
        if not created and khach_vang_lai.ho_ten != khach_ho_ten:
            khach_vang_lai.ho_ten = khach_ho_ten
            khach_vang_lai.save()
        
        # Create reservation
        validated_data['ban_an'] = ban_an
        validated_data['khach_vang_lai'] = khach_vang_lai
        
        don_hang = DonHang(**validated_data)
        don_hang.save()
        
        return don_hang

    class Meta:
        model = DonHang
        fields = ['id', 'ban_an_id', 'ban_an', 'khach_ho_ten', 'khach_so_dien_thoai', 
                  'khach_vang_lai', 'ngay_dat', 'trang_thai']
        read_only_fields = ['id', 'ban_an', 'khach_vang_lai']
