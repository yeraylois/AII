from rest_framework import generics
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response as DRFResponse
from rest_framework import status
from rest_framework_simplejwt.views import TokenObtainPairView
from .metrics import monitor_view, count_requests
from .serializers import MyTokenObtainPairSerializer
from .models import Question, Response
from .serializers import UserRegistrationSerializer, QuestionSerializer, ResponseSerializer

# VIEW FOR TOKEN AUTHENTICATION
class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer

# VIEW FOR USER REGISTRATION
class UserRegistrationAPIView(generics.CreateAPIView):
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]

# VIEW FOR LISTING QUESTIONS
class QuestionListAPIView(generics.ListAPIView):
    queryset = Question.objects.all()
    serializer_class = QuestionSerializer
    permission_classes = [AllowAny]

# VIEW FOR CREATING RESPONSES
class ResponseCreateAPIView(generics.CreateAPIView):
    queryset = Response.objects.all()
    serializer_class = ResponseSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        # Asigna el usuario autenticado a la respuesta
        serializer.save(user=self.request.user)

# VIEW FOR BULK CREATING RESPONSES
class ResponseBulkCreateAPIView(generics.CreateAPIView):
    queryset = Response.objects.all()
    serializer_class = ResponseSerializer
    permission_classes = [IsAuthenticated]

    @monitor_view(view_name='ResponseBulkCreateAPIView')
    @count_requests(view_name='ResponseBulkCreateAPIView')
    def create(self, request, *args, **kwargs):

        responses_data = request.data.get('responses', [])

        # ASSIGN USER ID TO EACH RESPONSE
        for item in responses_data:
            item['user'] = request.user.id

        serializer = self.get_serializer(data=responses_data, many=True)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return DRFResponse(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        responses = []
        for validated_data in serializer.validated_data:
            response_instance = Response.objects.create(user=self.request.user, **validated_data)
            responses.append(response_instance)
        return responses
