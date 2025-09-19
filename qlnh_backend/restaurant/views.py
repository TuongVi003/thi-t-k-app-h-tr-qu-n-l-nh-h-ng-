from django.http import HttpResponse
from rest_framework.response import Response
from django.shortcuts import render
from urllib3 import request
from rest_framework import viewsets, generics

from restaurant.serializer import UserSerializer
from .models import NguoiDung



class UserView(viewsets.ViewSet, generics.CreateAPIView):
    queryset = NguoiDung.objects.all()
    serializer_class = UserSerializer






