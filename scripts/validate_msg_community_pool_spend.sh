#!/bin/bash

# Script para validar si MsgCommunityPoolSpend está disponible
# en el módulo distribution del Cosmos SDK

set -e

echo "=========================================="
echo "Validación de MsgCommunityPoolSpend"
echo "=========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir resultados
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# 1. Verificar versión del Cosmos SDK
echo "1. Verificando versión del Cosmos SDK..."
SDK_VERSION=$(go list -m github.com/cosmos/cosmos-sdk 2>/dev/null | awk '{print $2}' || echo "no encontrado")
print_info "Versión del SDK: $SDK_VERSION"
echo ""

# 2. Buscar en el código si existe referencia a MsgCommunityPoolSpend
echo "2. Buscando referencias a MsgCommunityPoolSpend en el código..."
if grep -r "MsgCommunityPoolSpend\|CommunityPoolSpend" . --include="*.go" --include="*.proto" 2>/dev/null | grep -v ".git" | grep -v "vendor" | head -5; then
    print_result 0 "Se encontraron referencias a MsgCommunityPoolSpend"
else
    print_result 1 "NO se encontraron referencias a MsgCommunityPoolSpend"
fi
echo ""

# 3. Verificar qué mensajes están disponibles en el módulo distribution
echo "3. Verificando mensajes disponibles en el módulo distribution..."
print_info "Buscando tipos de mensajes del módulo distribution..."

# Buscar archivos que importen distributiontypes
DIST_FILES=$(grep -r "distributiontypes\." . --include="*.go" 2>/dev/null | grep -v ".git" | grep -v "vendor" | head -10 | cut -d: -f1 | sort -u)

if [ -n "$DIST_FILES" ]; then
    print_info "Archivos que usan distributiontypes:"
    echo "$DIST_FILES" | head -5
    echo ""
    
    # Buscar qué mensajes se usan
    print_info "Mensajes de distribution encontrados:"
    grep -h "distributiontypes\.Msg" $DIST_FILES 2>/dev/null | grep -o "Msg[A-Za-z]*" | sort -u || echo "  (no se encontraron mensajes específicos)"
else
    print_result 1 "No se encontraron archivos que usen distributiontypes"
fi
echo ""

# 4. Verificar en el módulo distribution del SDK (si está en go.mod)
echo "4. Verificando mensajes en el módulo distribution del SDK..."
SDK_PATH=$(go list -m -f '{{.Dir}}' github.com/cosmos/cosmos-sdk 2>/dev/null || echo "")

if [ -n "$SDK_PATH" ] && [ -d "$SDK_PATH" ]; then
    print_info "Ruta del SDK: $SDK_PATH"
    
    # Buscar archivos proto del módulo distribution
    DIST_PROTO=$(find "$SDK_PATH/x/distribution" -name "*.proto" 2>/dev/null | head -5)
    
    if [ -n "$DIST_PROTO" ]; then
        print_info "Archivos proto encontrados:"
        echo "$DIST_PROTO" | head -3
        echo ""
        
        # Buscar MsgCommunityPoolSpend en los protos
        if grep -r "MsgCommunityPoolSpend\|CommunityPoolSpend" $DIST_PROTO 2>/dev/null; then
            print_result 0 "MsgCommunityPoolSpend encontrado en los protos del SDK"
        else
            print_result 1 "MsgCommunityPoolSpend NO encontrado en los protos del SDK"
        fi
    else
        print_info "No se encontraron archivos proto en $SDK_PATH/x/distribution"
    fi
else
    print_info "El SDK no está disponible localmente (puede estar en cache de Go)"
    print_info "Intentando verificar a través de go list..."
    
    # Intentar verificar a través de go doc
    if go doc github.com/cosmos/cosmos-sdk/x/distribution/types 2>/dev/null | grep -i "CommunityPoolSpend"; then
        print_result 0 "MsgCommunityPoolSpend encontrado en la documentación del SDK"
    else
        print_result 1 "MsgCommunityPoolSpend NO encontrado en la documentación del SDK"
    fi
fi
echo ""

# 5. Verificar si el mensaje está registrado en el router
echo "5. Verificando registro de mensajes en el router..."
print_info "Buscando donde se registran los mensajes del módulo distribution..."

# Buscar RegisterMsgServer para distribution
if grep -r "distribution.*RegisterMsgServer\|RegisterMsgServer.*distribution" . --include="*.go" 2>/dev/null | grep -v ".git" | grep -v "vendor"; then
    print_info "Se encontró registro de mensajes del módulo distribution"
else
    print_info "No se encontró registro explícito (puede estar en el ModuleManager)"
fi
echo ""

# 6. Verificar a través de gRPC (si el nodo está corriendo)
echo "6. Verificando mensajes disponibles vía gRPC..."
if command -v infinited &> /dev/null; then
    print_info "Intentando consultar mensajes disponibles..."
    
    # Intentar consultar el servicio de mensajes
    if timeout 2 infinited query distribution params 2>/dev/null > /dev/null; then
        print_info "El nodo está disponible, puedes verificar manualmente con:"
        echo "  infinited query distribution community-pool"
        echo "  infinited tx distribution --help"
    else
        print_info "El nodo no está disponible o no responde"
    fi
else
    print_info "infinited no está disponible en PATH"
fi
echo ""

# 7. Verificar en la documentación del precompile
echo "7. Verificando en la documentación del precompile de distribution..."
if [ -f "precompiles/distribution/README.md" ]; then
    if grep -i "community.*pool.*spend\|spend.*community" precompiles/distribution/README.md 2>/dev/null; then
        print_result 0 "Se encontró referencia en la documentación"
    else
        print_result 1 "NO se encontró referencia en la documentación"
        print_info "Mensajes documentados en el precompile:"
        grep -E "function [a-zA-Z]+" precompiles/distribution/README.md 2>/dev/null | head -10 || echo "  (no se encontraron funciones documentadas)"
    fi
else
    print_info "No se encontró precompiles/distribution/README.md"
fi
echo ""

# 8. Resumen y recomendaciones
echo "=========================================="
echo "RESUMEN Y RECOMENDACIONES"
echo "=========================================="
echo ""

print_info "Para verificar definitivamente si MsgCommunityPoolSpend está disponible:"
echo ""
echo "1. Consultar la documentación del Cosmos SDK v$SDK_VERSION:"
echo "   https://docs.cosmos.network/sdk/v0.54/build/modules/distribution"
echo ""
echo "2. Verificar en el código del SDK:"
echo "   Buscar en: \$GOPATH/pkg/mod/github.com/cosmos/cosmos-sdk@$SDK_VERSION/x/distribution"
echo ""
echo "3. Probar crear una propuesta de governance:"
echo "   infinited tx gov submit-proposal --help"
echo ""
echo "4. Verificar mensajes disponibles del módulo distribution:"
echo "   infinited tx distribution --help"
echo ""
echo "5. Consultar el código fuente del SDK directamente:"
echo "   https://github.com/cosmos/cosmos-sdk/tree/v$SDK_VERSION/x/distribution"
echo ""

# 9. Verificar si hay algún test que use este mensaje
echo "9. Verificando tests que usen mensajes del community pool..."
if find . -name "*test*.go" -type f 2>/dev/null | xargs grep -l "CommunityPool\|community.*pool" 2>/dev/null | head -5; then
    print_info "Se encontraron tests relacionados con community pool"
else
    print_info "No se encontraron tests específicos"
fi
echo ""

echo "=========================================="
echo "Validación completada"
echo "=========================================="
