from django.contrib.auth.models import User
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from survey.models import Question, Response

# SERIALIZERS FOR USER REGISTRATION AND AUTHENTICATION
class UserRegistrationSerializer(serializers.ModelSerializer):
    password2 = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2']
        extra_kwargs = {'password': {'write_only': True}}

    def validate(self, data):
        if data['password'] != data['password2']:
            raise serializers.ValidationError("Las contraseñas deben coincidir.")
        return data

    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user

# SERIALIZERS FOR SURVEY QUESTIONS AND RESPONSES
class QuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Question
        fields = ['id', 'text']

# SERIALIZER FOR SURVEY RESPONSES
class ResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Response
        fields = ['id', 'question', 'answer_text', 'submitted_at']
        read_only_fields = ['submitted_at']

# SERIALIZER FOR JWT TOKEN
class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Agrega datos personalizados al token
        token['username'] = user.username
        token['email'] = user.email
        token['id'] = user.id
        return token