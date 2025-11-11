#!/bin/bash
set -e

# Script para regenerar parches para 0.4.9
# Uso: ./regenerate-patches-0.4.9.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "╔════════════════════════════════════════════════╗"
echo "║  Regenerar Parches para 0.4.9                 ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

cd "$REPO_ROOT"

# Backup de parches antiguos
echo "💾 Haciendo backup de parches antiguos..."
mkdir -p "$SCRIPT_DIR/backup-0.4.7"
cp "$SCRIPT_DIR"/*.patch "$SCRIPT_DIR/backup-0.4.7/" 2>/dev/null || true
echo "   ✓ Backup guardado en patches/backup-0.4.7/"
echo ""

# Generar nuevos parches basados en los commits
echo "📦 Generando parches desde commits..."

# Parche 1: Config changes
git diff release/0.4.9 -- config.go > "$SCRIPT_DIR/0001-disable-auto-update-and-add-custom-url-0.4.9.patch.tmp"

# Parche 2: Backend changes  
git diff release/0.4.9 -- ota.go jsonrpc.go > "$SCRIPT_DIR/0002-backend-support-for-custom-update-url-0.4.9.patch.tmp"

# Parche 3: UI changes
git diff release/0.4.9 -- ui/src/routes/devices.\$id.settings.general._index.tsx > "$SCRIPT_DIR/0003-ui-component-for-update-url-0.4.9.patch.tmp"

# Agregar headers a los parches
for patch in "$SCRIPT_DIR"/*.patch.tmp; do
    if [ -f "$patch" ]; then
        patch_name=$(basename "$patch" .tmp)
        final_patch="${patch%.tmp}"
        
        # Determinar el número y nombre
        if [[ $patch_name == *"0001"* ]]; then
            title="Disable auto-update by default and add configurable update URL (0.4.9)"
            desc="- Change AutoUpdateEnabled default from true to false
- Add UpdateMetadataURL field to Config struct  
- Add default value for UpdateMetadataURL

Updated for release/0.4.9 compatibility."
        elif [[ $patch_name == *"0002"* ]]; then
            title="Add backend support for configurable update URL (0.4.9)"
            desc="- Modify fetchUpdateMetadata to use config.UpdateMetadataURL
- Add RPC functions to get/set update metadata URL
- Register new RPC endpoints

Updated for release/0.4.9 compatibility."
        elif [[ $patch_name == *"0003"* ]]; then
            title="Add UI component for configurable update URL (0.4.9)"
            desc="- Add InputField import
- Add state management for update URL
- Add UI component with input field and save button
- Load and save update URL via RPC
- Integrate with localization system (m.*)

Updated for release/0.4.9 compatibility."
        fi
        
        # Crear parche con header
        cat > "$final_patch" << EOF
From: Custom Patches <patches@local>
Date: $(date -R)
Subject: [PATCH] $title

$desc

---
EOF
        cat "$patch" >> "$final_patch"
        rm "$patch"
        
        echo "   ✓ Generado: $(basename "$final_patch")"
    fi
done

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  ✓ Parches Regenerados                        ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "📝 Parches generados:"
ls -lh "$SCRIPT_DIR"/*-0.4.9.patch 2>/dev/null || echo "   (ninguno)"
echo ""
echo "💡 Próximos pasos:"
echo "   1. Revisar parches: cat patches/*-0.4.9.patch"
echo "   2. Verificar: ./patches/verify-patches.sh"
echo "   3. Reemplazar parches antiguos si todo está bien"
echo ""
