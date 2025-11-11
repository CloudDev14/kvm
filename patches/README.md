# Sistema de Gestión de Parches para JetKVM

Este directorio contiene los parches personalizados que modifican el comportamiento del firmware JetKVM.

## 📋 Parches Disponibles

### 1. `0001-disable-auto-update-by-default.patch`
- **Descripción**: Desactiva la actualización automática por defecto
- **Archivos modificados**: `config.go`
- **Razón**: Preferencia de control manual de actualizaciones

### 2. `0002-configurable-update-url.patch`
- **Descripción**: Permite configurar una URL personalizada para el servidor de actualizaciones
- **Archivos modificados**: `config.go`, `ota.go`, `jsonrpc.go`
- **Razón**: Apuntar a servidor propio de actualizaciones

### 3. `0003-update-url-ui-component.patch`
- **Descripción**: Agrega componente UI para configurar la URL de actualizaciones
- **Archivos modificados**: `ui/src/routes/devices.$id.settings.general._index.tsx`
- **Razón**: Interfaz gráfica para cambiar URL de actualizaciones

## 🔧 Uso

### Aplicar todos los parches
```bash
./patches/apply-patches.sh
```

### Aplicar un parche específico
```bash
git apply patches/0001-disable-auto-update-by-default.patch
```

### Verificar si los parches se pueden aplicar
```bash
git apply --check patches/*.patch
```

## 🔄 Actualizar el Firmware y Re-aplicar Parches

### Opción 1: Usar el script automatizado (Recomendado)
```bash
./patches/update-and-patch.sh release/0.4.9
```

**¿Cómo funciona?**
1. ✅ Verifica que existen los parches en tu rama actual
2. 💾 **Copia los parches a un directorio temporal** (importante!)
3. 🔄 Cambia a la versión objetivo (release/0.4.9)
4. 🔧 Aplica los parches desde el directorio temporal
5. 🧹 Limpia archivos temporales
6. 📊 Muestra resumen de parches aplicados/fallidos

**Nota**: El script copia los parches a `/tmp` antes de cambiar de branch, porque al cambiar de branch los archivos de parches desaparecerían.

### Opción 2: Actualización Manual
```bash
# 1. Guardar cambios actuales
git stash

# 2. Actualizar a la última versión
git fetch origin
git checkout release/0.4.9  # o la versión deseada

# 3. Re-aplicar parches manualmente
git apply /ruta/a/parches/*.patch

# 4. Si hay conflictos, resolverlos manualmente
```

## 📝 Crear Nuevos Parches

Cuando hagas cambios personalizados:

```bash
# 1. Hacer tus cambios
# 2. Hacer commit de los cambios
git add .
git commit -m "feat: mi nuevo cambio personalizado"

# 3. Generar el parche
git format-patch -1 HEAD -o patches/

# 4. Renombrar el parche con número secuencial
mv patches/0001-feat-mi-nuevo-cambio.patch patches/0004-mi-nuevo-cambio.patch
```

## ⚠️ Notas Importantes

1. **Orden de aplicación**: Los parches deben aplicarse en orden numérico
2. **Conflictos**: Si hay conflictos al actualizar, revisa manualmente cada archivo
3. **Backup**: Siempre haz backup antes de actualizar
4. **Testing**: Prueba el firmware después de aplicar parches

## 🔍 Verificar Parches Aplicados

```bash
# Ver diferencias con el upstream
git diff origin/release/0.4.9

# Ver commits locales
git log origin/release/0.4.9..HEAD --oneline
```
