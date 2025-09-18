
from django.urls import include
from .views import view
from django.urls import path


urlpatterns = [
    path('api/', view),
]
