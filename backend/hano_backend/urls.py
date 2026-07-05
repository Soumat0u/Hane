"""
URL configuration for hano_backend project.
"""
from django.conf import settings
from django.contrib import admin
from django.urls import path, re_path, include
from django.views.static import serve

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]

# Medya (yüklenen fiş/fatura/proje belgesi vb.) için ayrı bir CDN/depolama
# servisi yok. django.conf.urls.static.static() yalnızca DEBUG=True iken
# urlpattern üretir (Django'nun kendi kısayolu buna göre yazılmış); bu yüzden
# serve view'ı burada DEBUG'a bakılmaksızın elle tanımlıyoruz.
urlpatterns += [
    re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT}),
]
