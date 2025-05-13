#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# TRAP ERRORS AND SHOW LINE NUMBER
trap 'echo "[ERROR] ERROR AT LINE $LINENO."; exit 1' ERR

# DEFINE SCRIPT DIRECTORY AND VARS FILE
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VARS_FILE="$SCRIPT_DIR/.vars"
readonly HOSTS_ENTRY="127.0.0.1 miapp.local"
readonly HOSTS_FILE="/etc/hosts"
readonly HOSTS_BAK_DIR="$HOME/.bluegreen/hosts.bak"
readonly DOCKERFILE="$SCRIPT_DIR/blue/webhook_listener/Dockerfile"
readonly DOCKERFILE_GREEN="$SCRIPT_DIR/green/webhook_listener_green/Dockerfile"

# WRAPPER PARA SED -I PORTABLE (MAC VS LINUX)
function SED_I() {
  OS=$(DETECT_OS)
  if [[ "$OS" == "macos" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# ADJUST DOCKERFILE BASED ON ARCHITECTURE
function ADJUST_DOCKERFILE() {
  local arch files f ln

  arch=$(uname -m)
  echo "[INFO] ARQUITECTURA DETECTADA: $arch"

  files=("$DOCKERFILE" "$DOCKERFILE_GREEN")

  if [[ "$arch" =~ ^(aarch64|arm64)$ ]]; then
    echo "[INFO] CONFIGURANDO AMD64 (23-25) y DESACTIVANDO ARM64 (18–20)…"
    for f in "${files[@]}"; do
      # COMENTAR LÍNEAS 18,19,20 (solo si NO empiezan con '#')
      for ln in 18 19 20; do
        SED_I "${ln}s/^[[:blank:]]*\\([^#]\\)/#\\1/" "$f"
      done
      # DESCOMENTAR LÍNEAS 23,24,25 (solo si empiezan con '#')
      for ln in 23 24 25; do
        SED_I "${ln}s/^#//" "$f"
      done
    done

  elif [[ "$arch" == "x86_64" ]]; then
    echo "[INFO] CONFIGURANDO ARM64 (18-20) y DESACTIVANDO AMD64 (23-25)…"
    for f in "${files[@]}"; do
      # COMENTAR LÍNEAS 23,24,25 (solo si NO empiezan con '#')
      for ln in 23 24 25; do
        SED_I "${ln}s/^[[:blank:]]*\\([^#]\\)/#\\1/" "$f"
      done
      # DESCOMENTAR LÍNEAS 18,19,20 (solo si empiezan con '#')
      for ln in 18 19 20; do
        SED_I "${ln}s/^#//" "$f"
      done
    done

  else
    echo "[WARN] ARQUITECTURA '$arch' NO SOPORTADA: ningún cambio."
  fi

  echo "[OK] DOCKERFILES AJUSTADOS."
}

# PROMPT USER WITH A YES/NO QUESTION
function PROMPT_YES_NO() {
  local MSG="$1" ANS
  while true; do
    read -rp "$MSG [s/n]: " ANS
    case "$ANS" in
      [Ss]) return 0 ;;
      [Nn]) return 1 ;;
      *) echo "RESPONDE s O n." ;;
    esac
  done
}

# INITIALIZE .VARS FILE WITH SECURE PERMISSIONS
function INIT_VARS() {
  touch "$VARS_FILE"
  chmod 600 "$VARS_FILE"
  if ! grep -q '^deploy_env=' "$VARS_FILE"; then
    printf 'deploy_env=init\nrun_tests=false\n' > "$VARS_FILE"
  fi
}

# SHOW THE CURRENT CONTENTS OF THE .VARS FILE
function SHOW_VARS() {
  local inner_width=50 line

  if [[ -f "$VARS_FILE" ]]; then
    printf "┌──────────── CONTENIDO DE .vars ────────────────────┐\n"
    # OPEN FILE WITH READ LOCK
    exec 3< "$VARS_FILE"
    while IFS= read -r line <&3; do
      printf "│ %-*s │\n" "$inner_width" "$line"
    done
    exec 3<&-
  else
    # IF .vars FILE DOES NOT EXIST CREATE IT WITH DEFAULT VALUES
    INIT_VARS
    SHOW_VARS
    return
  fi

  printf "└────────────────────────────────────────────────────┘\n"
}

# SHOW A BIG BANNER
function SHOW_BANNER() {
  clear
  echo "┌────────────────────────────────────────────────────┐"
  echo "│          SISTEMA DE DESPLIEGUE BLUE-GREEN          │"
  echo "└────────────────────────────────────────────────────┘"
}

# DETECT OPERATING SYSTEM
function DETECT_OS() {
  local OS_TYPE
  OS_TYPE=$(uname)
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "macos"
  elif grep -qi 'ubuntu' /etc/os-release; then
    echo "ubuntu"
  elif grep -qi 'fedora' /etc/os-release; then
    echo "fedora"
  else
    echo "unknown"
  fi
}

# OPEN DOCKER DESKTOP IF NOT RUNNING
function OPEN_DOCKER_DESKTOP() {
  OS=$(DETECT_OS)

  if [[ "$OS" == "macos" ]]; then
    if ! pgrep -x "Docker" > /dev/null; then
      echo "[INFO] ABRIENDO DOCKER DESKTOP..."
      open -a "Docker"
      while ! docker system info &>/dev/null; do
        echo "[INFO] ESPERANDO A QUE DOCKER INICIE..."
        sleep 2
      done
      echo "[INFO] DOCKER DESKTOP ESTÁ LISTO."
    else
      echo "[INFO] DOCKER DESKTOP YA ESTÁ ABIERTO."
    fi

  elif [[ "$OS" == "ubuntu" || "$OS" == "fedora" ]]; then
    if ! pgrep -x "dockerd" > /dev/null; then
      echo "[INFO] INICIANDO DOCKER..."
      sudo systemctl start docker
      while ! docker system info &>/dev/null; do
        echo "[INFO] ESPERANDO A QUE DOCKER INICIE..."
        sleep 2
      done
      echo "[INFO] DOCKER ESTÁ LISTO."
    else
      echo "[INFO] DOCKER YA ESTÁ CORRIENDO."
    fi
  else
    echo "[ERROR] SISTEMA OPERATIVO NO SOPORTADO PARA ABRIR DOCKER DESKTOP."
  fi
}

# STOP CONTAINERS BY NAME
function DELETE_CONTAINERS_BY_NAME() {
  local container_names=(
    "frontend-survey-1"
    "webhook"
    "backend-web-1"
    "backend-db-1"
    "backend-postgres_exporter-1"
    "metrics-grafana-1"
    "metrics-prometheus-1"
    "metrics-alertmanager-1"
    "nginx_proxy"
    "frontend_green"
    "grafana_green"
    "prometheus_green"
    "alertmanager_green"
    "backend-green-web_green-1"
    "backend-green-db-green-1"
    "backend-green-postgres_exporter_green-1"
    "webhook_listener_green"
  )

  echo "[INFO] INTENTANDO ELIMINAR LOS CONTENEDORES ESPECIFICADOS..."

  for name in "${container_names[@]}"; do
    container_id=$(docker ps -a --filter "name=^${name}$" --format "{{.ID}}")

    if [[ -n "$container_id" ]]; then
      echo "[INFO] ELIMINANDO CONTENEDOR: $name ($container_id)"
      docker rm -f "$container_id"
      if [[ $? -eq 0 ]]; then
        echo "[OK] CONTENEDOR '$name' ELIMINADO CORRECTAMENTE."
      else
        echo "[ERROR] NO SE PUDO ELIMINAR EL CONTENEDOR '$name'."
      fi
    else
      echo "[WARN] NO SE ENCONTRÓ UN CONTENEDOR CON EL NOMBRE EXACTO: $name"
    fi
  done

  echo "[INFO] ELIMINANDO VOLUMENES HUELLA DE CONTENEDORES ELIMINADOS..."
  docker volume prune -f
  echo "[INFO] LIMPIEZA COMPLETA DE VOLUMENES SIN USO."
}

# DELETE DOCKER VOLUMES AND IMAGES
function DELETE_DOCKER_VOLUMES_AND_IMAGES() {
  local volumes=(
    "metrics_grafana_data"
    "backend_backend_web_data"
    "backend_postgres_data"
    "metrics_green_grafana_data_green"
    "backend-green_backend_web_data_green"
    "backend-green_postgres_data_green"
    "act-toolcache"
  )

  local images=(
    "mysql:8"
    "mysql:8.0"
    "grafana/grafana:latest"
    "ghcr.io/dimitri/pgloader:amd64"
    "frontend-survey:latest"
    "frontend_green-survey_green:latest"
    "catthehacker/ubuntu:amd64"
    "busybox:latest"
    "backend-web:latest"
    "backend-green-web_green:latest"
    "backend-green-mysqld_exporter_green:latest"
    "backend-green-db-green:latest"
  )

  echo "[INFO] ELIMINANDO VOLUMENES ESPECIFICADOS..."

  for volume in "${volumes[@]}"; do
    if docker volume ls --format "{{.Name}}" | grep -q "^${volume}$"; then
      echo "[INFO] ELIMINANDO VOLUMEN: $volume"
      docker volume rm "$volume"
      if [[ $? -eq 0 ]]; then
        echo "[OK] VOLUMEN '$volume' ELIMINADO CORRECTAMENTE."
      else
        echo "[ERROR] NO SE PUDO ELIMINAR EL VOLUMEN '$volume'."
      fi
    else
      echo "[WARN] NO SE ENCONTRÓ EL VOLUMEN: $volume"
    fi
  done

  echo "[INFO] ELIMINANDO IMÁGENES ESPECIFICADAS..."

  for image in "${images[@]}"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
      echo "[INFO] ELIMINANDO IMAGEN: $image"
      docker rmi -f "$image"
      if [[ $? -eq 0 ]]; then
        echo "[OK] IMAGEN '$image' ELIMINADA CORRECTAMENTE."
      else
        echo "[ERROR] NO SE PUDO ELIMINAR LA IMAGEN '$image'."
      fi
    else
      echo "[WARN] NO SE ENCONTRÓ LA IMAGEN: $image"
    fi
  done

  echo "[INFO] LIMPIEZA DE ELEMENTOS NO UTILIZADOS..."
  docker system prune -f
  echo "[OK] LIMPIEZA COMPLETADA."
}

# INSTALL DEPENDENCIES FOR SUPPORTED OS
function INSTALL_DEPENDENCIES() {
  local OS
  OS=$(DETECT_OS)
  if [[ "$OS" == "unknown" ]]; then
    echo "[ERROR] SISTEMA OPERATIVO NO SOPORTADO. ABORTANDO."
    exit 1
  fi

  echo "┌── SISTEMA DETECTADO: $OS ────────────────────────────┐"
  echo "└────────────────────────────────────────────────────────┘"

  case "$OS" in
    macos)
      # CHECK REQUIRED COMMANDS
      for CMD in brew pip3 npm curl; do
        if ! command -v "$CMD" &>/dev/null; then
          echo "[WARN] '$CMD' NO INSTALADO O NO SE ENCUENTRA EN PATH."
        fi
      done
      # INSTALL VIA HOMEBREW
      brew install docker docker-compose node act || exit 1
      pip3 install --user ansible
      npm install -g @angular/cli
      brew install act || exit 1
      ;;
    ubuntu)
      # REQUIRE SUDO
      if ! command -v sudo &>/dev/null; then
        echo "[ERROR] 'sudo' NO DISPONIBLE." >&2
        exit 1
      fi
      sudo apt update  || exit 1
      sudo apt install -y docker.io docker-compose nodejs npm python3-pip git
      pip3 install --user ansible
      sudo npm install -g @angular/cli
      ;;
    fedora)
      sudo dnf update -y   || exit 1
      sudo dnf install -y docker docker-compose nodejs npm python3-pip git
      pip3 install --user ansible
      sudo npm install -g @angular/cli
      ;;
  esac

  echo "INSTALACIÓN COMPLETADA. VERIFICA ERRORES SI LOS HAY."
}

# MODIFY OR CREATE A KEY=VALUE IN .VARS WITH FLOCK
function MODIFY_VARS() {
  local KEY=$1 VALUE=$2
  case "$KEY" in
    deploy_env|run_tests) ;;
    *)
      echo "[ERROR] CLAVE INVÁLIDA: $KEY" >&2
      return 1
      ;;
  esac

  # DEFINIMOS UN LOCKDIR DENTRO DEL MISMO DIRECTORIO
  local LOCKDIR="${VARS_FILE}.lock"

  # ESPERAR HASTA PODER CREAR EL DIRECTORIO (OBTENER EL LOCK)
  while ! mkdir "$LOCKDIR" 2>/dev/null; do
    sleep 0.1
  done

  # UNA VEZ TENEMOS EL LOCK, EDITAMOS .vars
  if grep -q "^${KEY}=" "$VARS_FILE"; then
    sed -i.bak "s/^${KEY}=.*/${KEY}=${VALUE}/" "$VARS_FILE"
  else
    echo "${KEY}=${VALUE}" >> "$VARS_FILE"
  fi

  # LIBERAR EL LOCK
  rmdir "$LOCKDIR"
}

# RUN CI/CD PIPELINE USING ACT
function RUN_PIPELINE() {
  if ! command -v act &>/dev/null; then
    echo "[ERROR] 'act' NO INSTALADO." >&2
    exit 1
  fi
  echo "┌──────── EJECUTANDO PIPELINE CI/CD (act push) ─────┐"
  echo "└───────────────────────────────────────────────────┘"
  act push --container-architecture linux/amd64
}

# SAFE ADD ENTRY TO /ETC/HOSTS WITH BACKUP
function SAFE_ADD_HOSTS_ENTRY() {
  if grep -Fq "$HOSTS_ENTRY" "$HOSTS_FILE"; then
    echo "[INFO] ENTRADA YA EXISTE EN $HOSTS_FILE"
  else
    mkdir -p "$HOSTS_BAK_DIR"
    cp "$HOSTS_FILE" "$HOSTS_BAK_DIR/hosts.$(date +%F_%H%M%S)"
    echo "$HOSTS_ENTRY" | sudo tee -a "$HOSTS_FILE" > /dev/null
    chmod 644 "$HOSTS_FILE"
    echo "[INFO] ENTRADA AÑADIDA Y BACKUP CREADO EN $HOSTS_BAK_DIR"
  fi
}

# DISPLAY MENU OPTIONS
function SHOW_MENU() {
  SHOW_BANNER
  SHOW_VARS
  cat <<'EOF'
┌────────────────────────────────────────────────────┐
│            MENÚ – OPCIONES DE DESPLIEGUE           │
├────────────────────────────────────────────────────┤
│ 1) SET deploy_env = init                           │
│ 2) SET deploy_env = blue                           │
│ 3) SET deploy_env = green                          │
│ 4) SET run_tests = false                           │
│ 5) SET run_tests = true                            │
│ 6) FINISH EDITING AND RUN PIPELINE                 │
│ 7) EXIT WITHOUT RUNNING PIPELINE                   │
└────────────────────────────────────────────────────┘
EOF
  echo -n "> OPCIÓN [1-7]: "
}

# MAIN INTERACTIVE LOOP
function MAIN_MENU() {
  while true; do
    SHOW_MENU
    read -r OPTION
    case $OPTION in
      1) MODIFY_VARS "deploy_env" "init"; echo "deploy_env=init" ;;
      2) MODIFY_VARS "deploy_env" "blue"; echo "deploy_env=blue" ;;
      3) MODIFY_VARS "deploy_env" "green"; echo "deploy_env=green" ;;
      4) MODIFY_VARS "run_tests" "false"; echo "run_tests=false" ;;
      5) MODIFY_VARS "run_tests" "true"; echo "run_tests=true" ;;
      6)
        echo "FINALIZANDO Y EJECUTANDO PIPELINE..."
        RUN_PIPELINE
        ;;
      7)
        echo "SALIENDO SIN EJECUTAR PIPELINE.( + DETENER ENTORNO)"
        DELETE_CONTAINERS_BY_NAME
        DELETE_DOCKER_VOLUMES_AND_IMAGES
        exit 0 ;;
      *) echo "OPCIÓN INVÁLIDA. INTENTA DE NUEVO." ;;
    esac
    echo
    read -rp "PRESIONA ENTER PARA CONTINUAR..." _
  done
}

# PREVENT RUNNING AS ROOT
if [[ "$(id -u)" -eq 0 ]]; then
  echo "[ADVERTENCIA] NO EJECUTES ESTE SCRIPT COMO ROOT."
  exit 1
fi

# ASK TO INSTALL DEPENDENCIES
if PROMPT_YES_NO "¿DESEAS INSTALAR DEPENDENCIAS?"; then
  INSTALL_DEPENDENCIES
fi

# ASK TO ADD HOSTS ENTRY
if PROMPT_YES_NO "¿DESEAS AÑADIR $HOSTS_ENTRY A $HOSTS_FILE?"; then
  SAFE_ADD_HOSTS_ENTRY
fi

# CHECK ARCHITECTURE AND ADJUST DOCKERFILE
if PROMPT_YES_NO "¿DESEAS AJUSTAR EL DOCKERFILE PARA TU ARQUITECTURA?"; then
  ADJUST_DOCKERFILE
fi

if PROMPT_YES_NO "¿DESEAS ABRIR DOCKER DESKTOP (EN CASO DE QUE NO LO POSEA INTRODUCE n?"; then
  OPEN_DOCKER_DESKTOP
fi

# LAUNCH MAIN MENU
 MAIN_MENU
