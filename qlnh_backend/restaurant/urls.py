
from django.urls import include
from django.urls import path
from . import views
from rest_framework import routers


router = routers.DefaultRouter()
router.register('users', views.UserView, basename='user')
router.register('donhang', views.DonHangView, basename='donhang')

urlpatterns = [
    path('api/', include(router.urls)),
]
