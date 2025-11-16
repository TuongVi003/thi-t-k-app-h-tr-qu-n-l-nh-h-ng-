
from django.urls import include
from django.urls import path
from . import views
from .chat_views import ConversationViewSet, ChatMessageViewSet
from rest_framework import routers


router = routers.DefaultRouter()
router.register('users', views.UserView, basename='user')
router.register('donhang', views.DonHangView, basename='donhang')
router.register('tables', views.TableView, basename='table')
router.register('takeaway', views.TakeawayOrderView, basename='takeaway')
router.register('dine-in', views.DineInOrderView, basename='dine-in')
router.register('menu', views.MenuView, basename='menu')
router.register('categories', views.DanhMucView, basename='category')
router.register('about-us', views.AboutUsView, basename='about-us')
router.register('tables-for-reservations', views.UserTableView, basename='tfr')
router.register('statistics', views.StatisticsView, basename='statistics')
router.register('hoadon', views.HoaDonView, basename='hoadon')
router.register('notifications', views.NotificationView, basename='notification')
router.register('khuyenmai', views.KhuyenMaiView, basename='khuyenmai')

# Chat endpoints
router.register('conversations', ConversationViewSet, basename='conversation')
router.register('messages', ChatMessageViewSet, basename='message')


urlpatterns = [
    path('fcm-token/', views.register_fcm_token, name='fcm-token'),
    path('cleanup-socket/', views.cleanup_socket_sessions, name='cleanup-socket'),
    path('', include(router.urls)),
    
]
