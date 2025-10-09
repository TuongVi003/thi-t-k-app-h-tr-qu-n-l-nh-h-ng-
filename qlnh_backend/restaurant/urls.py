
from django.urls import include
from django.urls import path
from . import views
from rest_framework import routers


router = routers.DefaultRouter()
router.register('users', views.UserView, basename='user')
router.register('donhang', views.DonHangView, basename='donhang')
router.register('tables', views.TableView, basename='table')
router.register('takeaway', views.TakeawayOrderView, basename='takeaway')
router.register('dine-in', views.DineInOrderView, basename='dine-in')
router.register('menu', views.MenuView, basename='menu')
router.register('categories', views.DanhMucView, basename='category')


urlpatterns = [
    path('fcm-token/', views.register_fcm_token, name='fcm-token'),
    path('', include(router.urls)),
    
]
