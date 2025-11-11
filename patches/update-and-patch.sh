#!/bin/bash
set -e

# Script para actualizar el firmware y re-aplicar parches
# Uso: ./update-and-patch.sh [version]
# Ejemplo: ./update-and-patch.sh release/0.4.9

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_VERSION="${1:-release/0.4.9}"

echo "╔════════════════════════════════════════════════╗"
echo "║  Actualizar Firmware y Aplicar Parches        ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "🎯 Versión objetivo: $TARGET_VERSION"
echo ""

cd "$REPO_ROOT"

# Verificar que estamos en un repositorio git
if [ ! -d ".git" ]; then
    echo "❌ Error: No se encuentra el repositorio git"
    exit 1
fi

# Guardar el branch actual
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "📍 Branch actual: $CURRENT_BRANCH"

# Verificar que existen los parches
PATCH_COUNT=$(ls -1 "$SCRIPT_DIR"/*.patch 2>/dev/null | wc -l)
if [ "$PATCH_COUNT" -eq 0 ]; then
    echo "❌ Error: No se encontraron parches en $SCRIPT_DIR"
    echo "   Asegúrate de estar en la rama correcta con los parches"
    exit 1
fi

echo "📦 Encontrados $PATCH_COUNT parche(s) para aplicar"
echo ""

# IMPORTANTE: Copiar parches a un directorio temporal
# porque al cambiar de branch desaparecerán
TEMP_PATCHES_DIR=$(mktemp -d)
echo "💾 Copiando parches a directorio temporal..."
cp "$SCRIPT_DIR"/*.patch "$TEMP_PATCHES_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR"/apply-patches.sh "$TEMP_PATCHES_DIR/" 2>/dev/null || true

echo "   ✓ Parches guardados en: $TEMP_PATCHES_DIR"
echo ""

# Verificar si hay cambios sin commit
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Hay cambios sin commit"
    echo "   Opciones:"
    echo "   1. Hacer stash (guardar temporalmente)"
    echo "   2. Hacer commit"
    echo "   3. Cancelar"
    echo ""
    read -p "¿Hacer stash de los cambios? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "💾 Guardando cambios..."
        git stash push -m "Auto-stash before update to $TARGET_VERSION"
        STASHED=1
    else
        echo "❌ Cancelado. Haz commit o stash manualmente"
        rm -rf "$TEMP_PATCHES_DIR"
        exit 1
    fi
fi

# Actualizar repositorio
echo ""
echo "🔄 Actualizando repositorio..."
git fetch --all --tags

# Verificar que la versión existe
if ! git rev-parse "$TARGET_VERSION" >/dev/null 2>&1; then
    echo "❌ Error: La versión $TARGET_VERSION no existe"
    echo "   Versiones disponibles:"
    git tag -l "release/*" | tail -5
    rm -rf "$TEMP_PATCHES_DIR"
    exit 1
fi

# Cambiar a la versión objetivo
echo ""
echo "🔀 Cambiando a $TARGET_VERSION..."
git checkout "$TARGET_VERSION"

# Aplicar parches desde el directorio temporal
echo ""
echo "🔧 Aplicando parches desde directorio temporal..."
APPLIED=0
FAILED=0

for patch in "$TEMP_PATCHES_DIR"/*.patch; do
    if [ -f "$patch" ]; then
        patch_name=$(basename "$patch")
        echo "   Aplicando $patch_name..."
        
        if git apply --check "$patch" 2>/dev/null; then
            if git apply "$patch"; then
                echo "   ✓ $patch_name aplicado exitosamente"
                APPLIED=$((APPLIED + 1))
            else
                echo "   ❌ Error aplicando $patch_name"
                FAILED=$((FAILED + 1))
            fi
        else
            echo "   ⚠️  Conflictos detectados, intentando merge de 3 vías..."
            if git apply --3way "$patch"; then
                echo "   ✓ $patch_name aplicado con merge (revisa conflictos)"
                APPLIED=$((APPLIED + 1))
            else
                echo "   ❌ No se pudo aplicar $patch_name"
                FAILED=$((FAILED + 1))
            fi
        fi
    fi
done

# Limpiar directorio temporal
echo ""
echo "🧹 Limpiando archivos temporales..."
rm -rf "$TEMP_PATCHES_DIR"

# Restaurar stash si se hizo
if [ "${STASHED:-0}" -eq 1 ]; then
    echo ""
    echo "📦 Restaurando cambios guardados..."
    if git stash pop; then
        echo "   ✓ Cambios restaurados"
    else
        echo "   ⚠️  Hay conflictos al restaurar"
        echo "   Revisa y resuelve manualmente"
    fi
fi

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  ✓ Actualización Completada                   ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "📊 Resumen:"
echo "   Versión: $TARGET_VERSION"
echo "   Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "   Commit: $(git rev-parse --short HEAD)"
echo "   Parches aplicados: $APPLIED"
echo "   Parches fallidos: $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
    echo "⚠️  Algunos parches no se pudieron aplicar"
    echo "   Revisa los conflictos manualmente"
    echo ""
fi

echo "💡 Próximos pasos:"
echo "   1. Revisar cambios: git status"
echo "   2. Ver diferencias: git diff"
if [ $FAILED -gt 0 ]; then
    echo "   3. Resolver conflictos si los hay"
fi
echo "   4. Compilar: make build_dev"
echo "   5. Probar el firmware"
echo ""
echo "🔙 Para volver al estado anterior:"
echo "   git checkout $CURRENT_BRANCH"
echo ""
