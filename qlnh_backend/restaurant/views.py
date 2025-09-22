from django.http import HttpResponse
from rest_framework.response import Response
from rest_framework.decorators import action
from django.shortcuts import render
from urllib3 import request
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import viewsets, generics

from restaurant.serializer import UserSerializer, BanAnSerializer, DonHangSerializer
from .models import DonHang, NguoiDung



class UserView(viewsets.ViewSet, generics.CreateAPIView):
    queryset = NguoiDung.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'], url_path='current-user')
    def get_current_user(self, request):
        user = request.user     # object NguoiDung
        serializer = self.get_serializer(user)
        return Response(status=200, data=serializer.data)



class DonHangView(viewsets.ViewSet, generics.ListCreateAPIView):
    queryset = DonHang.objects.all()
    serializer_class = DonHangSerializer
    permission_classes = [IsAuthenticated]   

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response(status=201, data=serializer.data)
        return Response(status=400, data=serializer.errors)



