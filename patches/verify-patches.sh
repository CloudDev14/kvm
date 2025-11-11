#!/bin/bash
set -e

# Script para verificar que los parches se pueden aplicar
# Uso: ./verify-patches.sh [version]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_VERSION="${1:-HEAD}"

echo "╔════════════════════════════════════════════════╗"
echo "║  Verificar Compatibilidad de Parches          ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "🎯 Verificando contra: $TARGET_VERSION"
echo ""

cd "$REPO_ROOT"

# Contar parches
PATCH_COUNT=$(ls -1 "$SCRIPT_DIR"/*.patch 2>/dev/null | wc -l)

if [ "$PATCH_COUNT" -eq 0 ]; then
    echo "❌ No se encontraron parches"
    exit 1
fi

echo "📦 Encontrados $PATCH_COUNT parche(s)"
echo ""

# Verificar cada parche
COMPATIBLE=0
INCOMPATIBLE=0

for patch in "$SCRIPT_DIR"/*.patch; do
    patch_name=$(basename "$patch")
    echo -n "🔍 Verificando $patch_name... "
    
    if git apply --check "$patch" 2>/dev/null; then
        echo "✓ Compatible"
        COMPATIBLE=$((COMPATIBLE + 1))
    else
        echo "❌ Incompatible"
        INCOMPATIBLE=$((INCOMPATIBLE + 1))
        
        # Mostrar detalles del error
        echo "   Detalles:"
        git apply --check "$patch" 2>&1 | head -5 | sed 's/^/   /'
        echo ""
    fi
done

echo ""
echo "═══════════════════════════════════════════════"
echo "📊 Resumen:"
echo "   Compatible:    $COMPATIBLE"
echo "   Incompatible:  $INCOMPATIBLE"
echo "   Total:         $PATCH_COUNT"
echo "═══════════════════════════════════════════════"
echo ""

if [ $INCOMPATIBLE -gt 0 ]; then
    echo "⚠️  Algunos parches no son compatibles"
    echo ""
    echo "💡 Posibles soluciones:"
    echo "   1. Actualizar a la versión correcta:"
    echo "      git checkout release/0.4.7"
    echo ""
    echo "   2. Regenerar los parches:"
    echo "      - Aplicar cambios manualmente"
    echo "      - Crear nuevos parches con create-patch.sh"
    echo ""
    echo "   3. Usar merge de 3 vías:"
    echo "      git apply --3way patches/*.patch"
    echo ""
    exit 1
else
    echo "✓ Todos los parches son compatibles"
    echo ""
    echo "💡 Puedes aplicarlos con:"
    echo "   ./patches/apply-patches.sh"
    echo ""
fi
