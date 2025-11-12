# JetKVM Releases

## Versión Actual: 0.5.1

**Fecha:** 2025-11-11 18:03:53  
**Descripción:** Versión parcheada basada en 0.5.0: auto-update OFF, custom URL, logo

### Archivos

- `jetkvm_app_0.5.1` - Binario de la aplicación JetKVM
- `releases.json` - Metadata para el sistema de actualizaciones

### Hash SHA256

```
bd054c2d00484306b2f244af89235ca289e9d2ba8229949d752ad262a5e4a76c  jetkvm_app_0.5.1
```

### Instalación Manual

1. Descarga el binario: `jetkvm_app_0.5.1`
2. Verifica el hash: `sha256sum jetkvm_app_0.5.1`
3. Copia al dispositivo: `scp jetkvm_app_0.5.1 root@IP:/userdata/jetkvm/jetkvm_app`
4. Reinicia el servicio

### Configurar Update URL

En el dispositivo JetKVM:
1. Ve a **Settings → General**
2. Configura **Update Server URL**: `https://bitbucket.org/cloudsourceit/releases/downloads/releases.json`
3. Guarda los cambios

## Historial de Versiones

### 0.5.1 - 2025-11-11
- Versión parcheada basada en 0.5.0: auto-update OFF, custom URL, logo
- App version: 0.5.1
- System version: 0.2.7

