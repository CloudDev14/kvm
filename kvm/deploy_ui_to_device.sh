#!/bin/bash
#
# Script para desplegar solo la UI al dispositivo JetKVM
# Útil para desarrollo rápido sin recompilar todo el firmware
#
# Uso:
#   ./deploy_ui_to_device.sh [IP_DISPOSITIVO]
#
# Ejemplo:
#   ./deploy_ui_to_device.sh 10.1.1.104
#   ./deploy_ui_to_device.sh              # Te preguntará la IP
#
# Requisitos:
#   - Acceso SSH al dispositivo como root
#   - UI compilada (npm run build:device en el directorio ui/)
#

set -e

# Detectar directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
REMOTE_USER="root"
LOCAL_STATIC_DIR="$SCRIPT_DIR/static"
REMOTE_STATIC_DIR="/userdata/jetkvm/resource/static"

# Solicitar IP si no se proporciona como argumento
if [ -z "$1" ]; then
    read -p "📡 Ingresa la IP del dispositivo JetKVM: " REMOTE_IP
    if [ -z "$REMOTE_IP" ]; then
        echo "❌ Error: Debes proporcionar una IP"
        exit 1
    fi
else
    REMOTE_IP="$1"
fi

echo "╔════════════════════════════════════════════════╗"
echo "║  Desplegar UI a Dispositivo JetKVM            ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "🎯 Target: $REMOTE_USER@$REMOTE_IP"
echo "📁 Local UI: $LOCAL_STATIC_DIR"
echo "📂 Remote path: $REMOTE_STATIC_DIR"
echo ""

# Check if static directory exists
if [ ! -d "$LOCAL_STATIC_DIR" ]; then
    echo "❌ Error: Directorio static no encontrado en $LOCAL_STATIC_DIR"
    echo "💡 Por favor ejecuta primero: cd ui && npm run build:device"
    exit 1
fi

# Function to transfer directory via tar+ssh
transfer_directory() {
    local local_dir="$1"
    local remote_dir="$2"
    
    echo "📦 Transfiriendo archivos..."
    
    # Create remote directory and transfer files
    tar -czf - -C "$local_dir" . | ssh "$REMOTE_USER@$REMOTE_IP" "
        mkdir -p '$remote_dir' && \
        cd '$remote_dir' && \
        tar -xzf - && \
        echo '   ✓ Archivos extraídos exitosamente'
    "
}

# Stop the jetkvm service
echo "⏸️  Deteniendo servicio jetkvm..."
ssh "$REMOTE_USER@$REMOTE_IP" "pkill -9 jetkvm_app || true"
sleep 2

# Backup existing static directory
echo "💾 Creando backup del directorio static..."
ssh "$REMOTE_USER@$REMOTE_IP" "
    if [ -d '$REMOTE_STATIC_DIR' ]; then
        cp -r '$REMOTE_STATIC_DIR' '${REMOTE_STATIC_DIR}.backup.\$(date +%Y%m%d_%H%M%S)'
        echo '   ✓ Backup creado'
    fi
"

# Transfer new static files
transfer_directory "$LOCAL_STATIC_DIR" "$REMOTE_STATIC_DIR"

# Restart the jetkvm service
echo "🔄 Reiniciando servicio jetkvm..."
ssh "$REMOTE_USER@$REMOTE_IP" "
    cd /userdata/jetkvm && \
    nohup ./jetkvm_app > /dev/null 2>&1 &
"

sleep 3

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  ✓ Despliegue Completado                      ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "🌐 Accede al dispositivo en: http://$REMOTE_IP"
echo ""
