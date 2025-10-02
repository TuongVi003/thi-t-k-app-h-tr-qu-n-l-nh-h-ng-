
from django.urls import include
from django.urls import path
from . import views
from rest_framework import routers


router = routers.DefaultRouter()
router.register('users', views.UserView, basename='user')
router.register('donhang', views.DonHangView, basename='donhang')
router.register('tables', views.TableView, basename='table')
router.register('takeaway', views.TakeawayOrderView, basename='takeaway')
router.register('menu', views.MenuView, basename='menu')
router.register('categories', views.DanhMucView, basename='category')


urlpatterns = [
    path('', include(router.urls)),
]
