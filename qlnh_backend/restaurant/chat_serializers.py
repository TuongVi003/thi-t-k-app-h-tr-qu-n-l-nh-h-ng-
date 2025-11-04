from rest_framework import serializers
from .models import Conversation, ChatMessage, NguoiDung


class NguoiDungSimpleSerializer(serializers.ModelSerializer):
    """Serializer đơn giản cho NguoiDung trong chat"""
    class Meta:
        model = NguoiDung
        fields = ['id', 'username', 'ho_ten', 'loai_nguoi_dung', 'chuc_vu']


class ChatMessageSerializer(serializers.ModelSerializer):
    nguoi_goi_name = serializers.SerializerMethodField()
    nguoi_goi_display = serializers.SerializerMethodField()
    nguoi_goi_info = NguoiDungSimpleSerializer(source='nguoi_goi', read_only=True)
    
    class Meta:
        model = ChatMessage
        fields = [
            'id', 
            'conversation', 
            'nguoi_goi', 
            'nguoi_goi_name',
            'nguoi_goi_display',
            'nguoi_goi_info',
            'noi_dung', 
            'thoi_gian'
        ]
        read_only_fields = ['id', 'thoi_gian', 'nguoi_goi_name', 'nguoi_goi_display']
    
    def get_nguoi_goi_name(self, obj):
        """Trả về tên người gửi"""
        if obj.nguoi_goi:
            return obj.nguoi_goi.ho_ten
        return "Không xác định"
    
    def get_nguoi_goi_display(self, obj):
        """Trả về tên hiển thị (staff group hiển thị chung "Nhân viên")"""
        return obj.nguoi_goi_display()


class ConversationSerializer(serializers.ModelSerializer):
    customer_info = NguoiDungSimpleSerializer(source='customer', read_only=True)
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = [
            'id',
            'customer',
            'customer_info',
            'is_staff_group',
            'created_at',
            'last_message_at',
            'last_message',
            'unread_count'
        ]
        read_only_fields = ['id', 'created_at', 'last_message_at']
    
    def get_last_message(self, obj):
        """Lấy tin nhắn cuối cùng"""
        last_msg = obj.messages.order_by('-thoi_gian').first()
        if last_msg:
            return {
                'id': last_msg.id,
                'noi_dung': last_msg.noi_dung,
                'thoi_gian': last_msg.thoi_gian,
                'nguoi_goi_name': last_msg.nguoi_goi_display()
            }
        return None
    
    def get_unread_count(self, obj):
        """Số tin chưa đọc (có thể implement sau với field is_read trong ChatMessage)"""
        # TODO: Implement khi thêm tính năng đọc/chưa đọc
        return 0


class ConversationDetailSerializer(ConversationSerializer):
    """Serializer chi tiết với danh sách messages"""
    messages = ChatMessageSerializer(many=True, read_only=True)
    
    class Meta(ConversationSerializer.Meta):
        fields = ConversationSerializer.Meta.fields + ['messages']
