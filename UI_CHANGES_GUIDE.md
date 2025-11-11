# Guía de Cambios de UI para JetKVM

## Resumen
Esta guía documenta los cambios realizados para crear una interfaz minimalista con solo el video y el logo de Holo.

## Cambios Aplicados

### 1. WebRTCVideo.tsx (`/home/clouddev10/Desarrollo/kvm/ui/src/components/WebRTCVideo.tsx`)

#### Importar el logo de Holo
```tsx
// Línea ~24
import HoloLogo from "@/assets/holo_logo_white.png";
```

#### Ocultar barra superior de controles
```tsx
// Línea ~487 (buscar: <div className="flex min-h-[39.5px] flex-col">)
// ANTES:
<div className="flex min-h-[39.5px] flex-col">

// DESPUÉS:
<div className="hidden flex min-h-[39.5px] flex-col">
```

#### Agregar logo de Holo centrado en la parte inferior
```tsx
// Línea ~543 (después del elemento </video>)
{/* Watermark logo - centered at bottom of video */}
{isPlaying && !hdmiError && peerConnectionState === "connected" && (
  <img
    src={HoloLogo}
    alt="Holoscopia"
    className="absolute h-8 w-auto opacity-70 pointer-events-none z-20"
    style={{
      maxWidth: '80px',
      filter: 'drop-shadow(0 1px 2px rgba(0, 0, 0, 0.5))',
      bottom: '10px',
      left: '50%',
      transform: 'translateX(-50%)'
    }}
  />
)}
```

#### Ocultar InfoBar inferior
```tsx
// Línea ~584 (buscar: <div><InfoBar /></div>)
// ANTES:
<div>
  <InfoBar />
</div>

// DESPUÉS:
<div className="hidden">
  <InfoBar />
</div>
```

### 2. devices.$id.tsx (`/home/clouddev10/Desarrollo/kvm/ui/src/routes/devices.$id.tsx`)

#### Ocultar DashboardNavbar
```tsx
// Línea ~862 (buscar: <DashboardNavbar)
// ANTES:
<DashboardNavbar
  primaryLinks={isOnDevice ? [] : [{ title: "Cloud Devices", to: "/devices" }]}
  showConnectionStatus={true}
  isLoggedIn={authMode === "password" || !!user}
  userEmail={user?.email}
  picture={user?.picture}
  kvmName={deviceName ?? m.jetkvm_device()}
/>

// DESPUÉS:
<div className="hidden">
  <DashboardNavbar
    primaryLinks={isOnDevice ? [] : [{ title: "Cloud Devices", to: "/devices" }]}
    showConnectionStatus={true}
    isLoggedIn={authMode === "password" || !!user}
    userEmail={user?.email}
    picture={user?.picture}
    kvmName={deviceName ?? m.jetkvm_device()}
  />
</div>
```

### 3. index.css (`/home/clouddev10/Desarrollo/kvm/ui/src/index.css`)

#### Agregar fondo negro
```css
/* Línea ~156 */
html,
body {
  height: 100%;
  width: 100%;
  overflow: auto;
  background-color: black;  /* <- Agregar esta línea */
}
```

### 4. Makefile (`/home/clouddev10/Desarrollo/kvm/Makefile`)

#### Asegurar que la UI se compile antes del binario
```makefile
# Línea ~58 (buscar: build_dev:)
# ANTES:
build_dev: hash_resource

# DESPUÉS:
build_dev: frontend hash_resource
```

## Archivos Necesarios

### Logo de Holo
- **Ubicación**: `/home/clouddev10/Desarrollo/kvm/ui/src/assets/holo_logo_white.png`
- **Formato**: PNG con fondo transparente
- **Tamaño recomendado**: ~116x32 píxeles (se redimensionará automáticamente)
- **Color**: Blanco para contraste con fondo oscuro

## Proceso de Compilación y Flash

### Opción 1: Usar el script automatizado
```bash
cd /home/clouddev10/Desarrollo
chmod +x build_and_flash.sh
./build_and_flash.sh
```

### Opción 2: Proceso manual

#### Paso 1: Compilar UI
```bash
cd /home/clouddev10/Desarrollo/kvm
npm --prefix ui run build:device
```

#### Paso 2: Compilar binario Go
```bash
cd /home/clouddev10/Desarrollo/kvm
make build_dev
```

#### Paso 3: Copiar binario a rv1106-system
```bash
cp /home/clouddev10/Desarrollo/kvm/bin/jetkvm_app \
   /home/clouddev10/Desarrollo/rv1106-system/project/app/jetkvm/jetkvm/bin/

cp /home/clouddev10/Desarrollo/kvm/bin/jetkvm_app \
   /home/clouddev10/Desarrollo/rv1106-system/output/out/app_out/install_to_userdata/jetkvm/bin/

cp /home/clouddev10/Desarrollo/kvm/bin/jetkvm_app \
   /home/clouddev10/Desarrollo/rv1106-system/output/out/userdata/jetkvm/bin/
```

#### Paso 4: Construir firmware
```bash
cd /home/clouddev10/Desarrollo/rv1106-system
sudo ./build.sh firmware
```

#### Paso 5: Flashear dispositivo
```bash
# Poner el dispositivo en modo DFU (Maskrom):
# 1. Desconectar el dispositivo
# 2. Mantener presionado el botón de recuperación
# 3. Conectar el dispositivo mientras se mantiene el botón
# 4. Soltar el botón después de 3 segundos

# Verificar que el dispositivo está en modo DFU
cd /home/clouddev10/Desarrollo/rv1106-system/tools/linux/Linux_Upgrade_Tool
sudo ./upgrade_tool ld

# Flashear
sudo ./upgrade_tool uf /home/clouddev10/Desarrollo/rv1106-system/output/image/update.img
```

## Verificación

Después de flashear, espera 30-60 segundos y accede a `http://10.1.1.104`

### Deberías ver:
- ✅ Fondo completamente negro
- ✅ Solo el video de transmisión
- ✅ Logo de Holo centrado en la parte inferior (cuando el video está reproduciendo)
- ✅ Sin controles visibles (ni arriba ni abajo)
- ✅ Sin barra de navegación

### NO deberías ver:
- ❌ Barra superior con controles
- ❌ Barra inferior (InfoBar)
- ❌ DashboardNavbar
- ❌ Bordes o decoraciones alrededor del video

## Solución de Problemas

### Los cambios no se reflejan después de flashear
1. Verificar que el binario `jetkvm_app` tenga el tamaño correcto (~29MB)
   ```bash
   ls -lh /home/clouddev10/Desarrollo/kvm/bin/jetkvm_app
   ```

2. Verificar que el binario se copió correctamente a rv1106-system
   ```bash
   ls -lh /home/clouddev10/Desarrollo/rv1106-system/output/out/userdata/jetkvm/bin/jetkvm_app
   ```

3. Verificar que el firmware se construyó después de copiar el binario
   ```bash
   ls -lh /home/clouddev10/Desarrollo/rv1106-system/output/image/update.img
   ```

### Error de espacio en disco
```bash
# Limpiar builds antiguos
sudo rm -rf /home/clouddev10/Desarrollo/rv1106-system/output/out/rootfs_uclibc_rv1106

# Limpiar imágenes antiguas
find /home/clouddev10/Desarrollo/rv1106-system/IMAGE -type d -name "RV1106_*" -mtime +1 -exec sudo rm -rf {} +
```

### El dispositivo no se detecta en modo DFU
```bash
# Verificar conexión USB
lsusb | grep 2207

# Si no aparece, intentar:
# 1. Usar otro cable USB
# 2. Usar otro puerto USB
# 3. Reintentar el proceso de entrada a modo DFU
```

## Personalización Adicional

### Cambiar tamaño del logo
Editar en `WebRTCVideo.tsx`:
```tsx
className="absolute h-8 w-auto..."  // h-8 = 32px, cambiar a h-10, h-12, etc.
style={{
  maxWidth: '80px',  // Cambiar el ancho máximo
  ...
}}
```

### Cambiar opacidad del logo
```tsx
className="absolute h-8 w-auto opacity-70..."  // opacity-70 = 70%, cambiar a opacity-50, opacity-90, etc.
```

### Cambiar posición del logo
```tsx
style={{
  bottom: '10px',  // Distancia desde abajo
  left: '50%',     // Centrado horizontal
  transform: 'translateX(-50%)'  // Ajuste para centrado perfecto
}}
```

## Notas Importantes

1. **Siempre compilar la UI antes del binario Go**: El binario Go embebe los archivos estáticos de la UI, por lo que cualquier cambio en la UI debe compilarse primero.

2. **Copiar el binario a las 3 ubicaciones**: El sistema de build de rv1106-system usa múltiples ubicaciones de caché, todas deben actualizarse.

3. **Verificar el tamaño del binario**: Un binario de ~25MB indica que tiene la UI antigua. El binario correcto debe ser ~29MB.

4. **Modo DFU es obligatorio para flashear**: No se puede flashear via SSH, debe ser via upgrade_tool en modo DFU.

5. **El fondo negro en index.css es importante**: Sin esto, se verá el fondo por defecto del navegador.

## Referencias

- Proyecto KVM: `/home/clouddev10/Desarrollo/kvm`
- Sistema RV1106: `/home/clouddev10/Desarrollo/rv1106-system`
- Patch original: `/home/clouddev10/Desarrollo/kvm_local_patch_20251110_100326.diff`
- Script de build: `/home/clouddev10/Desarrollo/build_and_flash.sh`
