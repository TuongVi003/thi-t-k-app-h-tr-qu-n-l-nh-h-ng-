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


class BanAnSerializer(ModelSerializer):

    class Meta:
        model = BanAn
        fields = '__all__'


class DonHangSerializer(ModelSerializer):
    # declare these as explicit serializer fields so they are accepted from request body
    suc_chua = serializers.IntegerField(write_only=True)
    khu_vuc = serializers.ChoiceField(choices=BanAn.KHU_VUC, default='inside', write_only=True)

    def create(self, validated_data):
        # copy validated_data so we can modify before creating DonHang
        data = validated_data.copy()

        # extract the helper fields passed in request body
        suc_chua = data.pop('suc_chua', None)
        khu_vuc = data.pop('khu_vuc', 'inside')

        # validation
        if suc_chua is None:
            raise serializers.ValidationError({ 'suc_chua': "Trường 'suc_chua' là bắt buộc" })

        # find a matching table
        ban_an = BanAn.objects.filter(suc_chua__gte=suc_chua, khu_vuc__exact=khu_vuc).order_by('suc_chua').first()

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


