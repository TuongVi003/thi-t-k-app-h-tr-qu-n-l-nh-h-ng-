from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Max
from .models import Conversation, ChatMessage, NguoiDung
from .chat_serializers import (
    ConversationSerializer, 
    ConversationDetailSerializer,
    ChatMessageSerializer
)


class ConversationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet cho Conversation (Read-only)
    
    Logic:
    - Khách hàng: Chỉ có 1 conversation duy nhất với staff group
    - Nhân viên: Xem tất cả conversations của tất cả khách hàng
    - Tất cả nhân viên chung 1 luồng (is_staff_group=True)
    
    Endpoints:
    - GET /conversations/ - List conversations (staff: all, customer: own)
    - GET /conversations/{id}/ - Get conversation detail
    - GET /conversations/my_conversation/ - Customer lấy conversation của mình
    - GET /conversations/{id}/messages/ - Get messages trong conversation
    - POST /conversations/{id}/send_message/ - Gửi tin nhắn
    """
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        
        if user.loai_nguoi_dung == 'nhan_vien':
            # Staff xem TẤT CẢ conversations của tất cả khách hàng
            # Tất cả staff đều thấy chung, không phân chia riêng
            return Conversation.objects.filter(
                is_staff_group=True
            ).select_related('customer').prefetch_related('messages').order_by('-last_message_at')
        else:
            # Customer chỉ xem conversation DUY NHẤT của mình
            # Mỗi customer chỉ có 1 conversation với staff group
            return Conversation.objects.filter(
                customer=user,
                is_staff_group=True
            ).select_related('customer').prefetch_related('messages')
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ConversationDetailSerializer
        return ConversationSerializer
    
    @action(detail=False, methods=['get'])
    def my_conversation(self, request):
        """
        Customer lấy conversation của chính mình
        GET /api/conversations/my_conversation/
        """
        user = request.user
        if user.loai_nguoi_dung != 'khach_hang':
            return Response(
                {'error': 'Chỉ khách hàng mới có thể gọi endpoint này'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        conv = Conversation.get_or_create_for_customer(user)
        serializer = ConversationDetailSerializer(conv)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """
        Lấy tất cả messages trong conversation
        GET /api/conversations/{id}/messages/
        Query params:
        - limit: số message lấy (default 50)
        - offset: offset cho pagination
        """
        conversation = self.get_object()
        limit = int(request.query_params.get('limit', 50))
        offset = int(request.query_params.get('offset', 0))
        
        messages = ChatMessage.objects.filter(
            conversation=conversation
        ).select_related('nguoi_goi').order_by('-thoi_gian')[offset:offset+limit]
        
        # Reverse để tin mới nhất ở cuối
        messages = list(reversed(messages))
        
        serializer = ChatMessageSerializer(messages, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        """
        Gửi message qua REST API (alternative cho socket.io)
        POST /api/conversations/{id}/send_message/
        Body: {'noi_dung': str}
        """
        conversation = self.get_object()
        user = request.user
        noi_dung = request.data.get('noi_dung', '').strip()
        
        if not noi_dung:
            return Response(
                {'error': 'Nội dung tin nhắn không được để trống'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Kiểm tra quyền gửi tin
        if user.loai_nguoi_dung == 'khach_hang':
            if conversation.customer != user:
                return Response(
                    {'error': 'Bạn không có quyền gửi tin trong conversation này'},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        # Tạo message
        message = ChatMessage.objects.create(
            conversation=conversation,
            nguoi_goi=user,
            noi_dung=noi_dung
        )
        
        serializer = ChatMessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class ChatMessageViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet cho ChatMessage (chỉ đọc)
    Sử dụng ConversationViewSet để gửi message
    """
    serializer_class = ChatMessageSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        
        if user.loai_nguoi_dung == 'nhan_vien':
            # Staff xem tất cả messages
            return ChatMessage.objects.all().select_related('nguoi_goi', 'conversation').order_by('-thoi_gian')
        else:
            # Customer chỉ xem messages của conversation của mình
            return ChatMessage.objects.filter(
                conversation__customer=user,
                conversation__is_staff_group=True
            ).select_related('nguoi_goi', 'conversation').order_by('-thoi_gian')
