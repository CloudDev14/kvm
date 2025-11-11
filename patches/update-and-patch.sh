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

# Verificar si hay cambios sin commit
if ! git diff-index --quiet HEAD --; then
    echo ""
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
    exit 1
fi

# Cambiar a la versión objetivo
echo ""
echo "🔀 Cambiando a $TARGET_VERSION..."
git checkout "$TARGET_VERSION"

# Aplicar parches
echo ""
if [ -f "$SCRIPT_DIR/apply-patches.sh" ]; then
    "$SCRIPT_DIR/apply-patches.sh"
else
    echo "⚠️  No se encontró apply-patches.sh"
    echo "   Aplicando parches manualmente..."
    
    for patch in "$SCRIPT_DIR"/*.patch; do
        if [ -f "$patch" ]; then
            patch_name=$(basename "$patch")
            echo "   Aplicando $patch_name..."
            if git apply "$patch" 2>/dev/null; then
                echo "   ✓ $patch_name aplicado"
            else
                echo "   ❌ Error aplicando $patch_name"
                echo ""
                echo "   Posibles conflictos. Aplicando con 3-way merge..."
                if git apply --3way "$patch"; then
                    echo "   ✓ Aplicado con merge (revisa conflictos)"
                else
                    echo "   ❌ No se pudo aplicar. Revisa manualmente"
                fi
            fi
        fi
    done
fi

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
echo "📊 Estado actual:"
echo "   Versión: $TARGET_VERSION"
echo "   Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "   Commit: $(git rev-parse --short HEAD)"
echo ""
echo "💡 Próximos pasos:"
echo "   1. Revisar cambios: git status"
echo "   2. Resolver conflictos si los hay"
echo "   3. Compilar: make build_dev"
echo "   4. Probar el firmware"
echo ""
echo "🔙 Para volver al estado anterior:"
echo "   git checkout $CURRENT_BRANCH"
echo ""
