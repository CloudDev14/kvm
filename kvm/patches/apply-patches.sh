#!/bin/bash
set -e

# Script para aplicar todos los parches personalizados
# Uso: ./apply-patches.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "╔════════════════════════════════════════════════╗"
echo "║  Aplicando Parches Personalizados JetKVM      ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

cd "$REPO_ROOT"

# Verificar que estamos en un repositorio git
if [ ! -d ".git" ]; then
    echo "❌ Error: No se encuentra el repositorio git"
    exit 1
fi

# Verificar si hay cambios sin commit
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Advertencia: Hay cambios sin commit"
    echo "   Se recomienda hacer commit o stash antes de aplicar parches"
    read -p "¿Continuar de todas formas? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Contar parches
PATCH_COUNT=$(ls -1 "$SCRIPT_DIR"/*.patch 2>/dev/null | wc -l)

if [ "$PATCH_COUNT" -eq 0 ]; then
    echo "❌ No se encontraron parches en $SCRIPT_DIR"
    exit 1
fi

echo "📦 Encontrados $PATCH_COUNT parche(s)"
echo ""

# Verificar si los parches se pueden aplicar
echo "🔍 Verificando parches..."
FAILED_CHECK=0
for patch in "$SCRIPT_DIR"/*.patch; do
    patch_name=$(basename "$patch")
    if ! git apply --check "$patch" 2>/dev/null; then
        echo "   ❌ $patch_name - No se puede aplicar (conflictos)"
        FAILED_CHECK=1
    else
        echo "   ✓ $patch_name - OK"
    fi
done

if [ $FAILED_CHECK -eq 1 ]; then
    echo ""
    echo "❌ Algunos parches tienen conflictos"
    echo "   Posibles causas:"
    echo "   - El código base ha cambiado"
    echo "   - Los parches ya están aplicados"
    echo "   - Necesitas actualizar los parches"
    echo ""
    echo "   Soluciones:"
    echo "   1. Actualizar a la versión correcta del código"
    echo "   2. Aplicar parches manualmente"
    echo "   3. Regenerar los parches"
    exit 1
fi

echo ""
echo "✓ Todos los parches son compatibles"
echo ""

# Aplicar parches
echo "🔧 Aplicando parches..."
APPLIED=0
for patch in "$SCRIPT_DIR"/*.patch; do
    patch_name=$(basename "$patch")
    echo "   Aplicando $patch_name..."
    if git apply "$patch"; then
        echo "   ✓ $patch_name aplicado"
        APPLIED=$((APPLIED + 1))
    else
        echo "   ❌ Error aplicando $patch_name"
        exit 1
    fi
done

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  ✓ $APPLIED parche(s) aplicado(s) exitosamente    ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "📝 Cambios aplicados:"
git diff --stat
echo ""
echo "💡 Próximos pasos:"
echo "   1. Revisar los cambios: git diff"
echo "   2. Compilar: make build_dev"
echo "   3. Probar el firmware"
echo ""
