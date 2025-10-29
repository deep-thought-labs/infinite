#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the internal tooling for command name rebranding
# validation and audit processes.
#
# Purpose: Compare command outputs before and after code modifications
#          to verify changes and ensure correct command name implementation.
#
# Prerequisites: Execute test_outputs_before.sh prior to running this script.
#

set -e

NEW_COMMAND="infinited"
OLD_COMMAND="evmd"

echo "========================================="
echo "📊 COMPARACIÓN DE OUTPUTS"
echo "========================================="
echo ""

# Buscar directorio de outputs "antes"
BEFORE_DIR=$(ls -td outputs_before_* 2>/dev/null | head -1)

if [ -z "$BEFORE_DIR" ]; then
    echo "❌ No se encontró directorio de outputs 'antes'"
    echo ""
    echo "Por favor ejecuta primero:"
    echo "  ./scripts/test_outputs_before.sh"
    exit 1
fi

echo "📂 Usando outputs anteriores de: $BEFORE_DIR"
echo ""

# Crear outputs nuevos
echo "📸 Capturando outputs actuales..."
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

$NEW_COMMAND --help > "$TEMP_DIR/help_main.txt" 2>&1
$NEW_COMMAND version > "$TEMP_DIR/version.txt" 2>&1
$NEW_COMMAND keys --help > "$TEMP_DIR/keys_help.txt" 2>&1 || echo "No disponible" > "$TEMP_DIR/keys_help.txt"
$NEW_COMMAND query --help > "$TEMP_DIR/query_help.txt" 2>&1 || echo "No disponible" > "$TEMP_DIR/query_help.txt"
$NEW_COMMAND tx --help > "$TEMP_DIR/tx_help.txt" 2>&1 || echo "No disponible" > "$TEMP_DIR/tx_help.txt"

echo ""
echo "========================================="
echo "📝 COMPARACIÓN: Help Principal"
echo "========================================="

echo ""
echo "Cambios en 'Usage:' (líneas con diferencias):"
diff "$BEFORE_DIR/help_main.txt" "$TEMP_DIR/help_main.txt" | grep -E "^[<>].*Usage|^[<>].*$OLD_COMMAND|^[<>].*$NEW_COMMAND" | head -10 || echo "No hay diferencias en Usage"

echo ""
echo "Verificando nombres de comandos..."
echo ""
echo "ANTES (debe contener '$OLD_COMMAND'):"
grep -i "Usage:\|^$OLD_COMMAND" "$BEFORE_DIR/help_main.txt" | head -3 || echo "  No encontrado"

echo ""
echo "DESPUÉS (debe contener '$NEW_COMMAND'):"
grep -i "Usage:\|^$NEW_COMMAND" "$TEMP_DIR/help_main.txt" | head -3 || echo "  No encontrado"

echo ""
echo "========================================="
echo "📝 COMPARACIÓN: Version"
echo "========================================="

echo ""
echo "ANTES:"
cat "$BEFORE_DIR/version.txt" | head -5

echo ""
echo "DESPUÉS:"
cat "$TEMP_DIR/version.txt" | head -5

echo ""
echo "Verificando AppName..."
BEFORE_APPNAME=$(grep -i "AppName:" "$BEFORE_DIR/version.txt" || echo "No encontrado")
AFTER_APPNAME=$(grep -i "AppName:" "$TEMP_DIR/version.txt" || echo "No encontrado")

echo "  ANTES:  $BEFORE_APPNAME"
echo "  DESPUÉS: $AFTER_APPNAME"

echo ""
echo "========================================="
echo "🔍 BÚSQUEDA DE NOMBRES VIEJOS"
echo "========================================="

echo ""
echo "Buscando '$OLD_COMMAND' en outputs nuevos..."
FOUND_OLD=0

for file in "$TEMP_DIR"/*.txt; do
    if grep -qi "$OLD_COMMAND" "$file"; then
        echo "  ⚠️  Encontrado '$OLD_COMMAND' en: $(basename $file)"
        grep -i "$OLD_COMMAND" "$file" | head -2 | sed 's/^/    /'
        FOUND_OLD=1
    fi
done

if [ $FOUND_OLD -eq 0 ]; then
    echo "  ✅ No se encontró '$OLD_COMMAND' en outputs nuevos"
fi

echo ""
echo "Verificando que '$NEW_COMMAND' aparece..."
FOUND_NEW=0

for file in "$TEMP_DIR"/*.txt; do
    if grep -qi "$NEW_COMMAND" "$file"; then
        echo "  ✅ Encontrado '$NEW_COMMAND' en: $(basename $file)"
        FOUND_NEW=1
    fi
done

if [ $FOUND_NEW -eq 0 ]; then
    echo "  ⚠️  No se encontró '$NEW_COMMAND' en outputs"
fi

echo ""
echo "========================================="
echo "📋 RESUMEN"
echo "========================================="

if [ $FOUND_OLD -eq 0 ] && [ $FOUND_NEW -gt 0 ]; then
    echo "✅ COMPARACIÓN EXITOSA"
    echo ""
    echo "Los outputs muestran '$NEW_COMMAND' y ya no contienen '$OLD_COMMAND'"
    echo "como nombre de comando ejecutable."
else
    echo "⚠️  REVISIÓN NECESARIA"
    echo ""
    if [ $FOUND_OLD -gt 0 ]; then
        echo "  - Aún aparecen referencias a '$OLD_COMMAND'"
    fi
    if [ $FOUND_NEW -eq 0 ]; then
        echo "  - No se encontró '$NEW_COMMAND' en outputs"
    fi
fi

