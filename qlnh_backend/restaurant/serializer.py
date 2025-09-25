from rest_framework import serializers
from rest_framework.serializers import ModelSerializer
from .models import NguoiDung, BanAn, DonHang


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

        # find a matching table
        ban_an = BanAn.objects.filter(suc_chua__gte=suc_chua, khu_vuc__exact=khu_vuc).order_by('suc_chua').first()
        print('ban_an:', ban_an)
        if not ban_an:
            raise serializers.ValidationError({ 'non_field_errors': ["Không tìm thấy bàn ăn phù hợp"] })

        data['ban_an'] = ban_an

        khach_hang = self.context['request'].user   # object NguoiDung
        data['khach_hang'] = khach_hang

        dh = DonHang(**data)
        dh.save()

        return dh

    class Meta:
        model = DonHang
        fields = '__all__'


