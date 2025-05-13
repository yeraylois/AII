from django.db import models
from django.contrib.auth.models import User

# MODEL FOR SURVEY QUESTIONS
class Question(models.Model):
    text = models.CharField(max_length=255)

    def __str__(self):
        return self.text

# MODEL FOR SURVEY RESPONSES
class Response(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    answer_text = models.TextField()
    submitted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.question.text}: {self.answer_text}"
