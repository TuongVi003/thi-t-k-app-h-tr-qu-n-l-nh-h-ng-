from django.http import HttpResponse
from rest_framework.response import Response
from rest_framework.decorators import action
from django.shortcuts import render
from urllib3 import request
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import viewsets, generics
from oauth2_provider.views import TokenView
from oauth2_provider.models import AccessToken
from django.http import JsonResponse
from django.utils import timezone
from rest_framework import status
import json

from restaurant.serializer import UserSerializer, BanAnSerializer, DonHangSerializer
from .models import DonHang, NguoiDung, BanAn



class UserView(viewsets.ViewSet, generics.CreateAPIView):
    queryset = NguoiDung.objects.all()
    serializer_class = UserSerializer
    
    def get_permissions(self):
        if self.action in ['create']:
            self.permission_classes = [AllowAny]
        else:
            self.permission_classes = [IsAuthenticated]
        return super().get_permissions()

    @action(detail=False, methods=['get'], url_path='current-user')
    def get_current_user(self, request):
        user = request.user     # object NguoiDung
        serializer = self.get_serializer(user)
        return Response(status=200, data=serializer.data)



class DonHangView(viewsets.ViewSet, generics.ListCreateAPIView):
    queryset = DonHang.objects.order_by('-id')
    serializer_class = DonHangSerializer
    permission_classes = [IsAuthenticated]


    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(status=201, data=serializer.data)
        return Response(status=400, data=serializer.errors)

    @action(detail=True, methods=['patch'], url_path='update-status')
    def update_status(self, request, pk=None):
        try:
            don_hang = DonHang.objects.get(pk=pk)
        except DonHang.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if user is authenticated and is employee
        if not request.user.is_authenticated or not hasattr(request.user, 'loai_nguoi_dung') or request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được cập nhật trạng thái'}, status=status.HTTP_403_FORBIDDEN)
        
        new_status = request.data.get('trang_thai')
        if new_status not in ['pending', 'confirmed', 'canceled']:
            return Response({'error': 'Trạng thái không hợp lệ'}, status=status.HTTP_400_BAD_REQUEST)
        
        don_hang.trang_thai = new_status
        don_hang.save()
        
        serializer = self.get_serializer(don_hang)
        return Response(serializer.data)


class TableView(viewsets.ViewSet, generics.ListCreateAPIView):
    queryset = BanAn.objects.all()
    serializer_class = BanAnSerializer

    


class CustomTokenView(TokenView):
    def post(self, request, *args, **kwargs):
        # Parse data from JSON or form
        if request.content_type == 'application/json':
            try:
                data = json.loads(request.body)
            except json.JSONDecodeError:
                return JsonResponse({'error': 'Invalid JSON'}, status=status.HTTP_400_BAD_REQUEST)
        else:
            data = request.POST
        
        print('CustomTokenView.post called:', dict(data).get('app_nhan_vien'))
        response = super().post(request, *args, **kwargs)
        
        if not dict(data).get('app_nhan_vien'):
            # Nếu yêu cầu đến từ app khách hàng
            return response
        
        # nếu yêu cầu đến từ app nhân viên
        if response.status_code == 200:
            print('Token created successfully for employee app')
            # Parse response để lấy user từ access_token
            try:
                response_data = json.loads(response.content)
                access_token = response_data.get('access_token')
                if access_token:
                    token_obj = AccessToken.objects.get(token=access_token)
                    user = token_obj.user
                    if user.is_authenticated and hasattr(user, 'loai_nguoi_dung'):
                        if user.loai_nguoi_dung == 'khach_hang':
                            # Người dùng là khách hàng, không cho phép đăng nhập
                            return JsonResponse({'error': 'Access denied for customer users'}, status=status.HTTP_401_UNAUTHORIZED)
                else:
                    print('No access_token in response')
            except (json.JSONDecodeError, AccessToken.DoesNotExist) as e:
                print('Error parsing token response:', e)
                return JsonResponse({'error': 'Internal server error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
        return response


def landing_page(request):
    return render(request, 'landing_page.html')
