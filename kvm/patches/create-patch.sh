#!/bin/bash
set -e

# Script para crear un nuevo parche desde los cambios actuales
# Uso: ./create-patch.sh "descripción del parche"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -z "$1" ]; then
    echo "❌ Error: Debes proporcionar una descripción"
    echo "   Uso: $0 \"descripción del parche\""
    echo ""
    echo "   Ejemplo:"
    echo "   $0 \"add custom feature\""
    exit 1
fi

DESCRIPTION="$1"

echo "╔════════════════════════════════════════════════╗"
echo "║  Crear Nuevo Parche                            ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

cd "$REPO_ROOT"

# Verificar que hay cambios
if git diff-index --quiet HEAD --; then
    echo "❌ No hay cambios para crear un parche"
    exit 1
fi

# Mostrar cambios
echo "📝 Cambios detectados:"
git diff --stat
echo ""

# Determinar el siguiente número de parche
LAST_PATCH=$(ls -1 "$SCRIPT_DIR"/*.patch 2>/dev/null | tail -1)
if [ -z "$LAST_PATCH" ]; then
    NEXT_NUM="0001"
else
    LAST_NUM=$(basename "$LAST_PATCH" | sed 's/^\([0-9]\{4\}\).*/\1/')
    NEXT_NUM=$(printf "%04d" $((10#$LAST_NUM + 1)))
fi

# Crear nombre de archivo
PATCH_NAME="${NEXT_NUM}-${DESCRIPTION// /-}.patch"
PATCH_PATH="$SCRIPT_DIR/$PATCH_NAME"

echo "📦 Creando parche: $PATCH_NAME"
echo ""

# Crear el parche
cat > "$PATCH_PATH" << EOF
From: Custom Patches <patches@local>
Date: $(date -R)
Subject: [PATCH $NEXT_NUM] $DESCRIPTION

Custom patch created from local changes.

---
EOF

# Agregar el diff
git diff >> "$PATCH_PATH"

echo "✓ Parche creado: $PATCH_PATH"
echo ""
echo "📊 Estadísticas del parche:"
echo "   Archivos modificados: $(git diff --numstat | wc -l)"
echo "   Líneas agregadas: $(git diff --numstat | awk '{sum+=$1} END {print sum}')"
echo "   Líneas eliminadas: $(git diff --numstat | awk '{sum+=$2} END {print sum}')"
echo ""
echo "💡 Próximos pasos:"
echo "   1. Revisar el parche: cat $PATCH_PATH"
echo "   2. Hacer commit de los cambios: git add . && git commit"
echo "   3. Probar aplicar el parche: git apply --check $PATCH_PATH"
echo ""
