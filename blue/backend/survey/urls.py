from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    UserRegistrationAPIView,
    QuestionListAPIView,
    ResponseCreateAPIView,
    ResponseBulkCreateAPIView,
    MyTokenObtainPairView  # Vista personalizada para obtener token
)

urlpatterns = [
    path('register/', UserRegistrationAPIView.as_view(), name='register'),
    path('token/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('questions/', QuestionListAPIView.as_view(), name='question-list'),
    path('responses/', ResponseCreateAPIView.as_view(), name='response-create'),
    path('responses/bulk/', ResponseBulkCreateAPIView.as_view(), name='response-bulk-create'),
]