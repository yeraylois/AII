# survey/apps.py
from django.apps import AppConfig
import os
from .custom_metrics import set_active_backend

class SurveyConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'survey'

    def ready(self):
        # OBTAINS THE DATABASE ENGINE FROM ENVIRONMENT VARIABLE (DEFAULT 'POSTGRESQL')
        db_engine = os.environ.get("DATABASE_ENGINE", "postgresql")
        set_active_backend(db_engine)