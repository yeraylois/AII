# OFFICIAL IMAGE
FROM python:3.13-slim

WORKDIR /app

# INSTALL NECESSARY PACKAGES
RUN apt-get update && apt-get install -y \
    gcc \
    libffi-dev \
    libssl-dev \
    python3-dev \
    docker.io \
    curl \
    php-cli \
    && rm -rf /var/lib/apt/lists/*

# FOR AMD64 ARCHITECTURE DEPLOYMENT
#RUN mkdir -p /usr/lib/docker/cli-plugins \
#&& curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64" -o /usr/lib/docker/cli-plugins/docker-compose \
#&& chmod +x /usr/lib/docker/cli-plugins/docker-compose

# FOR ARM64 ARCHITECTURE DEPLOYMENT
RUN mkdir -p /usr/local/lib/docker/cli-plugins && \
curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-aarch64" -o /usr/local/lib/docker/cli-plugins/docker-compose && \
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# COPY THE REQUIREMENTS FILE INTO THE CONTAINER
COPY webhook_listener_green/requirements.txt .

# INSTALLING THE DEPENDENCIES
RUN pip install --no-cache-dir -r requirements.txt

# COPY ALL THE CONTEXT
COPY . .

EXPOSE 8080

# INIT
CMD [ "python", "webhook_listener_green/app.py" ]