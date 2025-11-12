#!/bin/bash
#
# Script para publicar releases de JetKVM
# Genera el binario, calcula hashes y crea releases.json
#
# Uso:
#   ./publish-release.sh 0.4.9-custom.1 "Descripción del release"
#   ./publish-release.sh 0.5.0-custom.2 "Nueva funcionalidad"
#
# Formato de versión: [VERSION_OFICIAL]-custom.[NUMERO_PARCHE]
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="${1}"
DESCRIPTION="${2:-Release $VERSION}"

if [ -z "$VERSION" ]; then
    echo "❌ Error: Debes proporcionar una versión"
    echo ""
    echo "Uso: ./publish-release.sh VERSION \"Descripción\""
    echo ""
    echo "Formato recomendado: [VERSION_OFICIAL]-custom.[NUMERO]"
    echo "Ejemplos:"
    echo "  ./publish-release.sh 0.4.9-custom.1 \"Auto-update OFF\""
    echo "  ./publish-release.sh 0.4.9-custom.2 \"Fix de logo\""
    echo "  ./publish-release.sh 0.5.0-custom.1 \"Basado en 0.5.0\""
    exit 1
fi

# Remover 'v' si existe para el número de versión
VERSION_NUMBER="${VERSION#v}"

echo "╔════════════════════════════════════════════════╗"
echo "║  Publicar Release JetKVM                      ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "📦 Versión: $VERSION"
echo "📝 Descripción: $DESCRIPTION"
echo ""

# Paso 1: Compilar el binario con la versión correcta
echo "🔨 Paso 1/5: Compilando binario con versión $VERSION_NUMBER..."
cd "$SCRIPT_DIR/kvm"

# Modificar temporalmente el Makefile para usar la versión correcta
sed -i.bak "s/^VERSION := .*/VERSION := $VERSION_NUMBER/" Makefile

# Compilar usando el Makefile (que tiene el cross-compiler configurado)
make build_release > /dev/null 2>&1

# Restaurar el Makefile original
mv Makefile.bak Makefile

BINARY_PATH="$SCRIPT_DIR/kvm/bin/jetkvm_app"

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Error: No se encontró el binario en $BINARY_PATH"
    exit 1
fi

BINARY_SIZE=$(du -h "$BINARY_PATH" | cut -f1)
echo "   ✓ Binario compilado ($BINARY_SIZE)"

# Paso 2: Calcular hash SHA256
echo "🔐 Paso 2/5: Calculando hash SHA256..."
BINARY_HASH=$(sha256sum "$BINARY_PATH" | cut -d' ' -f1)
echo "   ✓ Hash: ${BINARY_HASH:0:16}..."

# Paso 3: Copiar binario a directorio de releases
RELEASES_DIR="$SCRIPT_DIR/releases"
mkdir -p "$RELEASES_DIR"

BINARY_NAME="jetkvm_app_${VERSION_NUMBER}"
BINARY_RELEASE_PATH="$RELEASES_DIR/$BINARY_NAME"

cp "$BINARY_PATH" "$BINARY_RELEASE_PATH"
echo "📁 Paso 3/5: Binario copiado a releases/"
echo "   ✓ $BINARY_NAME"

# Paso 4: Generar releases.json
echo "📄 Paso 4/5: Generando releases.json..."

# Obtener versión del sistema desde rv1106-system/VERSION
SYSTEM_VERSION="unknown"
if [ -f "$SCRIPT_DIR/rv1106-system/VERSION" ]; then
    SYSTEM_VERSION=$(cat "$SCRIPT_DIR/rv1106-system/VERSION" | tr -d '\n')
fi

# URL base de Bitbucket Downloads para binarios
DOWNLOAD_BASE_URL="${DOWNLOAD_BASE_URL:-https://bitbucket.org/cloudsourceit/releases/downloads}"

# NOTA: Para el releases.json, usa Bitbucket Snippets en lugar de Downloads
# Crea un snippet público y usa la URL raw, por ejemplo:
# https://bitbucket.org/snippets/cloudsourceit/XXXXX/raw/HASH/releases.json

cat > "$RELEASES_DIR/releases.json" << EOF
{
  "appVersion": "$VERSION_NUMBER",
  "appUrl": "$DOWNLOAD_BASE_URL/$BINARY_NAME",
  "appHash": "$BINARY_HASH",
  "systemVersion": "$SYSTEM_VERSION",
  "systemUrl": "",
  "systemHash": ""
}
EOF

echo "   ✓ releases.json generado"

# Paso 5: Crear README con instrucciones
cat > "$RELEASES_DIR/README.md" << EOF
# JetKVM Releases

## Versión Actual: $VERSION

**Fecha:** $(date +"%Y-%m-%d %H:%M:%S")  
**Descripción:** $DESCRIPTION

### Archivos

- \`$BINARY_NAME\` - Binario de la aplicación JetKVM
- \`releases.json\` - Metadata para el sistema de actualizaciones

### Hash SHA256

\`\`\`
$BINARY_HASH  $BINARY_NAME
\`\`\`

### Instalación Manual

1. Descarga el binario: \`$BINARY_NAME\`
2. Verifica el hash: \`sha256sum $BINARY_NAME\`
3. Copia al dispositivo: \`scp $BINARY_NAME root@IP:/userdata/jetkvm/jetkvm_app\`
4. Reinicia el servicio

### Configurar Update URL

En el dispositivo JetKVM:
1. Ve a **Settings → General**
2. Configura **Update Server URL**: \`$DOWNLOAD_BASE_URL/releases.json\`
3. Guarda los cambios

## Historial de Versiones

### $VERSION - $(date +"%Y-%m-%d")
- $DESCRIPTION
- App version: $VERSION_NUMBER
- System version: $SYSTEM_VERSION

EOF

echo "   ✓ README.md generado"

# Resumen
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  ✓ Release Preparado                          ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "📦 Archivos generados en: releases/"
echo "   - $BINARY_NAME ($BINARY_SIZE)"
echo "   - releases.json"
echo "   - README.md"
echo ""
echo "🚀 Próximos pasos:"
echo ""
echo "1. Subir archivos a Bitbucket Downloads:"
echo "   - Ve a tu repo en Bitbucket"
echo "   - Downloads → Add files"
echo "   - Sube: releases/$BINARY_NAME y releases/releases.json"
echo ""
echo "2. Actualizar DOWNLOAD_BASE_URL en este script con la URL real"
echo ""
echo "3. Configurar en dispositivos:"
echo "   Update Server URL: $DOWNLOAD_BASE_URL/releases.json"
echo ""
echo "💡 Tip: Puedes usar Bitbucket Pipelines para automatizar esto"
echo ""
