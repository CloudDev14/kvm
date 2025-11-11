#!/bin/bash
# Script para verificar la configuración de updates en el dispositivo

echo "╔════════════════════════════════════════════════╗"
echo "║  Verificar Configuración de Updates           ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Solicitar IP si no se proporciona como argumento
if [ -z "$1" ]; then
    read -p "📡 Ingresa la IP del dispositivo: " DEVICE_IP
    if [ -z "$DEVICE_IP" ]; then
        echo "❌ Error: Debes proporcionar una IP"
        exit 1
    fi
else
    DEVICE_IP="$1"
fi

echo ""
echo "🔍 Conectando a: $DEVICE_IP"
echo ""

# Verificar archivo de configuración
echo "📝 Configuración actual:"
ssh root@$DEVICE_IP "cat /userdata/kvm_config.json 2>/dev/null | grep -E '(auto_update|update_metadata)' || echo 'No config file found'"
echo ""

# Verificar versión actual
echo "📦 Versión instalada:"
ssh root@$DEVICE_IP "/oem/jetkvm_app --version 2>/dev/null || echo 'Cannot get version'"
echo ""

# Verificar conectividad a servidor de updates
echo "🌐 Conectividad al servidor de updates:"
ssh root@$DEVICE_IP "wget -q --spider https://api.jetkvm.com/releases && echo '✓ Servidor accesible' || echo '✗ No se puede conectar al servidor'"
echo ""

# Verificar si hay updates disponibles
echo "🔄 Verificando updates disponibles:"
ssh root@$DEVICE_IP "curl -s 'https://api.jetkvm.com/releases?device_id=test&include_pre_release=false' | head -20 || echo '✗ Error al consultar updates'"
echo ""

echo "╔════════════════════════════════════════════════╗"
echo "║  ✓ Verificación Completa                      ║"
echo "╚════════════════════════════════════════════════╝"
