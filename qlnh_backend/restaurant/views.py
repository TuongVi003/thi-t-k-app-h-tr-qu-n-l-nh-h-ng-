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
from rest_framework.decorators import api_view
import json
from .utils import send_to_user  # import hàm gửi notification

from restaurant.serializer import (BanAnForReservationSerializer, UserSerializer, BanAnSerializer, DonHangSerializer, 
                                  OrderSerializer, TakeawayOrderCreateSerializer, 
                                  OrderStatusUpdateSerializer, MonAnSerializer, DanhMucSerializer, AboutUsSerializer)
from .models import DonHang, NguoiDung, BanAn, Order, MonAn, DanhMuc, FCMDevice, ChiTietOrder, AboutUs



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
    
    @action(detail=False, methods=['post'], url_path='check-in')
    def check_in(self, request):
        """Nhân viên check-in ca làm việc"""
        user = request.user
        if user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được check-in'}, status=status.HTTP_403_FORBIDDEN)
        
        if user.dang_lam_viec:
            return Response({'error': 'Bạn đã check-in rồi'}, status=status.HTTP_400_BAD_REQUEST)
        
        user.dang_lam_viec = True
        user.save()
        
        return Response({'message': 'Check-in thành công', 'status': 'working'})
    
    @action(detail=False, methods=['post'], url_path='check-out')
    def check_out(self, request):
        """Nhân viên check-out ca làm việc"""
        user = request.user
        if user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được check-out'}, status=status.HTTP_403_FORBIDDEN)
        
        if not user.dang_lam_viec:
            return Response({'error': 'Bạn chưa check-in'}, status=status.HTTP_400_BAD_REQUEST)
        
        user.dang_lam_viec = False
        user.save()
        
        return Response({'message': 'Check-out thành công', 'status': 'off_duty'})


@api_view(['POST'])
def register_fcm_token(request):
    token = request.data.get('token')
    print('Registering FCM token:', token)
    print('User authenticated:', request.user.is_authenticated)
    if request.user.is_authenticated:
        print('User:', request.user, 'ID:', request.user.id)
    if not token:
        return Response({"error": "Missing token"}, status=400)

    if not request.user.is_authenticated:
        # nếu chưa login, tìm thấy token thì xóa user cũ (và gán user=None)
        # không tìm thấy thì tạo mới với user=None
        FCMDevice.objects.update_or_create(token=token, defaults={"user": None})
        return Response({"message": "Token registered for anonymous user"})
    # nếu đã login, tìm thấy token thì cập nhật user
    # không tìm thấy thì tạo mới với user hiện tại
    FCMDevice.objects.update_or_create(token=token, defaults={"user": request.user})
    return Response({"message": "Token registered for authenticated user"})


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

    


class UserTableView(viewsets.ViewSet, generics.ListAPIView):
    serializer_class = BanAnForReservationSerializer
    queryset = BanAn.objects.all()

    def get_queryset(self):
        khu_vuc = self.request.query_params.get('khu_vuc')
        if khu_vuc:
            return self.queryset.filter(khu_vuc=khu_vuc)
        return self.queryset


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


class TakeawayOrderView(viewsets.ModelViewSet):
    queryset = Order.objects.filter(loai_order='takeaway')
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return TakeawayOrderCreateSerializer
        elif self.action == 'update_status':
            return OrderStatusUpdateSerializer
        return OrderSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = serializer.save()
        
        # Push notification to all employees
        employees = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien')
        for emp in employees:
            send_to_user(emp, "Đơn hàng mới", f"Đơn hàng Mang về #{order.id} vừa được tạo.")
        
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    def get_queryset(self):
        user = self.request.user
        if user.loai_nguoi_dung == 'khach_hang':
            # Khách hàng chỉ xem đơn của mình - luôn lấy dữ liệu mới nhất
            return Order.objects.select_related('khach_hang', 'nhan_vien', 'ban_an').prefetch_related('chitietorder_set__mon_an').filter(loai_order='takeaway', khach_hang=user).order_by('-id')
        elif user.loai_nguoi_dung == 'nhan_vien':
            # Nhân viên xem tất cả đơn takeaway - luôn lấy dữ liệu mới nhất
            return Order.objects.select_related('khach_hang', 'nhan_vien', 'ban_an').prefetch_related('chitietorder_set__mon_an').filter(loai_order='takeaway').exclude(trang_thai__in=['canceled']).order_by('-id')
        return Order.objects.none()
    
    @action(detail=True, methods=['patch'], url_path='accept-order')
    def accept_order(self, request, pk=None):
        """Nhân viên nhận đơn"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được nhận đơn'}, status=status.HTTP_403_FORBIDDEN)
        
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc'}, status=status.HTTP_400_BAD_REQUEST)
        
        if order.trang_thai != 'pending':
            return Response({'error': 'Đơn hàng đã được xử lý'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.nhan_vien = request.user
        order.trang_thai = 'confirmed'
        order.save()

        # push notification đến khách hàng
        print(f"Sending order confirmation notification to user {order.khach_hang.id}")
        send_to_user(order.khach_hang, "Đơn hàng đã được xác nhận", f"Đơn hàng #{order.id} của bạn đã được nhân viên {request.user.ho_ten} xác nhận.")
        
        serializer = self.get_serializer(order)
        return Response(serializer.data)
    
    @action(detail=True, methods=['patch'], url_path='confirm-time')
    def confirm_time(self, request, pk=None):
        """Nhân viên xác nhận thời gian lấy món"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user != order.nhan_vien:
            return Response({'error': 'Chỉ nhân viên phụ trách mới được xác nhận'}, status=status.HTTP_403_FORBIDDEN)
        
        # Kiểm tra nhân viên đã check-in hay chưa
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc. Vui lòng check-in trước'}, status=status.HTTP_400_BAD_REQUEST)
        
        thoi_gian_lay = request.data.get('thoi_gian_lay')
        if not thoi_gian_lay:
            return Response({'error': 'Vui lòng nhập thời gian lấy món'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.thoi_gian_lay = thoi_gian_lay
        order.trang_thai = 'cooking'
        order.save()

        send_to_user(order.khach_hang, "Thời gian lấy món đã được xác nhận", f"Đơn hàng #{order.id} sẽ sẵn sàng sau {thoi_gian_lay} phút.")
        
        serializer = self.get_serializer(order)
        return Response(serializer.data)
    
    
    
    @action(detail=True, methods=['patch'], url_path='update-status')
    def update_status(self, request, pk=None):
        """Cập nhật trạng thái đơn hàng (dành cho bếp và nhân viên)"""
        from django.utils import timezone
        
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được cập nhật trạng thái'}, status=status.HTTP_403_FORBIDDEN)
        
        # Kiểm tra nhân viên đã check-in hay chưa
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc. Vui lòng check-in trước'}, status=status.HTTP_400_BAD_REQUEST)
        
        new_status = request.data.get('trang_thai')
        if new_status not in ['cooking', 'ready', 'completed']:
            return Response({'error': 'Trạng thái không hợp lệ'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Chỉ bếp (chef) mới được đặt trạng thái ready
        if new_status == 'ready' and request.user.chuc_vu != 'chef':
            return Response({'error': 'Chỉ bếp trưởng mới được đánh dấu món sẵn sàng'}, status=status.HTTP_403_FORBIDDEN)
        
        order.trang_thai = new_status
        if new_status == 'ready':
            order.thoi_gian_san_sang = timezone.now()
        order.save()

        if new_status == 'ready':
            send_to_user(order.khach_hang, "Món đã sẵn sàng", f"Đơn hàng #{order.id} của bạn đã sẵn sàng để lấy.")
        if new_status == 'completed':
            send_to_user(order.khach_hang, "Đơn hàng hoàn thành", f"Đơn hàng #{order.id} của bạn đã hoàn thành. Cảm ơn bạn đã sử dụng dịch vụ!")

        serializer = self.get_serializer(order)
        return Response(serializer.data)
    
    @action(detail=True, methods=['patch'], url_path='cancel-order')
    def cancel_order(self, request, pk=None):
        """Khách hàng hủy đơn"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user != order.khach_hang:
            return Response({'error': 'Chỉ chủ đơn mới được hủy'}, status=status.HTTP_403_FORBIDDEN)
        
        if order.trang_thai in ['cooking', 'ready', 'completed']:
            return Response({'error': 'Không thể hủy đơn hàng đã bắt đầu chế biến hoặc hoàn thành'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.trang_thai = 'canceled'
        order.save()
        
        serializer = self.get_serializer(order)
        return Response(serializer.data)


class DineInOrderView(viewsets.ModelViewSet):
    queryset = Order.objects.filter(loai_order='dine_in')
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return TakeawayOrderCreateSerializer
        return OrderSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.loai_nguoi_dung == 'nhan_vien':
            # Nhân viên xem tất cả đơn dine-in
            return Order.objects.select_related('khach_hang', 'nhan_vien', 'ban_an').prefetch_related('chitietorder_set__mon_an').filter(loai_order='dine_in').exclude(trang_thai__in=['canceled', 'completed']).order_by('-id')
        return Order.objects.none()
    
    def create(self, request, *args, **kwargs):
        """Nhân viên tạo đơn cho khách hàng tại bàn"""
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được tạo đơn'}, status=status.HTTP_403_FORBIDDEN)
        
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc'}, status=status.HTTP_400_BAD_REQUEST)
        
        ban_an_id = request.data.get('ban_an_id')
        if not ban_an_id:
            return Response({'error': 'Vui lòng chọn bàn ăn'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            ban_an = BanAn.objects.get(id=ban_an_id)
        except BanAn.DoesNotExist:
            return Response({'error': 'Bàn ăn không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        mon_an_list = request.data.get('mon_an_list', [])
        if not mon_an_list:
            return Response({'error': 'Vui lòng chọn món ăn'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Tạo order dine-in
        order = Order.objects.create(
            ban_an=ban_an,
            nhan_vien=request.user,
            loai_order='dine_in',
            trang_thai='pending',
            ghi_chu=request.data.get('ghi_chu', '')
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
        
        serializer = self.get_serializer(order)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['patch'], url_path='confirm-time')
    def confirm_time(self, request, pk=None):
        """Nhân viên xác nhận thời gian chế biến món"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được xác nhận'}, status=status.HTTP_403_FORBIDDEN)
        
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc'}, status=status.HTTP_400_BAD_REQUEST)
        
        if order.trang_thai != 'pending':
            return Response({'error': 'Đơn hàng đã được xử lý'}, status=status.HTTP_400_BAD_REQUEST)
        
        thoi_gian_lay = request.data.get('thoi_gian_lay')
        if not thoi_gian_lay:
            return Response({'error': 'Vui lòng nhập thời gian chế biến'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.thoi_gian_lay = thoi_gian_lay
        order.trang_thai = 'confirmed'
        order.save()
        
        serializer = self.get_serializer(order)
        return Response(serializer.data)
    
    @action(detail=True, methods=['patch'], url_path='start-cooking')
    def start_cooking(self, request, pk=None):
        """Bếp bắt đầu chế biến món"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được cập nhật'}, status=status.HTTP_403_FORBIDDEN)
        
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc'}, status=status.HTTP_400_BAD_REQUEST)
        
        if order.trang_thai != 'confirmed':
            return Response({'error': 'Đơn hàng chưa được xác nhận'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.trang_thai = 'cooking'
        order.save()
        
        serializer = self.get_serializer(order)
        return Response(serializer.data)
    
    @action(detail=True, methods=['patch'], url_path='mark-ready')
    def mark_ready(self, request, pk=None):
        """Bếp đánh dấu món sẵn sàng"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được cập nhật'}, status=status.HTTP_403_FORBIDDEN)
        
        if request.user.chuc_vu != 'chef':
            return Response({'error': 'Chỉ bếp trưởng mới được đánh dấu món sẵn sàng'}, status=status.HTTP_403_FORBIDDEN)
        
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc'}, status=status.HTTP_400_BAD_REQUEST)
        
        if order.trang_thai != 'cooking':
            return Response({'error': 'Đơn hàng chưa được bắt đầu chế biến'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.trang_thai = 'ready'
        order.thoi_gian_san_sang = timezone.now()
        order.save()
        
        # Thông báo cho nhân viên phụ trách
        if order.nhan_vien:
            send_to_user(order.nhan_vien, "Món đã sẵn sàng", f"Đơn hàng bàn {order.ban_an.so_ban} (#{order.id}) đã sẵn sàng để phục vụ.")
        
        serializer = self.get_serializer(order)
        return Response(serializer.data)
    
    @action(detail=True, methods=['patch'], url_path='deliver-to-table')
    def deliver_to_table(self, request, pk=None):
        """Nhân viên đem món tới bàn"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được cập nhật'}, status=status.HTTP_403_FORBIDDEN)
        
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc'}, status=status.HTTP_400_BAD_REQUEST)
        
        if order.trang_thai != 'ready':
            return Response({'error': 'Món chưa sẵn sàng'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.trang_thai = 'completed'
        order.save()
        
        serializer = self.get_serializer(order)
        return Response(serializer.data)
    
    @action(detail=True, methods=['patch'], url_path='cancel-order')
    def cancel_order(self, request, pk=None):
        """Nhân viên hủy đơn"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được hủy đơn'}, status=status.HTTP_403_FORBIDDEN)
        
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc'}, status=status.HTTP_400_BAD_REQUEST)
        
        if order.trang_thai in ['ready', 'completed']:
            return Response({'error': 'Không thể hủy đơn hàng đã sẵn sàng hoặc hoàn thành'}, status=status.HTTP_400_BAD_REQUEST)
        
        order.trang_thai = 'canceled'
        order.save()
        
        serializer = self.get_serializer(order)
        return Response(serializer.data)


class MenuView(viewsets.ReadOnlyModelViewSet):
    queryset = MonAn.objects.filter(available=True)
    serializer_class = MonAnSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        category = request.query_params.get('danh_muc')
        if category:
            print('Filtering by category:', category)
            self.queryset = self.queryset.filter(danh_muc__id=category)

        return super().list(request, *args, **kwargs)


class DanhMucView(viewsets.ViewSet, generics.ListAPIView):
    queryset = DanhMuc.objects.all()
    serializer_class = DanhMucSerializer
    permission_classes = [AllowAny]


class NhanVienView(viewsets.ViewSet, generics.ListAPIView):
    queryset = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien')
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]


class AboutUsView(viewsets.ViewSet, generics.ListAPIView):
    queryset = AboutUs.objects.filter(public=True)
    serializer_class = AboutUsSerializer
    permission_classes = [AllowAny]


def landing_page(request):
    return render(request, 'landing_page.html')
