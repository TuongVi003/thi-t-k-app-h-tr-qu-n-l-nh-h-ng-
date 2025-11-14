from django.test import TestCase
from django.utils import timezone
from datetime import timedelta

from .models import BanAn, DonHang, Order, NguoiDung
from .utils import get_table_status_at


class GetTableStatusAtTests(TestCase):
    def setUp(self):
        # create a table and a user for use in reservations/orders
        self.table = BanAn.objects.create(so_ban=1, suc_chua=4)
        self.user = NguoiDung.objects.create_user(
            username='testuser', password='pass', ho_ten='Test User', so_dien_thoai='0123456789'
        )

    def test_available_when_no_reservations_or_orders(self):
        target_dt = timezone.now()
        status = get_table_status_at(self.table, target_dt)
        self.assertEqual(status, 'available')

    def test_occupied_when_reservation_on_date(self):
        target_dt = timezone.now() + timedelta(days=1)
        DonHang.objects.create(
            khach_hang=self.user,
            ban_an=self.table,
            trang_thai='pending',
            ngay_dat=target_dt,
        )
        status = get_table_status_at(self.table, target_dt)
        self.assertEqual(status, 'occupied')

    def test_occupied_when_dine_in_order_on_date(self):
        target_dt = timezone.now() + timedelta(days=2)
        order = Order.objects.create(
            ban_an=self.table,
            khach_hang=self.user,
            loai_order='dine_in',
            trang_thai='pending',
        )
        # order_time is auto_now_add; override to the target datetime for the test
        order.order_time = target_dt
        order.save(update_fields=['order_time'])

        status = get_table_status_at(self.table, target_dt)
        self.assertEqual(status, 'occupied')

    def test_ignores_takeaway_orders(self):
        target_dt = timezone.now() + timedelta(days=3)
        order = Order.objects.create(
            ban_an=self.table,
            khach_hang=self.user,
            loai_order='takeaway',
            trang_thai='pending',
        )
        order.order_time = target_dt
        order.save(update_fields=['order_time'])

        status = get_table_status_at(self.table, target_dt)
        self.assertEqual(status, 'available')

    def test_available_when_reservation_completed(self):
        """Bàn trống khi đơn đặt đã hoàn thành"""
        target_dt = timezone.now() + timedelta(days=1)
        DonHang.objects.create(
            khach_hang=self.user,
            ban_an=self.table,
            trang_thai='completed',
            ngay_dat=target_dt,
        )
        status = get_table_status_at(self.table, target_dt)
        self.assertEqual(status, 'available')

    def test_available_when_reservation_canceled(self):
        """Bàn trống khi đơn đặt đã bị hủy"""
        target_dt = timezone.now() + timedelta(days=1)
        DonHang.objects.create(
            khach_hang=self.user,
            ban_an=self.table,
            trang_thai='canceled',
            ngay_dat=target_dt,
        )
        status = get_table_status_at(self.table, target_dt)
        self.assertEqual(status, 'available')

    def test_available_when_order_completed(self):
        """Bàn trống khi order đã hoàn thành"""
        target_dt = timezone.now() + timedelta(days=1)
        order = Order.objects.create(
            ban_an=self.table,
            khach_hang=self.user,
            loai_order='dine_in',
            trang_thai='completed',
        )
        order.order_time = target_dt
        order.save(update_fields=['order_time'])

        status = get_table_status_at(self.table, target_dt)
        self.assertEqual(status, 'available')

    def test_occupied_with_multiple_statuses(self):
        """Bàn bị chiếm khi có nhiều trạng thái active khác nhau"""
        target_dt = timezone.now() + timedelta(days=1)
        
        # Create order with 'cooking' status
        order = Order.objects.create(
            ban_an=self.table,
            khach_hang=self.user,
            loai_order='dine_in',
            trang_thai='cooking',
        )
        order.order_time = target_dt
        order.save(update_fields=['order_time'])

        status = get_table_status_at(self.table, target_dt)
        self.assertEqual(status, 'occupied')