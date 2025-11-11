# Script de Build y Flash para JetKVM

## Descripción

Script automatizado y dinámico para compilar y flashear cambios de UI en el firmware de JetKVM. Detecta automáticamente las ubicaciones de los proyectos y permite personalizar el proceso de build.

## Características

✅ **Auto-detección de directorios**: Encuentra automáticamente los proyectos `kvm` y `rv1106-system`  
✅ **Opciones flexibles**: Permite saltar pasos específicos del proceso  
✅ **Gestión de espacio**: Limpia automáticamente archivos temporales si es necesario  
✅ **Validación de dispositivo**: Verifica que el dispositivo esté en modo DFU antes de flashear  
✅ **Mensajes informativos**: Output con colores y progreso claro  
✅ **Manejo de errores**: Instrucciones claras si algo falla  

## Uso Básico

```bash
# Ejecutar el proceso completo (auto-detecta directorios)
./build_and_flash.sh

# Ver ayuda
./build_and_flash.sh --help
```

## Opciones Disponibles

### Especificar directorios manualmente

```bash
./build_and_flash.sh \
  --kvm-dir /ruta/al/proyecto/kvm \
  --rv1106-dir /ruta/al/proyecto/rv1106-system
```

### Saltar pasos específicos

```bash
# Solo compilar UI y binario, no flashear
./build_and_flash.sh --skip-flash

# Solo construir firmware (si ya compilaste UI y binario)
./build_and_flash.sh --skip-ui --skip-binary

# Solo compilar UI y construir firmware (reusar binario existente)
./build_and_flash.sh --skip-binary
```

### Especificar IP del dispositivo

```bash
./build_and_flash.sh --device-ip 192.168.1.100
```

### Combinar opciones

```bash
./build_and_flash.sh \
  --kvm-dir ~/Projects/kvm \
  --rv1106-dir ~/Projects/rv1106-system \
  --device-ip 192.168.1.100 \
  --skip-flash
```

## Proceso de Build

El script ejecuta los siguientes pasos:

1. **Compilar UI web** (`npm run build:device`)
2. **Compilar binario Go** (`make build_dev`)
3. **Verificar espacio en disco** (limpia si es necesario)
4. **Copiar binario** a las ubicaciones correctas en rv1106-system
5. **Construir firmware** (`./build.sh firmware`)
6. **Flashear dispositivo** (via `upgrade_tool`)

## Auto-detección de Directorios

El script busca los proyectos en las siguientes ubicaciones (en orden):

### Para el proyecto `kvm`:
1. `./kvm/` (relativo al script)
2. `../kvm/` (un nivel arriba)
3. `.` (directorio actual si contiene `ui/package.json`)
4. `~/Desarrollo/kvm`
5. `~/Development/kvm`
6. `~/Projects/kvm`

### Para el proyecto `rv1106-system`:
1. `./rv1106-system/` (relativo al script)
2. `../rv1106-system/` (un nivel arriba)
3. `.` (directorio actual si contiene `build.sh`)
4. `~/Desarrollo/rv1106-system`
5. `~/Development/rv1106-system`
6. `~/Projects/rv1106-system`

## Ejemplos de Uso

### Desarrollo rápido (solo UI)

Si solo modificaste archivos de UI y quieres probar rápido:

```bash
# Compilar UI, reusar binario existente, construir y flashear
./build_and_flash.sh --skip-binary
```

### Build completo sin flashear

Útil si quieres revisar el firmware antes de flashear:

```bash
./build_and_flash.sh --skip-flash

# Después, flashear manualmente:
cd ~/Desarrollo/rv1106-system/tools/linux/Linux_Upgrade_Tool
sudo ./upgrade_tool uf ~/Desarrollo/rv1106-system/output/image/update.img
```

### Solo construir firmware

Si ya tienes el binario compilado y solo necesitas reconstruir el firmware:

```bash
./build_and_flash.sh --skip-ui --skip-binary
```

### Workflow típico de desarrollo

```bash
# 1. Hacer cambios en la UI
vim kvm/ui/src/components/WebRTCVideo.tsx

# 2. Build completo y flash
./build_and_flash.sh

# 3. Esperar 30-60 segundos
# 4. Probar en http://10.1.1.104
```

## Requisitos

- **Node.js** (para compilar la UI)
- **Go** (para compilar el binario)
- **Toolchain ARM** (para cross-compilation)
- **sudo** (para construir firmware y flashear)
- **upgrade_tool** (en rv1106-system/tools/linux/Linux_Upgrade_Tool)

## Modo DFU (Maskrom)

Para flashear el dispositivo, debe estar en modo DFU:

1. **Desconectar** el dispositivo del USB
2. **Mantener presionado** el botón de recuperación
3. **Conectar** el dispositivo al USB mientras mantienes el botón
4. **Soltar** el botón después de 3 segundos

Verificar que está en modo DFU:
```bash
cd ~/Desarrollo/rv1106-system/tools/linux/Linux_Upgrade_Tool
sudo ./upgrade_tool ld
# Debe mostrar: Mode=Maskrom
```

## Solución de Problemas

### Error: "No se pudo detectar el directorio del proyecto kvm"

El script no encontró el proyecto. Especifícalo manualmente:
```bash
./build_and_flash.sh --kvm-dir /ruta/completa/al/proyecto/kvm
```

### Error: "Espacio en disco bajo"

El script intentará limpiar automáticamente. Si persiste:
```bash
# Limpiar manualmente
sudo rm -rf ~/Desarrollo/rv1106-system/output/out/rootfs_uclibc_rv1106
find ~/Desarrollo/rv1106-system/IMAGE -type d -name "RV1106_*" -mtime +1 -delete
```

### Error: "Dispositivo no detectado en modo DFU/Maskrom"

1. Verificar conexión USB
2. Intentar otro puerto USB
3. Repetir el proceso de entrada a modo DFU
4. Verificar con `lsusb | grep 2207`

### El binario es muy pequeño (~25MB en lugar de ~29MB)

Esto indica que la UI no se compiló correctamente. Ejecuta:
```bash
cd ~/Desarrollo/kvm
npm --prefix ui run build:device
make build_dev
ls -lh bin/jetkvm_app  # Debe ser ~29MB
```

### Los cambios no se reflejan después de flashear

1. Verificar que el binario tiene el tamaño correcto (~29MB)
2. Verificar que se copió a las 3 ubicaciones en rv1106-system
3. Verificar que el firmware se construyó DESPUÉS de copiar el binario
4. Limpiar caché del navegador (Ctrl+Shift+R)

## Estructura de Archivos

```
Desarrollo/
├── kvm/                          # Proyecto principal
│   ├── ui/                       # Código fuente de la UI
│   │   ├── src/
│   │   └── package.json
│   ├── bin/
│   │   └── jetkvm_app           # Binario compilado (~29MB)
│   └── Makefile
├── rv1106-system/                # Sistema de firmware
│   ├── project/app/jetkvm/jetkvm/bin/
│   ├── output/
│   │   ├── out/
│   │   │   ├── app_out/install_to_userdata/jetkvm/bin/
│   │   │   └── userdata/jetkvm/bin/
│   │   └── image/
│   │       └── update.img       # Firmware final
│   ├── tools/linux/Linux_Upgrade_Tool/
│   │   └── upgrade_tool
│   └── build.sh
└── build_and_flash.sh            # Este script
```

## Variables de Entorno

Puedes configurar variables de entorno para valores por defecto:

```bash
export JETKVM_DIR="/ruta/al/proyecto/kvm"
export JETKVM_RV1106_DIR="/ruta/al/proyecto/rv1106-system"
export JETKVM_DEVICE_IP="192.168.1.100"

./build_and_flash.sh
```

## Logs y Debugging

Para ver más detalles durante la ejecución:

```bash
# Ver output completo de npm
./build_and_flash.sh 2>&1 | tee build.log

# Ver solo errores
./build_and_flash.sh 2>&1 | grep -i error
```

## Integración con Git

Puedes agregar el script a tu repositorio:

```bash
# Copiar a la raíz del proyecto kvm
cp build_and_flash.sh ~/Desarrollo/kvm/

# Hacer ejecutable
chmod +x ~/Desarrollo/kvm/build_and_flash.sh

# Agregar a git
cd ~/Desarrollo/kvm
git add build_and_flash.sh
git commit -m "Add automated build and flash script"
```

## Mejoras Futuras

- [ ] Soporte para flasheo via red (SSH)
- [ ] Backup automático de firmware anterior
- [ ] Modo watch para recompilar automáticamente
- [ ] Soporte para múltiples dispositivos
- [ ] Integración con CI/CD
- [ ] Verificación de checksums
- [ ] Rollback automático si falla el flash

## Licencia

Este script es parte del proyecto JetKVM y está disponible bajo la misma licencia.

## Contribuciones

Si encuentras bugs o tienes sugerencias:
1. Abre un issue
2. Envía un pull request
3. Documenta los cambios

## Contacto

Para soporte o preguntas, consulta la documentación principal del proyecto JetKVM.
