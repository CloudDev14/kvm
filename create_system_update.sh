#!/bin/bash
#
# Script para crear el tarball de actualización del sistema
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RV1106_DIR="$SCRIPT_DIR/rv1106-system"
OUTPUT_DIR="$RV1106_DIR/output/image"
RELEASES_DIR="$SCRIPT_DIR/releases"

VERSION="${1}"

if [ -z "$VERSION" ]; then
    # Obtener versión del sistema
    if [ -f "$RV1106_DIR/VERSION" ]; then
        VERSION=$(cat "$RV1106_DIR/VERSION" | tr -d '\n')
    else
        echo "❌ Error: No se pudo determinar la versión del sistema"
        echo "Uso: $0 [VERSION]"
        exit 1
    fi
fi

echo "╔════════════════════════════════════════════════╗"
echo "║  Crear System Update Tarball                  ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "📦 Versión del sistema: $VERSION"
echo ""

# Verificar que existan las imágenes
if [ ! -f "$OUTPUT_DIR/system.img" ]; then
    echo "❌ Error: No se encontró system.img"
    echo "   Ejecuta primero: ./build_and_flash.sh --skip-flash"
    exit 1
fi

if [ ! -f "$OUTPUT_DIR/boot.img" ]; then
    echo "❌ Error: No se encontró boot.img"
    echo "   Ejecuta primero: ./build_and_flash.sh --skip-flash"
    exit 1
fi

# Crear directorio de releases si no existe
mkdir -p "$RELEASES_DIR"

# Nombre del tarball
TARBALL_NAME="update_system_${VERSION}.tar"
TARBALL_PATH="$RELEASES_DIR/$TARBALL_NAME"

echo "🔨 Creando tarball..."
cd "$OUTPUT_DIR"
tar -cf "$TARBALL_PATH" system.img boot.img

if [ ! -f "$TARBALL_PATH" ]; then
    echo "❌ Error: No se pudo crear el tarball"
    exit 1
fi

# Calcular hash
echo "🔐 Calculando hash SHA256..."
TARBALL_HASH=$(sha256sum "$TARBALL_PATH" | cut -d' ' -f1)
TARBALL_SIZE=$(du -h "$TARBALL_PATH" | cut -f1)

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  ✓ System Update Creado                       ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "📦 Archivo: $TARBALL_NAME ($TARBALL_SIZE)"
echo "🔐 Hash: ${TARBALL_HASH:0:16}..."
echo ""
echo "📋 Información para releases.json:"
echo ""
echo "  \"systemVersion\": \"$VERSION\","
echo "  \"systemUrl\": \"https://bitbucket.org/cloudsourceit/releases/downloads/$TARBALL_NAME\","
echo "  \"systemHash\": \"$TARBALL_HASH\""
echo ""
echo "🚀 Próximos pasos:"
echo "   1. Sube $TARBALL_NAME a Bitbucket Downloads"
echo "   2. Actualiza releases.json con la información de arriba"
echo ""
