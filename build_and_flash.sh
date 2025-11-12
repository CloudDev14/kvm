#!/bin/bash
#
# Script para compilar y flashear cambios de UI en JetKVM
# Autor: Asistente Cascade
# Fecha: 2025-11-10
#
# Este script automatiza el proceso completo de:
# 1. Compilar la UI web
# 2. Compilar el binario Go con la UI embebida
# 3. Copiar el binario a las ubicaciones correctas en rv1106-system
# 4. Construir el firmware
# 5. Flashear el dispositivo
#
# Uso:
#   ./build_and_flash.sh [opciones]
#
# Opciones:
#   --kvm-dir PATH        Directorio del proyecto kvm (default: auto-detectar)
#   --rv1106-dir PATH     Directorio del proyecto rv1106-system (default: auto-detectar)
#   --skip-ui             Saltar compilación de UI
#   --skip-binary         Saltar compilación del binario Go
#   --skip-flash          Solo construir firmware, no flashear
#   --device-ip IP        IP del dispositivo para verificación (default: 10.1.1.104)
#   --version VERSION     Versión a compilar (default: dev con timestamp)
#   --help                Mostrar esta ayuda
#

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables configurables
SKIP_UI=false
SKIP_BINARY=false
SKIP_FLASH=false
DEVICE_IP="10.1.1.104"
KVM_DIR=""
RV1106_DIR=""
BUILD_VERSION=""

# Función para detectar directorios automáticamente
detect_directories() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Intentar detectar KVM_DIR
    if [ -z "$KVM_DIR" ]; then
        # Buscar en el directorio actual
        if [ -f "$script_dir/kvm/ui/package.json" ]; then
            KVM_DIR="$script_dir/kvm"
        elif [ -f "$script_dir/../kvm/ui/package.json" ]; then
            KVM_DIR="$(cd "$script_dir/../kvm" && pwd)"
        elif [ -f "./kvm/ui/package.json" ]; then
            KVM_DIR="$(pwd)/kvm"
        elif [ -f "./ui/package.json" ] && [ -f "./Makefile" ]; then
            KVM_DIR="$(pwd)"
        else
            # Buscar en directorios comunes
            for dir in ~/Desarrollo/kvm ~/Development/kvm ~/Projects/kvm ~/kvm ./kvm; do
                if [ -f "$dir/ui/package.json" ]; then
                    KVM_DIR="$dir"
                    break
                fi
            done
        fi
    fi
    
    # Intentar detectar RV1106_DIR
    if [ -z "$RV1106_DIR" ]; then
        if [ -f "$script_dir/rv1106-system/build.sh" ]; then
            RV1106_DIR="$script_dir/rv1106-system"
        elif [ -f "$script_dir/../rv1106-system/build.sh" ]; then
            RV1106_DIR="$(cd "$script_dir/../rv1106-system" && pwd)"
        elif [ -f "./rv1106-system/build.sh" ]; then
            RV1106_DIR="$(pwd)/rv1106-system"
        elif [ -f "./build.sh" ] && [ -d "./project/app/jetkvm" ]; then
            RV1106_DIR="$(pwd)"
        else
            # Buscar en directorios comunes
            for dir in ~/Desarrollo/rv1106-system ~/Development/rv1106-system ~/Projects/rv1106-system ~/rv1106-system ./rv1106-system; do
                if [ -f "$dir/build.sh" ]; then
                    RV1106_DIR="$dir"
                    break
                fi
            done
        fi
    fi
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --kvm-dir)
            KVM_DIR="$2"
            shift 2
            ;;
        --rv1106-dir)
            RV1106_DIR="$2"
            shift 2
            ;;
        --skip-ui)
            SKIP_UI=true
            shift
            ;;
        --skip-binary)
            SKIP_BINARY=true
            shift
            ;;
        --skip-flash)
            SKIP_FLASH=true
            shift
            ;;
        --device-ip)
            DEVICE_IP="$2"
            shift 2
            ;;
        --version)
            BUILD_VERSION="$2"
            shift 2
            ;;
        --help)
            head -n 30 "$0" | grep "^#" | sed 's/^# //'
            exit 0
            ;;
        *)
            echo "Opción desconocida: $1"
            echo "Usa --help para ver las opciones disponibles"
            exit 1
            ;;
    esac
done

# Detectar directorios si no se especificaron
detect_directories

# Validar que se encontraron los directorios
if [ -z "$KVM_DIR" ] || [ ! -d "$KVM_DIR" ]; then
    print_error "No se pudo detectar el directorio del proyecto kvm"
    echo "Especifícalo manualmente con: --kvm-dir /ruta/al/proyecto/kvm"
    exit 1
fi

if [ -z "$RV1106_DIR" ] || [ ! -d "$RV1106_DIR" ]; then
    print_error "No se pudo detectar el directorio del proyecto rv1106-system"
    echo "Especifícalo manualmente con: --rv1106-dir /ruta/al/proyecto/rv1106-system"
    exit 1
fi

UPGRADE_TOOL_DIR="$RV1106_DIR/tools/linux/Linux_Upgrade_Tool"

# Función para imprimir mensajes
print_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Mostrar configuración
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${GREEN}Configuración del Build${NC}                      ${BLUE}║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC}  KVM Dir:     ${YELLOW}$(basename "$KVM_DIR")${NC}"
echo -e "${BLUE}║${NC}  RV1106 Dir:  ${YELLOW}$(basename "$RV1106_DIR")${NC}"
echo -e "${BLUE}║${NC}  Device IP:   ${YELLOW}$DEVICE_IP${NC}"
echo -e "${BLUE}║${NC}  Skip UI:     ${YELLOW}$SKIP_UI${NC}"
echo -e "${BLUE}║${NC}  Skip Binary: ${YELLOW}$SKIP_BINARY${NC}"
echo -e "${BLUE}║${NC}  Skip Flash:  ${YELLOW}$SKIP_FLASH${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Calcular número total de pasos
TOTAL_STEPS=6
CURRENT_STEP=0
if [ "$SKIP_UI" = true ]; then
    TOTAL_STEPS=$((TOTAL_STEPS - 1))
fi
if [ "$SKIP_BINARY" = true ]; then
    TOTAL_STEPS=$((TOTAL_STEPS - 1))
fi
if [ "$SKIP_FLASH" = true ]; then
    TOTAL_STEPS=$((TOTAL_STEPS - 1))
fi

# Paso 1: Compilar la UI
if [ "$SKIP_UI" = false ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    print_step "Paso $CURRENT_STEP/$TOTAL_STEPS: Compilando UI web..."
    cd "$KVM_DIR"
    npm --prefix ui run build:device
    if [ $? -ne 0 ]; then
        print_error "Falló la compilación de la UI"
        exit 1
    fi
    print_step "✓ UI compilada exitosamente"
else
    print_warning "Saltando compilación de UI"
fi

# Paso 2: Compilar el binario Go con UI embebida
if [ "$SKIP_BINARY" = false ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    print_step "Paso $CURRENT_STEP/$TOTAL_STEPS: Compilando binario Go (jetkvm_app)..."
    cd "$KVM_DIR"
    
    if [ -n "$BUILD_VERSION" ]; then
        # Compilar con versión específica
        print_step "Compilando con versión: $BUILD_VERSION"
        sed -i.bak "s/^VERSION := .*/VERSION := $BUILD_VERSION/" Makefile
        make build_release
        mv Makefile.bak Makefile
    else
        # Compilar con versión dev (default)
        make build_dev
    fi
    
    if [ $? -ne 0 ]; then
        print_error "Falló la compilación del binario Go"
        exit 1
    fi
else
    print_warning "Saltando compilación del binario Go"
fi

# Verificar que el binario se creó
if [ ! -f "$KVM_DIR/bin/jetkvm_app" ]; then
    print_error "El binario jetkvm_app no se generó"
    exit 1
fi

BINARY_SIZE=$(du -h "$KVM_DIR/bin/jetkvm_app" | cut -f1)
print_step "✓ Binario compilado exitosamente (tamaño: $BINARY_SIZE)"

# Paso 3: Verificar espacio disponible
CURRENT_STEP=$((CURRENT_STEP + 1))
print_step "Paso $CURRENT_STEP/$TOTAL_STEPS: Verificando espacio en disco..."

# Detectar el sistema de archivos donde está RV1106_DIR
RV1106_MOUNT=$(df "$RV1106_DIR" | tail -1 | awk '{print $6}')
AVAILABLE_SPACE=$(df "$RV1106_DIR" | tail -1 | awk '{print $4}')
REQUIRED_SPACE=100000  # ~100MB en KB

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    print_warning "Espacio en disco bajo ($(($AVAILABLE_SPACE / 1024))MB disponibles). Limpiando archivos temporales..."
    
    # Limpiar builds antiguos
    if [ -d "$RV1106_DIR/output/out/rootfs_uclibc_rv1106" ]; then
        sudo rm -rf "$RV1106_DIR/output/out/rootfs_uclibc_rv1106" 2>/dev/null || true
    fi
    
    # Limpiar imágenes antiguas en IMAGE/
    if [ -d "$RV1106_DIR/IMAGE" ]; then
        find "$RV1106_DIR/IMAGE" -type d -name "RV1106_*" -mtime +1 -exec sudo rm -rf {} + 2>/dev/null || true
    fi
    
    print_step "✓ Espacio liberado"
else
    print_step "✓ Espacio suficiente ($(($AVAILABLE_SPACE / 1024))MB disponibles)"
fi

# Paso 4: Copiar binario a las ubicaciones correctas
CURRENT_STEP=$((CURRENT_STEP + 1))
print_step "Paso $CURRENT_STEP/$TOTAL_STEPS: Copiando binario a rv1106-system..."

# Crear directorios si no existen
mkdir -p "$RV1106_DIR/project/app/jetkvm/jetkvm/bin/"
mkdir -p "$RV1106_DIR/output/out/app_out/install_to_userdata/jetkvm/bin/"
mkdir -p "$RV1106_DIR/output/out/userdata/jetkvm/bin/"

# Copiar el binario a todas las ubicaciones necesarias
cp "$KVM_DIR/bin/jetkvm_app" "$RV1106_DIR/project/app/jetkvm/jetkvm/bin/jetkvm_app"
cp "$KVM_DIR/bin/jetkvm_app" "$RV1106_DIR/output/out/app_out/install_to_userdata/jetkvm/bin/jetkvm_app"
cp "$KVM_DIR/bin/jetkvm_app" "$RV1106_DIR/output/out/userdata/jetkvm/bin/jetkvm_app"

print_step "✓ Binario copiado a todas las ubicaciones"

# Paso 5: Construir firmware
CURRENT_STEP=$((CURRENT_STEP + 1))
print_step "Paso $CURRENT_STEP/$TOTAL_STEPS: Construyendo firmware..."
cd "$RV1106_DIR"
sudo ./build.sh firmware

if [ $? -ne 0 ]; then
    print_error "Falló la construcción del firmware"
    exit 1
fi

# Verificar que el firmware se creó
if [ ! -f "$RV1106_DIR/output/image/update.img" ]; then
    print_error "El firmware update.img no se generó"
    exit 1
fi

FIRMWARE_SIZE=$(du -h "$RV1106_DIR/output/image/update.img" | cut -f1)
print_step "✓ Firmware construido exitosamente (tamaño: $FIRMWARE_SIZE)"

# Paso 6: Flashear dispositivo
if [ "$SKIP_FLASH" = false ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    print_step "Paso $CURRENT_STEP/$TOTAL_STEPS: Flasheando dispositivo..."
    print_warning "Asegúrate de que el dispositivo esté en modo DFU (Maskrom)"
    echo -e "${YELLOW}Presiona Enter para continuar o Ctrl+C para cancelar...${NC}"
    read

    cd "$UPGRADE_TOOL_DIR"

    # Verificar que upgrade_tool existe
    if [ ! -f "./upgrade_tool" ]; then
        print_error "upgrade_tool no encontrado en $UPGRADE_TOOL_DIR"
        print_warning "Puedes flashear manualmente con:"
        echo "  cd $UPGRADE_TOOL_DIR"
        echo "  sudo ./upgrade_tool uf $RV1106_DIR/output/image/update.img"
        exit 1
    fi

    # Verificar que el dispositivo está conectado
    if ! sudo ./upgrade_tool ld | grep -q "Mode=Maskrom"; then
        print_error "Dispositivo no detectado en modo DFU/Maskrom"
        echo ""
        echo "Pasos para entrar en modo DFU:"
        echo "  1. Desconecta el dispositivo"
        echo "  2. Mantén presionado el botón de recuperación"
        echo "  3. Conecta el dispositivo mientras mantienes el botón"
        echo "  4. Suelta el botón después de 3 segundos"
        echo ""
        print_warning "Puedes flashear manualmente después con:"
        echo "  cd $UPGRADE_TOOL_DIR"
        echo "  sudo ./upgrade_tool uf $RV1106_DIR/output/image/update.img"
        exit 1
    fi

    print_step "Dispositivo detectado. Iniciando flash..."
    sudo ./upgrade_tool uf "$RV1106_DIR/output/image/update.img"

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                                ║${NC}"
        echo -e "${GREEN}║  ✓ FLASH COMPLETADO EXITOSAMENTE              ║${NC}"
        echo -e "${GREEN}║                                                ║${NC}"
        echo -e "${GREEN}║  El dispositivo se reiniciará automáticamente ║${NC}"
        echo -e "${GREEN}║  Espera 30-60 segundos antes de acceder       ║${NC}"
        echo -e "${GREEN}║                                                ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
        echo ""
        echo "Accede a: http://$DEVICE_IP"
    else
        print_error "Falló el flasheo del dispositivo"
        exit 1
    fi
else
    print_warning "Saltando flasheo del dispositivo"
    echo ""
    echo -e "${YELLOW}Firmware listo en:${NC}"
    echo "  $RV1106_DIR/output/image/update.img"
    echo ""
    echo -e "${YELLOW}Para flashear manualmente:${NC}"
    echo "  cd $UPGRADE_TOOL_DIR"
    echo "  sudo ./upgrade_tool uf $RV1106_DIR/output/image/update.img"
fi
