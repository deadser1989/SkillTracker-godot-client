"""
URL configuration for skill project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.views.generic.base import RedirectView
from skilltree.views import login_view, register_view, catalog_view

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', RedirectView.as_view(url='login/', permanent=False)),
    path('tree/', include('skilltree.urls')),
    path('login/', login_view, name='login'),
    path('register/', register_view, name='register'),
    path('catalog/', catalog_view, name='catalog'),
    
    path('integrations/', include('integrations.urls')),
]
