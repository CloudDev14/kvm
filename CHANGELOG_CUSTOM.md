# Changelog de Modificaciones Personalizadas

Este archivo documenta todas las modificaciones personalizadas realizadas al firmware JetKVM oficial.

## [Custom 1.0.0] - 2025-11-11

### 🎯 Objetivo
Desactivar actualizaciones automáticas por defecto y permitir configurar servidor de actualizaciones personalizado.

### ✨ Cambios Implementados

#### 1. Desactivar Auto-Update por Defecto
- **Archivo**: `config.go`
- **Línea**: 162
- **Cambio**: `AutoUpdateEnabled: false` (antes `true`)
- **Razón**: Preferencia de control manual sobre actualizaciones
- **Impacto**: Los dispositivos nuevos no se actualizarán automáticamente

#### 2. Campo URL de Metadatos Configurable
- **Archivos**: `config.go`, `ota.go`, `jsonrpc.go`
- **Cambios**:
  - Agregado campo `UpdateMetadataURL` a struct `Config`
  - Valor por defecto: `"https://api.jetkvm.com/releases"`
  - Modificado `fetchUpdateMetadata()` para usar URL configurable
  - Agregadas funciones RPC: `rpcGetUpdateMetadataURL()`, `rpcSetUpdateMetadataURL()`
  - Registrados endpoints: `getUpdateMetadataURL`, `setUpdateMetadataURL`
- **Razón**: Permitir apuntar a servidor propio de actualizaciones
- **Impacto**: Posibilidad de distribuir actualizaciones desde infraestructura propia

#### 3. Componente UI para Configuración
- **Archivo**: `ui/src/routes/devices.$id.settings.general._index.tsx`
- **Cambios**:
  - Agregado import de `InputField`
  - Agregado estado para `updateMetadataURL` y `tempUpdateMetadataURL`
  - Agregada función `handleUpdateMetadataURLSave()`
  - Agregado componente visual con input y botón "Save"
- **Ubicación UI**: Settings → General → Update Server URL
- **Razón**: Interfaz gráfica para configurar URL sin editar archivos
- **Impacto**: Usuarios pueden cambiar servidor de updates desde la UI

### 📦 Parches Creados

1. `0001-disable-auto-update-and-add-custom-url.patch`
2. `0002-backend-support-for-custom-update-url.patch`
3. `0003-ui-component-for-update-url.patch`

### 🔧 Scripts de Gestión

- `patches/apply-patches.sh` - Aplicar todos los parches
- `patches/update-and-patch.sh` - Actualizar firmware y re-aplicar parches
- `patches/verify-patches.sh` - Verificar compatibilidad de parches
- `patches/create-patch.sh` - Crear nuevos parches

### 📊 Estadísticas

- **Archivos modificados**: 4
- **Líneas agregadas**: ~80
- **Líneas eliminadas**: ~3
- **Funciones nuevas**: 3 (2 RPC + 1 UI handler)
- **Endpoints RPC nuevos**: 2

### ✅ Testing

- [x] Compilación exitosa
- [x] Flash al dispositivo exitoso
- [x] UI muestra campo correctamente
- [x] Guardar URL funciona
- [x] URL se persiste en config
- [x] Auto-update desactivado por defecto

### 🔄 Compatibilidad

- **Versión base**: `release/0.4.7`
- **Última versión probada**: `release/0.4.7`
- **Próxima actualización**: `release/0.4.9` (pendiente)

### 📝 Notas

- Los parches están diseñados para ser re-aplicables
- Compatible con sistema de configuración existente
- No rompe funcionalidad existente
- Cambios son retrocompatibles

### 🚀 Próximos Pasos

- [ ] Probar actualización a `release/0.4.9`
- [ ] Verificar compatibilidad de parches con nueva versión
- [ ] Actualizar parches si es necesario
- [ ] Documentar cualquier cambio adicional

---

## [Plantilla para Futuras Modificaciones]

```markdown
## [Custom X.Y.Z] - YYYY-MM-DD

### 🎯 Objetivo
Descripción breve del objetivo de los cambios

### ✨ Cambios Implementados

#### 1. Nombre del Cambio
- **Archivo**: `archivo.go`
- **Línea**: XXX
- **Cambio**: Descripción del cambio
- **Razón**: Por qué se hizo
- **Impacto**: Qué efecto tiene

### 📦 Parches Creados
- `000X-nombre-del-parche.patch`

### ✅ Testing
- [ ] Compilación
- [ ] Flash
- [ ] Funcionalidad

### 🔄 Compatibilidad
- **Versión base**: `release/X.Y.Z`
```

---

## 📋 Historial de Versiones

| Versión | Fecha | Cambios | Base |
|---------|-------|---------|------|
| Custom 1.0.0 | 2025-11-11 | Auto-update + URL configurable | 0.4.7 |

---

**Mantenido por**: Tu equipo  
**Última actualización**: 11 de noviembre de 2025
