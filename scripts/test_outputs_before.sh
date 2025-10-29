#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the internal tooling for command name rebranding
# validation and audit processes.
#
# Purpose: Capture and store command outputs before code modifications
#          to enable comparison and validation after changes.
#

set -e

OLD_COMMAND="evmd"  # Nombre actual del comando
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="outputs_before_$TIMESTAMP"

mkdir -p "$OUTPUT_DIR"

echo "========================================="
echo "📸 CAPTURANDO OUTPUTS ACTUALES"
echo "========================================="
echo "Comando actual: $OLD_COMMAND"
echo "Directorio: $OUTPUT_DIR"
echo ""

# Verificar que el binario existe
if ! command -v "$OLD_COMMAND" &> /dev/null; then
    echo "⚠️  AVISO: El comando '$OLD_COMMAND' no está en PATH"
    echo "Buscando en ubicaciones comunes..."
    
    # Buscar en GOPATH/bin
    if [ -f "$HOME/go/bin/$OLD_COMMAND" ]; then
        OLD_COMMAND="$HOME/go/bin/$OLD_COMMAND"
        echo "✅ Encontrado en: $OLD_COMMAND"
    elif [ -f "./build/$OLD_COMMAND" ]; then
        OLD_COMMAND="./build/$OLD_COMMAND"
        echo "✅ Encontrado en: $OLD_COMMAND"
    else
        echo "❌ No se encontró el binario. Por favor, compila primero:"
        echo "   make install"
        exit 1
    fi
fi

echo "Capturando outputs..."

# Help principal
echo "1. Help principal..."
$OLD_COMMAND --help > "$OUTPUT_DIR/help_main.txt" 2>&1

# Version
echo "2. Version..."
$OLD_COMMAND version > "$OUTPUT_DIR/version.txt" 2>&1

# Comandos principales
echo "3. Comandos principales..."
$OLD_COMMAND keys --help > "$OUTPUT_DIR/keys_help.txt" 2>&1 || echo "Comando keys no disponible" > "$OUTPUT_DIR/keys_help.txt"
$OLD_COMMAND query --help > "$OUTPUT_DIR/query_help.txt" 2>&1 || echo "Comando query no disponible" > "$OUTPUT_DIR/query_help.txt"
$OLD_COMMAND tx --help > "$OUTPUT_DIR/tx_help.txt" 2>&1 || echo "Comando tx no disponible" > "$OUTPUT_DIR/tx_help.txt"

# Comando testnet si existe
echo "4. Comando testnet..."
$OLD_COMMAND testnet --help > "$OUTPUT_DIR/testnet_help.txt" 2>&1 || echo "Comando testnet no disponible" > "$OUTPUT_DIR/testnet_help.txt"

# Crear resumen
cat > "$OUTPUT_DIR/README.txt" << EOF
Outputs capturados ANTES de cambios
====================================
Fecha: $(date)
Comando usado: $OLD_COMMAND

Archivos:
- help_main.txt    : Salida de '$OLD_COMMAND --help'
- version.txt      : Salida de '$OLD_COMMAND version'
- keys_help.txt    : Salida de '$OLD_COMMAND keys --help'
- query_help.txt   : Salida de '$OLD_COMMAND query --help'
- tx_help.txt      : Salida de '$OLD_COMMAND tx --help'
- testnet_help.txt : Salida de '$OLD_COMMAND testnet --help'

Usa estos archivos para comparar después de los cambios.
EOF

echo ""
echo "✅ Outputs capturados en: $OUTPUT_DIR"
echo ""
echo "Archivos creados:"
ls -lh "$OUTPUT_DIR"
echo ""
echo "Puedes revisar el contenido:"
echo "  cat $OUTPUT_DIR/help_main.txt"
echo "  cat $OUTPUT_DIR/version.txt"

