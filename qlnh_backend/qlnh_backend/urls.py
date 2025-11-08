
from django.urls import include, path
from restaurant.views import CustomTokenView, landing_page
from django.conf import settings
from django.conf.urls.static import static
from restaurant.admin import admin_site


urlpatterns = [
    path('admin/', admin_site.urls),
    path('o/token/', CustomTokenView.as_view(), name='token'),
    path('o/', include('oauth2_provider.urls', namespace='oauth2_provider')),
    path('', landing_page),
    path('api/', include('restaurant.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

