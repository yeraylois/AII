from prometheus_client import Gauge, generate_latest, CONTENT_TYPE_LATEST
from django.http import HttpResponse

# DEFINE THE Gauge FOR THE ACTIVE BACKEND
active_backend = Gauge('active_backend', 'Indica el motor de base de datos activo', ['engine'])

def set_active_backend(engine):
    """
    Establece active_backend de la siguiente forma:
      - Si engine es "postgres" o "postgresql": active_backend{engine="postgres"}=1 y active_backend{engine="mysql"}=0.
      - Si engine es "mysql": active_backend{engine="mysql"}=1 y active_backend{engine="postgres"}=0.
      - En caso contrario, ambas se ponen en 0.
    """

    """ 
    Sets active_backend as follows:
        - If engine is "postgres" or "postgresql": active_backend{engine="postgres"}=1 and active_backend{engine="mysql"}=0.
        - If engine is "mysql": active_backend{engine="mysql"}=1 and active_backend{engine="postgres"}=0.
        - Otherwise, both are set to 0.
    """

    engine = engine.lower()
    if engine in ["postgresql", "postgres"]:
        active_backend.labels(engine="postgres").set(1)
        active_backend.labels(engine="mysql").set(0)
    elif engine == "mysql":
        active_backend.labels(engine="postgres").set(0)
        active_backend.labels(engine="mysql").set(1)
    else:
        active_backend.labels(engine="postgres").set(0)
        active_backend.labels(engine="mysql").set(0)

def custom_metrics_view(request):
    # VIEW FOR PROMETHEUS TO ACCESS THE PERSONALIZED METRICS
    output = generate_latest(active_backend)
    return HttpResponse(output, content_type=CONTENT_TYPE_LATEST)