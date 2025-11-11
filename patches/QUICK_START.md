# 🚀 Guía Rápida de Parches

## ⚡ Comandos Esenciales

```bash
# En el directorio: /home/clouddev10/Desarrollo/kvm

# 1️⃣ Verificar parches (siempre primero)
./patches/verify-patches.sh

# 2️⃣ Aplicar parches
./patches/apply-patches.sh

# 3️⃣ Actualizar firmware + parches (automático)
./patches/update-and-patch.sh release/0.4.9

# 4️⃣ Crear nuevo parche
./patches/create-patch.sh "descripción"
```

## 📊 Estado Actual

| Item | Valor |
|------|-------|
| **Versión actual** | `release/0.4.7` |
| **Última disponible** | `release/0.4.9` ⚠️ |
| **Parches aplicados** | 3 |
| **Archivos modificados** | 4 |

## 🎯 Tus Modificaciones

✅ **Auto-update desactivado por defecto**
- Archivo: `config.go`
- Antes: `AutoUpdateEnabled: true`
- Ahora: `AutoUpdateEnabled: false`

✅ **URL de updates configurable**
- Archivos: `config.go`, `ota.go`, `jsonrpc.go`
- Nuevo campo: `UpdateMetadataURL`
- Permite apuntar a tu servidor

✅ **UI para configurar URL**
- Archivo: `ui/src/routes/devices.$id.settings.general._index.tsx`
- Campo de input + botón Save
- Ruta: Settings → General → Update Server URL

## 🔄 Actualizar a 0.4.9

### Opción A: Automática (Recomendada)
```bash
cd /home/clouddev10/Desarrollo/kvm
./patches/update-and-patch.sh release/0.4.9
```

### Opción B: Manual
```bash
# 1. Guardar cambios
git stash

# 2. Actualizar
git fetch --tags
git checkout release/0.4.9

# 3. Aplicar parches
./patches/apply-patches.sh

# 4. Compilar
make build_dev
```

## 🆕 Novedades en 0.4.9

- ⚡ **Migración a cgo** - Componente nativo reescrito
- 💤 **Modo suspensión HDMI** - Ahorro de energía
- 🚀 **Paste más rápido** - Mejor rendimiento
- 🐳 **Soporte Podman** - Alternativa a Docker
- 🐛 **Múltiples correcciones** - Bugs resueltos

## 🛠️ Workflow Completo

```bash
# 1. Verificar estado
git status
git describe --tags

# 2. Backup
git branch backup-$(date +%Y%m%d)

# 3. Actualizar
./patches/update-and-patch.sh release/0.4.9

# 4. Compilar
make build_dev

# 5. Flashear
cd /home/clouddev10/Desarrollo
./build_and_flash.sh

# 6. Acceder
# http://10.1.1.104
```

## 🚨 Si Algo Sale Mal

### Conflictos al aplicar parches
```bash
# Ver detalles
git status

# Aplicar con merge
git apply --3way patches/*.patch

# O aplicar manualmente
vim <archivo-con-conflicto>
```

### Volver atrás
```bash
# Volver a versión anterior
git checkout release/0.4.7

# O a tu backup
git checkout backup-20251111
```

### Regenerar parches
```bash
# Si los parches no aplican en nueva versión
# 1. Aplicar cambios manualmente
# 2. Crear nuevos parches
./patches/create-patch.sh "actualizar para 0.4.9"
```

## 📁 Estructura de Parches

```
patches/
├── README.md                    # Documentación completa
├── QUICK_START.md              # Esta guía
├── 0001-*.patch                # Parche 1: Config
├── 0002-*.patch                # Parche 2: Backend
├── 0003-*.patch                # Parche 3: UI
├── apply-patches.sh            # Aplicar todos
├── update-and-patch.sh         # Actualizar + parches
├── verify-patches.sh           # Verificar compatibilidad
└── create-patch.sh             # Crear nuevo parche
```

## 💡 Tips

1. **Siempre verifica primero**: `./patches/verify-patches.sh`
2. **Haz backup**: `git branch backup-$(date +%Y%m%d)`
3. **Prueba en branch**: `git checkout -b test-update`
4. **Lee el changelog**: Ver qué cambió entre versiones
5. **Documenta cambios**: Actualiza esta guía si haces más modificaciones

## 🔗 Enlaces Útiles

- 📦 [Releases oficiales](https://github.com/jetkvm/kvm/releases)
- 📖 [Documentación completa](./README.md)
- 📝 [Guía de parches](../CUSTOM_PATCHES.md)
- 🐛 [Reportar issues](https://github.com/jetkvm/kvm/issues)

---

**Creado**: 11 de noviembre de 2025  
**Versión**: 1.0
