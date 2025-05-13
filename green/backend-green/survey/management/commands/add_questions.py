# survey/management/commands/add_questions.py
from django.core.management.base import BaseCommand
from survey.models import Question

# ADD PREDEFINED QUESTIONS TO THE DATABASE
class Command(BaseCommand):
    help = 'Add predefined questions to the database'

    def handle(self, *args, **kwargs):
        # Clear all existing questions
        Question.objects.all().delete()

        # Predefined questions to add
        questions = [
            "¿Cuál es tu color favorito?",
            "¿Cuál es tu comida preferida?",
            "¿Qué deporte practicas con más frecuencia?",
            "¿Cuál es tu película favorita?"
        ]

        # Add new questions to the database
        for question_text in questions:
            Question.objects.create(text=question_text)

        self.stdout.write(self.style.SUCCESS('Successfully added questions'))
