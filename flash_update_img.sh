#!/bin/bash
#
# Script para flashear un update.img descargado
#

set -e

UPDATE_IMG="${1:-$HOME/Descargas/update.img}"
UPGRADE_TOOL="$HOME/Desarrollo/jetkvm-project/rv1106-system/tools/linux/Linux_Upgrade_Tool/upgrade_tool"

if [ ! -f "$UPDATE_IMG" ]; then
    echo "❌ Error: No se encontró $UPDATE_IMG"
    echo "Uso: $0 [ruta/al/update.img]"
    exit 1
fi

if [ ! -f "$UPGRADE_TOOL" ]; then
    echo "❌ Error: No se encontró upgrade_tool"
    exit 1
fi

echo "╔════════════════════════════════════════════════╗"
echo "║  Flashear update.img                          ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "📦 Imagen: $UPDATE_IMG"
echo "🔧 Tool: $UPGRADE_TOOL"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   1. Desconecta el dispositivo"
echo "   2. Mantén presionado el botón MASKROM"
echo "   3. Conecta el USB mientras mantienes el botón"
echo "   4. Suelta el botón después de 2 segundos"
echo ""
read -p "Presiona Enter cuando el dispositivo esté en modo DFU..."

echo ""
echo "🔍 Detectando dispositivo..."
if ! sudo $UPGRADE_TOOL LD > /dev/null 2>&1; then
    echo "❌ No se detectó dispositivo en modo DFU"
    echo "   Intenta de nuevo el proceso de DFU mode"
    exit 1
fi

echo "✓ Dispositivo detectado"
echo ""
echo "🚀 Iniciando flash..."
sudo $UPGRADE_TOOL UF "$UPDATE_IMG"

if [ $? -eq 0 ]; then
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║                                                ║"
    echo "║  ✓ FLASH COMPLETADO EXITOSAMENTE              ║"
    echo "║                                                ║"
    echo "║  El dispositivo se reiniciará automáticamente ║"
    echo "║  Espera 30-60 segundos antes de acceder       ║"
    echo "║                                                ║"
    echo "╚════════════════════════════════════════════════╝"
else
    echo ""
    echo "❌ Error durante el flash"
    exit 1
fi
