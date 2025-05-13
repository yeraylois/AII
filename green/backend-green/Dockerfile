# OFFICIAL IMAGE
FROM python:3.13-slim

# INSTALL NECESSARY PACKAGES
RUN apt-get update && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# SETTING THE WORKING DIRECTORY
WORKDIR /app

# COPYING THE REQUIREMENTS FILE INTO THE CONTAINER
COPY requirements.txt .

# INSTALLING THE DEPENDENCIES
RUN pip install -r requirements.txt

# COPYING THE REST OF THE APPLICATION CODE
COPY . .

COPY wait-for-it.sh /wait-for-it.sh
RUN chmod +x /wait-for-it.sh

COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]

# RUN THE APP
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
