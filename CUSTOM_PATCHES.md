# 🔧 Guía de Gestión de Parches Personalizados

Esta guía te ayuda a mantener tus modificaciones personalizadas cuando actualizas el firmware JetKVM.

## 📋 Resumen Rápido

```bash
# Verificar parches
./patches/verify-patches.sh

# Aplicar todos los parches
./patches/apply-patches.sh

# Actualizar firmware y aplicar parches
./patches/update-and-patch.sh release/0.4.9

# Crear nuevo parche
./patches/create-patch.sh "mi nuevo cambio"
```

## 🎯 Tus Modificaciones Actuales

### 1. Actualización Automática Desactivada
- **Archivo**: `config.go`
- **Cambio**: `AutoUpdateEnabled: false` (antes era `true`)
- **Razón**: Control manual de actualizaciones

### 2. URL de Actualizaciones Configurable
- **Archivos**: `config.go`, `ota.go`, `jsonrpc.go`
- **Cambio**: Campo `UpdateMetadataURL` configurable
- **Razón**: Apuntar a servidor propio de actualizaciones

### 3. Interfaz UI para URL de Actualizaciones
- **Archivo**: `ui/src/routes/devices.$id.settings.general._index.tsx`
- **Cambio**: Campo de input y botón para cambiar URL
- **Razón**: Configuración visual desde la UI

## 🔄 Flujo de Actualización

### Escenario 1: Actualización Simple (Sin Conflictos)

```bash
# 1. Verificar versión actual
git describe --tags

# 2. Ver versiones disponibles
git fetch --tags
git tag -l "release/*" | tail -5

# 3. Actualizar y aplicar parches automáticamente
./patches/update-and-patch.sh release/0.4.9

# 4. Compilar y probar
make build_dev
./build_and_flash.sh
```

### Escenario 2: Actualización con Conflictos

```bash
# 1. Intentar actualización automática
./patches/update-and-patch.sh release/0.4.9

# 2. Si hay conflictos, revisar archivos
git status

# 3. Resolver conflictos manualmente
# Editar archivos marcados con conflictos

# 4. Marcar como resueltos
git add <archivo-resuelto>

# 5. Continuar
git am --continue  # o git rebase --continue si aplica

# 6. Compilar y probar
make build_dev
```

### Escenario 3: Actualización Manual

```bash
# 1. Guardar cambios actuales
git stash

# 2. Actualizar a nueva versión
git fetch --tags
git checkout release/0.4.9

# 3. Aplicar parches uno por uno
git apply patches/0001-*.patch
git apply patches/0002-*.patch
git apply patches/0003-*.patch

# 4. Si hay conflictos, usar merge de 3 vías
git apply --3way patches/0001-*.patch

# 5. Restaurar otros cambios si los había
git stash pop
```

## 📝 Crear Nuevos Parches

Cuando hagas cambios adicionales:

```bash
# 1. Hacer tus modificaciones
vim config.go

# 2. Verificar cambios
git diff

# 3. Crear parche automáticamente
./patches/create-patch.sh "agregar nueva funcionalidad"

# 4. El parche se guarda en patches/000X-*.patch
```

## 🔍 Verificar Estado

### Ver diferencias con upstream
```bash
# Comparar con versión oficial
git diff origin/release/0.4.9

# Ver solo archivos modificados
git diff --name-only origin/release/0.4.9
```

### Ver parches aplicados
```bash
# Listar parches
ls -lh patches/*.patch

# Ver contenido de un parche
cat patches/0001-*.patch

# Ver estadísticas
git diff --stat origin/release/0.4.9
```

## 🚨 Solución de Problemas

### Problema: "Patch does not apply"

**Causa**: El código base ha cambiado y el parche no es compatible.

**Solución**:
```bash
# Opción 1: Usar merge de 3 vías
git apply --3way patches/0001-*.patch

# Opción 2: Aplicar manualmente
# 1. Ver qué cambios hace el parche
cat patches/0001-*.patch

# 2. Aplicar cambios manualmente en los archivos
# 3. Regenerar el parche
./patches/create-patch.sh "actualizar parche"
```

### Problema: "Conflictos al hacer stash pop"

**Causa**: Cambios locales conflictúan con la nueva versión.

**Solución**:
```bash
# Ver conflictos
git status

# Resolver manualmente cada archivo
vim <archivo-con-conflicto>

# Marcar como resuelto
git add <archivo>

# Limpiar stash
git stash drop
```

### Problema: "No se puede compilar después de aplicar parches"

**Causa**: Incompatibilidad de API o dependencias.

**Solución**:
```bash
# 1. Verificar errores de compilación
make build_dev 2>&1 | tee build.log

# 2. Revisar cambios en la API
git log --oneline origin/release/0.4.7..origin/release/0.4.9

# 3. Actualizar código según nuevas APIs
# 4. Regenerar parches
```

## 📚 Comandos Útiles

```bash
# Ver historial de commits
git log --oneline --graph --all -10

# Ver cambios entre versiones
git diff release/0.4.7..release/0.4.9

# Buscar en el historial
git log --grep="update" --oneline

# Ver archivos modificados en un commit
git show --name-only <commit-hash>

# Deshacer último commit (mantener cambios)
git reset --soft HEAD~1

# Deshacer cambios en un archivo
git checkout -- <archivo>

# Ver ramas remotas
git branch -r

# Actualizar referencias remotas
git fetch --all --prune
```

## 🎓 Mejores Prácticas

1. **Siempre verifica antes de aplicar**
   ```bash
   ./patches/verify-patches.sh
   ```

2. **Haz backup antes de actualizar**
   ```bash
   git branch backup-$(date +%Y%m%d)
   ```

3. **Prueba en un branch separado**
   ```bash
   git checkout -b test-update-0.4.9
   ./patches/update-and-patch.sh release/0.4.9
   ```

4. **Documenta tus cambios**
   - Agrega comentarios en el código
   - Actualiza README.md si es necesario
   - Mantén un changelog de tus modificaciones

5. **Mantén parches pequeños y específicos**
   - Un parche por funcionalidad
   - Facilita la resolución de conflictos
   - Más fácil de mantener

## 📊 Estado Actual

- **Versión base**: `release/0.4.7`
- **Última versión disponible**: `release/0.4.9`
- **Parches aplicados**: 3
- **Archivos modificados**: 4

## 🔗 Referencias

- [Repositorio oficial JetKVM](https://github.com/jetkvm/kvm)
- [Releases](https://github.com/jetkvm/kvm/releases)
- [Documentación Git](https://git-scm.com/doc)
- [Guía de parches Git](https://git-scm.com/docs/git-format-patch)

---

**Última actualización**: 11 de noviembre de 2025
