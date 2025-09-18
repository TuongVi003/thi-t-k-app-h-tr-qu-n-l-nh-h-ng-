from django.http import HttpResponse
from django.shortcuts import render
from urllib3 import request

def view(request):
    return HttpResponse('Hello, world. You are at the restaurant index.')


