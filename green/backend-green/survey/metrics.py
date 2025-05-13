from prometheus_client import Histogram, Counter
import time
from functools import wraps

view_request_counter = Counter(
    'django_view_requests_total',
    'Número total de solicitudes recibidas por una vista',
    ['view_name']
)

def count_requests(view_name):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Incrementa el contador para la vista dada.
            view_request_counter.labels(view_name=view_name).inc()
            return func(*args, **kwargs)
        return wrapper
    return decorator

view_latency = Histogram(
    'django_view_latency_seconds',
    'Tiempo de ejecución de la vista',
    ['view_name']
)

def monitor_view(view_name):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                return func(*args, **kwargs)
            finally:
                duration = time.time() - start_time
                view_latency.labels(view_name=view_name).observe(duration)
        return wrapper
    return decorator
