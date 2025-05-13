from django.contrib import admin
from django.urls import path, include

from survey.custom_metrics import custom_metrics_view

# URLS FOR PROJECT
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('survey.urls')),  # ENDPOINTS FOR APPLICATION (API)
    path('', include('django_prometheus.urls')),  # ENDPOINTS FOR PROMETHEUS
    path('metrics', custom_metrics_view, name='custom_metrics'), # ENDPOINT FOR CUSTOM METRICS

]
