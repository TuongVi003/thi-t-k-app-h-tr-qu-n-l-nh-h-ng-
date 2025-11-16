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
from datetime import datetime, timedelta
from django.db.models import Sum, Count, Q, Avg, F
from django.db.models.functions import TruncDate, TruncMonth
from .utils import send_to_user, format_donhang_status  # import hàm gửi notification
from .khuyenmai_utils import is_promotion_active, discounted_price

from restaurant.serializer import (BanAnForReservationSerializer, UserSerializer, BanAnSerializer, DonHangSerializer, 
                                  OrderSerializer, TakeawayOrderCreateSerializer, CustomerUserUpdateSerializer, 
                                  OrderStatusUpdateSerializer, MonAnSerializer, DanhMucSerializer, AboutUsSerializer, HotlineReservationSerializer,
                                  HoaDonSerializer, NotificationSerializer, KhuyenMaiSerializer)
from .models import DonHang, NguoiDung, BanAn, Order, MonAn, DanhMuc, FCMDevice, ChiTietOrder, AboutUs, HoaDon, Notification, KhuyenMai
from restaurant.mail_service import send_order_completion_email


class UserView(viewsets.ViewSet, generics.CreateAPIView, generics.UpdateAPIView):
    queryset = NguoiDung.objects.all()
    serializer_class = UserSerializer
    
    def get_permissions(self):
        if self.action in ['create']:
            self.permission_classes = [AllowAny]
        else:
            self.permission_classes = [IsAuthenticated]
        return super().get_permissions()

    @action(detail=False, methods=['get', 'patch'], url_path='current-user')
    def get_current_user(self, request):
        if request.method.__eq__('PATCH'):
            serializer = CustomerUserUpdateSerializer(request.user, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(status=200, data=serializer.data)
            return Response(status=400, data=serializer.errors)
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

    @action(detail=False, methods=['post'], url_path='hotline-reservation')
    def hotline_reservation(self, request):
        """Nhân viên đặt bàn qua hotline cho khách vãng lai"""
        # Check if user is employee
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được đặt bàn qua hotline'}, status=status.HTTP_403_FORBIDDEN)
        
        # Check if employee has checked in
        if not request.user.dang_lam_viec:
            return Response({'error': 'Vui lòng check-in trước khi đặt bàn'}, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = HotlineReservationSerializer(data=request.data)
        if serializer.is_valid():
            reservation = serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

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

        # send notification
        send_to_user(don_hang.khach_hang, "Cập nhật trạng thái đặt bàn", f"Đơn đặt bàn #{don_hang.id} của bạn đã được cập nhật trạng thái thành '{format_donhang_status(new_status)}'.")
        
        serializer = self.get_serializer(don_hang)
        return Response(serializer.data)


class TableView(viewsets.ViewSet, generics.ListCreateAPIView):
    queryset = BanAn.objects.all()
    serializer_class = BanAnSerializer

    @action(detail=True, methods=['post'], url_path='clear-table')
    def clear_table(self, request, pk=None):
        """Nhân viên cập nhật trạng thái bàn về available bằng cách kết thúc các đơn đang active"""
        # Check if user is employee
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được phép thực hiện'}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            ban_an = BanAn.objects.get(pk=pk)
        except BanAn.DoesNotExist:
            return Response({'error': 'Bàn ăn không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        from django.utils import timezone
        today = timezone.now().date()
        
        # Update active reservations in DonHang to canceled
        updated_reservations = DonHang.objects.filter(
            ban_an=ban_an,
            trang_thai__in=['pending', 'confirmed'],
            ngay_dat__date=today
        ).update(trang_thai='completed')
        
        # Update active orders in Order to completed
        updated_orders = Order.objects.filter(
            ban_an=ban_an,
            loai_order='dine_in',
            order_time__date=today,
            trang_thai__in=['pending', 'confirmed', 'cooking', 'ready']
        ).update(trang_thai='completed')
        
        return Response({
            'message': 'Đã cập nhật trạng thái bàn thành công',
            'reservations_completed': updated_reservations,
            'orders_completed': updated_orders,
            'table_status': 'available'
        })



class UserTableView(viewsets.ViewSet, generics.ListAPIView):
    serializer_class = BanAnForReservationSerializer
    queryset = BanAn.objects.all()

    def get_queryset(self):
        khu_vuc = self.request.query_params.get('khu_vuc')
        # khu_vuc = 'inside'
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
        
        # Kiểm tra token có được tạo thành công không
        if response.status_code == 200:
            try:
                response_data = json.loads(response.content)
                access_token = response_data.get('access_token')
                if access_token:
                    token_obj = AccessToken.objects.get(token=access_token)
                    user = token_obj.user
                    
                    if user.is_authenticated and hasattr(user, 'loai_nguoi_dung'):
                        is_employee_app = dict(data).get('app_nhan_vien')
                        
                        if is_employee_app:
                            # Nếu là app nhân viên, chỉ cho phép nhân viên đăng nhập
                            if user.loai_nguoi_dung != 'nhan_vien':
                                # Xóa token vừa tạo
                                token_obj.delete()
                                return JsonResponse({'error': 'Chỉ nhân viên mới được phép đăng nhập vào ứng dụng này'}, status=status.HTTP_401_UNAUTHORIZED)
                        else:
                            # Nếu là app khách hàng, chỉ cho phép khách hàng đăng nhập
                            if user.loai_nguoi_dung != 'khach_hang':
                                # Xóa token vừa tạo
                                token_obj.delete()
                                return JsonResponse({'error': 'Chỉ khách hàng mới được phép đăng nhập vào ứng dụng này'}, status=status.HTTP_401_UNAUTHORIZED)
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
        
        # Tạo thông báo dựa trên phương thức giao hàng
        print('Order delivery method:', order.phuong_thuc_giao_hang)
        if order.phuong_thuc_giao_hang == 'Giao hàng tận nơi':
            notification_title = "Đơn hàng giao tận nơi mới"
            notification_message = f"Đơn giao hàng #{order.id} vừa được tạo. Địa chỉ: {order.dia_chi_giao_hang}"
        else:
            notification_title = "Đơn hàng mang về mới"
            notification_message = f"Đơn hàng Mang về #{order.id} vừa được tạo. Khách sẽ tự đến lấy."
        
        # Push notification to all employees
        employees = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien')
        for emp in employees:
            send_to_user(emp, notification_title, notification_message)
        
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
        # If this is a delivery order, calculate shipping fee and include it in the notification
        if order.phuong_thuc_giao_hang == 'Giao hàng tận nơi':
            try:
                fee = order.calculate_shipping_fee()
            except Exception:
                fee = None

            if fee is None:
                # Unable to calculate fee
                send_to_user(
                    order.khach_hang,
                    "Đơn hàng đã được xác nhận",
                    f"Đơn hàng #{order.id} của bạn đã được nhân viên {request.user.ho_ten} xác nhận. Phí giao hàng hiện chưa xác định; nhân viên sẽ cập nhật sau."
                )
            else:
                # Format fee for Vietnamese display: 15.000 ₫
                try:
                    fee_int = int(round(float(fee)))
                    formatted_fee = f"{fee_int:,}".replace(',', '.') + ' ₫'
                except Exception:
                    formatted_fee = str(fee)

                send_to_user(
                    order.khach_hang,
                    "Đơn hàng đã được xác nhận",
                    f"Đơn hàng #{order.id} của bạn đã được nhân viên {request.user.ho_ten} xác nhận. Phí giao hàng: {formatted_fee}"
                )
        else:
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
        
        # thoi_gian_lay = request.data.get('thoi_gian_lay')
        # if not thoi_gian_lay:
        #     return Response({'error': 'Vui lòng nhập thời gian lấy món'}, status=status.HTTP_400_BAD_REQUEST)
        
        # order.thoi_gian_lay = thoi_gian_lay
        order.thoi_gian_lay = None
        order.trang_thai = 'cooking'
        order.save()

        # send_to_user(order.khach_hang, "Thời gian lấy món đã được xác nhận", f"Đơn hàng #{order.id} sẽ sẵn sàng sau {thoi_gian_lay} phút.")
        
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
            payment_qr = AboutUs.objects.filter(key='payment_qr').first()
            if order.phuong_thuc_giao_hang == 'Giao hàng tận nơi':
                send_to_user(order.khach_hang, "Món đã sẵn sàng", f"Đơn hàng #{order.id} của bạn đã sẵn sàng. Nhân viên sẽ giao đến địa chỉ: {order.dia_chi_giao_hang}", { 'image_url': payment_qr.noi_dung if payment_qr else '' })
            else:
                send_to_user(order.khach_hang, "Món đã sẵn sàng", f"Đơn hàng #{order.id} của bạn đã sẵn sàng để lấy.", { 'image_url': payment_qr.noi_dung if payment_qr else '' })
        if new_status == 'completed':
            # Tạo hóa đơn
            from decimal import Decimal
            chi_tiet_list = order.chitietorder_set.all()
            tong_tien = sum(Decimal(str(item.gia)) * item.so_luong for item in chi_tiet_list)
            
            # Tính phí giao hàng
            phi_giao_hang = order.calculate_shipping_fee()
            if phi_giao_hang is None:
                phi_giao_hang = Decimal('0.00')
            
            pm = request.data.get('payment_method')
            # Tính khuyến mãi chỉ áp dụng cho tổng tiền đơn hàng (không bao gồm phí ship)
            final_amount, applied_promotions = discounted_price(tong_tien)
            gia_giam = tong_tien - final_amount
            
            # Tổng tiền cuối cùng = tiền sau giảm giá + phí giao hàng
            tong_tien_cuoi_cung = final_amount + phi_giao_hang
            
            hoa_don = HoaDon.objects.create(
                order=order,
                tong_tien=tong_tien_cuoi_cung,
                phi_giao_hang=phi_giao_hang,
                payment_method=pm,
                gia_giam=gia_giam,
            )
            # Lưu các khuyến mãi đã áp dụng vào hóa đơn
            if applied_promotions:
                hoa_don.khuyen_mai.set(applied_promotions)
            
            # Gửi thông báo cho khách hàng
            send_to_user(order.khach_hang, "Đơn hàng hoàn thành", f"Đơn hàng #{order.id} của bạn đã hoàn thành. Cảm ơn bạn đã sử dụng dịch vụ!")
            send_order_completion_email(order)  # Gửi email thông báo đơn hàng hoàn thành

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
    
    @action(detail=True, methods=['patch'], url_path='confirm-payment')
    def confirm_payment(self, request, pk=None):
        """Khách hàng xác nhận đã thanh toán"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        # Chỉ khách hàng của đơn hàng mới có thể xác nhận
        if order.khach_hang != request.user:
            return Response({'error': 'Bạn không có quyền xác nhận thanh toán đơn hàng này'}, status=status.HTTP_403_FORBIDDEN)
        
        # Kiểm tra đã xác nhận chưa
        if order.khach_hang_xac_nhan_thanh_toan:
            return Response({'message': 'Đơn hàng đã được xác nhận thanh toán trước đó'}, status=status.HTTP_200_OK)
        
        order.khach_hang_xac_nhan_thanh_toan = True
        order.save()
        
        serializer = self.get_serializer(order)

        # Gửi thông báo cho nhân viên
        employees = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien', dang_lam_viec=True)
        for emp in employees:
            send_to_user(
                emp,
                "Xác nhận thanh toán từ khách hàng",
                f"Khách hàng {order.khach_hang.ho_ten} đã xác nhận thanh toán cho đơn hàng #{order.id}."
            )
        return Response({
            'message': 'Xác nhận thanh toán thành công',
            'order': serializer.data
        }, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['post'], url_path='staff-create-order')
    def staff_create_order(self, request):
        """Nhân viên tạo đơn mang về cho khách (tại bàn hoặc vãng lai)"""
        # Check if user is employee
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được tạo đơn'}, status=status.HTTP_403_FORBIDDEN)
        
        # Check if employee has checked in
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc'}, status=status.HTTP_400_BAD_REQUEST)
        
        from restaurant.serializer import StaffTakeawayOrderSerializer
        serializer = StaffTakeawayOrderSerializer(data=request.data, context={'request': request})
        
        if serializer.is_valid():
            order = serializer.save()
            
            # Tạo thông báo dựa trên phương thức giao hàng
            if order.phuong_thuc_giao_hang == 'Giao hàng tận nơi':
                customer_message = f"Nhân viên {request.user.ho_ten} đã tạo đơn giao hàng #{order.id} cho bạn. Địa chỉ giao: {order.dia_chi_giao_hang}"
                chef_message = f"Đơn giao hàng #{order.id} vừa được tạo bởi {request.user.ho_ten}. Địa chỉ: {order.dia_chi_giao_hang}"
            else:
                customer_message = f"Nhân viên {request.user.ho_ten} đã tạo đơn mang về #{order.id} cho bạn. Vui lòng đến lấy món khi sẵn sàng."
                chef_message = f"Đơn mang về #{order.id} vừa được tạo bởi {request.user.ho_ten}. Khách sẽ tự đến lấy."
            
            # Gửi thông báo cho khách hàng (nếu có tài khoản)
            if order.khach_hang:
                send_to_user(
                    order.khach_hang,
                    "Đơn mang về mới",
                    customer_message,
                    data={'order_id': str(order.id), 'type': 'takeaway_order'}
                )
            
            # Gửi thông báo cho bếp
            chefs = NguoiDung.objects.filter(
                loai_nguoi_dung='nhan_vien',
                chuc_vu='chef',
                dang_lam_viec=True
            )
            for chef in chefs:
                send_to_user(
                    chef,
                    "Đơn mang về mới",
                    chef_message,
                    data={'order_id': str(order.id), 'type': 'new_takeaway_order'}
                )
            
            # Return with full order details
            response_serializer = OrderSerializer(order)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


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
    
    @action(detail=True, methods=['post'], url_path='add-items')
    def add_items(self, request, pk=None):
        """Nhân viên thêm món vào đơn order dine-in đã tồn tại"""
        try:
            order = self.get_object()
        except Order.DoesNotExist:
            return Response({'error': 'Đơn hàng không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
        
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới được thêm món'}, status=status.HTTP_403_FORBIDDEN)
        
        if not request.user.dang_lam_viec:
            return Response({'error': 'Bạn chưa vào ca làm việc'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Kiểm tra trạng thái đơn - chỉ cho phép thêm món khi đơn chưa hoàn thành hoặc bị hủy
        if order.trang_thai in ['completed', 'canceled']:
            return Response({'error': 'Không thể thêm món vào đơn đã hoàn thành hoặc đã hủy'}, status=status.HTTP_400_BAD_REQUEST)
        
        mon_an_list = request.data.get('mon_an_list', [])
        if not mon_an_list:
            return Response({'error': 'Vui lòng chọn món cần thêm'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Thêm các món mới vào chi tiết order
        added_items = []
        for item in mon_an_list:
            try:
                mon_an = MonAn.objects.get(id=item['mon_an_id'])
                so_luong = item.get('so_luong', 1)
                
                # Kiểm tra xem món đã có trong order chưa
                existing_item = ChiTietOrder.objects.filter(order=order, mon_an=mon_an).first()
                if existing_item:
                    # Nếu đã có, tăng số lượng
                    existing_item.so_luong += so_luong
                    existing_item.save()
                    added_items.append({
                        'mon_an': mon_an.ten_mon,
                        'so_luong_cu': existing_item.so_luong - so_luong,
                        'so_luong_moi': existing_item.so_luong,
                        'action': 'updated'
                    })
                else:
                    # Nếu chưa có, tạo mới
                    ChiTietOrder.objects.create(
                        order=order,
                        mon_an=mon_an,
                        so_luong=so_luong,
                        gia=mon_an.gia
                    )
                    added_items.append({
                        'mon_an': mon_an.ten_mon,
                        'so_luong': so_luong,
                        'action': 'added'
                    })
            except MonAn.DoesNotExist:
                return Response({'error': f'Món ăn ID {item["mon_an_id"]} không tồn tại'}, status=status.HTTP_404_NOT_FOUND)
            except KeyError:
                return Response({'error': 'Thiếu trường mon_an_id trong danh sách món'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Gửi thông báo cho bếp nếu đơn đang được xử lý
        if order.trang_thai in ['confirmed', 'cooking']:
            chefs = NguoiDung.objects.filter(loai_nguoi_dung='nhan_vien', chuc_vu='chef', dang_lam_viec=True)
            for chef in chefs:
                send_to_user(
                    chef,
                    f"Đơn #{order.id} - Bàn {order.ban_an.so_ban} có món mới",
                    f"Khách đã gọi thêm {len(added_items)} món",
                    data={'order_id': str(order.id), 'type': 'order_updated'}
                )
        
        serializer = self.get_serializer(order)
        return Response({
            'message': f'Đã thêm {len(added_items)} món vào đơn hàng',
            'added_items': added_items,
            'order': serializer.data
        }, status=status.HTTP_200_OK)
    
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
        
        # Tạo hóa đơn
        from decimal import Decimal
        chi_tiet_list = order.chitietorder_set.all()
        tong_tien = sum(Decimal(str(item.gia)) * item.so_luong for item in chi_tiet_list)
        
        # Tính phí giao hàng (dine-in không có phí giao hàng)
        phi_giao_hang = Decimal('0.00')
        
        # Tạo hóa đơn
        pm = request.data.get('payment_method')
        # Tính khuyến mãi chỉ áp dụng cho tổng tiền đơn hàng
        final_amount, applied_promotions = discounted_price(tong_tien)
        gia_giam = tong_tien - final_amount
        
        # Tổng tiền cuối cùng = tiền sau giảm giá + phí giao hàng (dine-in thì phi_giao_hang = 0)
        tong_tien_cuoi_cung = final_amount + phi_giao_hang
        
        hoa_don = HoaDon.objects.create(
            order=order,
            tong_tien=tong_tien_cuoi_cung,
            phi_giao_hang=phi_giao_hang,
            payment_method=pm,
            gia_giam=gia_giam
        )
        # Lưu các khuyến mãi đã áp dụng vào hóa đơn
        if applied_promotions:
            hoa_don.khuyen_mai.set(applied_promotions)
        
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


class StatisticsView(viewsets.ViewSet):
    """API thống kê cho nhân viên"""
    permission_classes = [IsAuthenticated]
    
    def list(self, request):
        """Tổng quan thống kê tổng hợp"""
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới có quyền xem thống kê'}, status=status.HTTP_403_FORBIDDEN)
        
        today = timezone.now().date()
        start_of_month = today.replace(day=1)
        
        # Thống kê hôm nay
        today_orders = Order.objects.filter(order_time__date=today)
        today_reservations = DonHang.objects.filter(ngay_dat__date=today)
        
        # Thống kê tháng này
        month_orders = Order.objects.filter(order_time__date__gte=start_of_month)
        month_reservations = DonHang.objects.filter(ngay_dat__date__gte=start_of_month)
        
        # Doanh thu hôm nay
        today_revenue = ChiTietOrder.objects.filter(
            order__order_time__date=today,
            order__trang_thai='completed'
        ).aggregate(total=Sum(F('so_luong') * F('gia')))['total'] or 0
        
        # Doanh thu tháng này
        month_revenue = ChiTietOrder.objects.filter(
            order__order_time__date__gte=start_of_month,
            order__trang_thai='completed'
        ).aggregate(total=Sum(F('so_luong') * F('gia')))['total'] or 0
        
        # Món ăn bán chạy nhất (tháng này)
        top_dishes = ChiTietOrder.objects.filter(
            order__order_time__date__gte=start_of_month,
            order__trang_thai='completed'
        ).values('mon_an__ten_mon', 'mon_an__id').annotate(
            total_sold=Sum('so_luong'),
            revenue=Sum(F('so_luong') * F('gia'))
        ).order_by('-total_sold')[:5]
        
        # Trạng thái bàn hiện tại
        total_tables = BanAn.objects.count()
        occupied_tables = Order.objects.filter(
            loai_order='dine_in',
            trang_thai__in=['pending', 'confirmed', 'cooking', 'ready'],
            order_time__date=today
        ).values('ban_an').distinct().count()
        
        reserved_tables = DonHang.objects.filter(
            trang_thai__in=['pending', 'confirmed'],
            ngay_dat__date=today
        ).values('ban_an').distinct().count()
        
        data = {
            'today': {
                'total_orders': today_orders.count(),
                'completed_orders': today_orders.filter(trang_thai='completed').count(),
                'pending_orders': today_orders.filter(trang_thai='pending').count(),
                'total_reservations': today_reservations.count(),
                'revenue': float(today_revenue),
            },
            'month': {
                'total_orders': month_orders.count(),
                'completed_orders': month_orders.filter(trang_thai='completed').count(),
                'total_reservations': month_reservations.count(),
                'revenue': float(month_revenue),
            },
            'tables': {
                'total': total_tables,
                'occupied': occupied_tables,
                'reserved': reserved_tables,
                'available': total_tables - occupied_tables - reserved_tables,
            },
            'top_dishes': list(top_dishes),
        }
        
        return Response(data)
   
    @action(detail=False, methods=['get'], url_path='orders')
    def order_statistics(self, request):
        """Thống kê đơn hàng theo trạng thái và loại"""
        if request.user.loai_nguoi_dung != 'nhan_vien':
            return Response({'error': 'Chỉ nhân viên mới có quyền xem thống kê'}, status=status.HTTP_403_FORBIDDEN)
        
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        today = timezone.now().date()
        
        if not start_date:
            start_date = today - timedelta(days=7)
        else:
            start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
        
        if not end_date:
            end_date = today
        else:
            end_date = datetime.strptime(end_date, '%Y-%m-%d').date()
        
        # Thống kê theo trạng thái
        orders_by_status = Order.objects.filter(
            order_time__date__gte=start_date,
            order_time__date__lte=end_date
        ).values('trang_thai').annotate(count=Count('id')).order_by('-count')
        
        # Thống kê theo loại đơn
        orders_by_type = Order.objects.filter(
            order_time__date__gte=start_date,
            order_time__date__lte=end_date
        ).values('loai_order').annotate(count=Count('id'))
        
        # Đơn hàng theo nhân viên xử lý
        orders_by_staff = Order.objects.filter(
            order_time__date__gte=start_date,
            order_time__date__lte=end_date,
            nhan_vien__isnull=False
        ).values('nhan_vien__ho_ten', 'nhan_vien__id').annotate(
            total_orders=Count('id'),
            completed_orders=Count('id', filter=Q(trang_thai='completed'))
        ).order_by('-total_orders')[:10]
        
        return Response({
            'start_date': start_date.isoformat(),
            'end_date': end_date.isoformat(),
            'by_status': list(orders_by_status),
            'by_type': list(orders_by_type),
            'by_staff': list(orders_by_staff),
        })


class HoaDonView(viewsets.ReadOnlyModelViewSet):
    queryset = HoaDon.objects.all().select_related('order__khach_hang', 'order__nhan_vien', 'order__ban_an').prefetch_related('order__chitietorder_set__mon_an')
    serializer_class = HoaDonSerializer
    permission_classes = [IsAuthenticated]


class NotificationView(viewsets.ReadOnlyModelViewSet):
    """List notifications for the currently authenticated user."""
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Notification.objects.filter(user=user).order_by('-id')


class KhuyenMaiView(viewsets.ReadOnlyModelViewSet):
    """API lấy danh sách khuyến mãi đang hoạt động và trong thời gian áp dụng"""
    serializer_class = KhuyenMaiSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        from django.utils import timezone
        now = timezone.now()
        return KhuyenMai.objects.filter(
            active=True,
            ngay_bat_dau__lte=now,
            ngay_ket_thuc__gte=now
        ).order_by('-ngay_bat_dau')


def landing_page(request):
    return render(request, 'landing_page.html')


@api_view(['POST'])
def cleanup_socket_sessions(request):
    """
    Force cleanup socket sessions for current user (call this on logout)
    """
    from restaurant.socket_handlers import force_cleanup_user_sessions
    
    try:
        user_id = request.user.id
        cleaned_count = force_cleanup_user_sessions(user_id)
        
        return Response({
            'success': True,
            'message': f'Cleaned up {cleaned_count} socket sessions',
            'user_id': user_id
        }, status=200)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=500)
