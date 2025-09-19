from rest_framework.serializers import ModelSerializer
from .models import NguoiDung


class UserSerializer(ModelSerializer):
    class Meta:
        model = NguoiDung
        fields = '__all__'


