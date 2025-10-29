#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the internal tooling for command name rebranding
# validation and audit processes.
#
# Purpose: Verification script to validate command name changes post-modification.
#          Ensures the command uses the new name (infinited) and removes
#          references to the old command name (evmd).
#

set -e

NEW_COMMAND="infinited"
OLD_COMMAND="evmd"

echo "========================================="
echo "✅ VERIFICACIÓN DEL NOMBRE DEL COMANDO"
echo "========================================="
echo "Verificando que '$NEW_COMMAND' funciona correctamente"
echo "y que '$OLD_COMMAND' ya no aparece como comando"
echo ""

ERRORS=0
WARNINGS=0

# Verificar que el binario existe
if ! command -v "$NEW_COMMAND" &> /dev/null; then
    echo "❌ ERROR: El comando '$NEW_COMMAND' no está en PATH"
    echo "Por favor, compila primero: make clean && make install"
    exit 1
fi

echo "Binario encontrado: $(which $NEW_COMMAND)"
echo ""

# Test 1: Help principal - debe mostrar "infinited"
echo "🧪 Test 1: Help principal - nombre del comando"
if $NEW_COMMAND --help 2>&1 | grep -qi "Usage:.*$NEW_COMMAND\|^$NEW_COMMAND"; then
    echo "   ✅ Help muestra '$NEW_COMMAND' como comando"
else
    echo "   ❌ Help NO muestra '$NEW_COMMAND' como comando"
    ERRORS=$((ERRORS + 1))
fi

# Test 2: Help NO debe mostrar el comando viejo "evmd" como comando ejecutable
echo ""
echo "🧪 Test 2: Help NO contiene comando viejo"
if $NEW_COMMAND --help 2>&1 | grep -qi "Usage:.*$OLD_COMMAND\|^$OLD_COMMAND "; then
    echo "   ❌ Help aún contiene el comando viejo '$OLD_COMMAND'"
    echo "   Líneas encontradas:"
    $NEW_COMMAND --help 2>&1 | grep -i "$OLD_COMMAND" | head -3 | sed 's/^/      /'
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ Help no contiene '$OLD_COMMAND' como comando"
fi

# Test 3: Version command - verificar AppName
echo ""
echo "🧪 Test 3: Version - nombre del binario"
VERSION_OUT=$($NEW_COMMAND version 2>&1)
echo "$VERSION_OUT" | head -5

if echo "$VERSION_OUT" | grep -qi "AppName:.*$NEW_COMMAND"; then
    echo "   ✅ Version muestra AppName: $NEW_COMMAND"
elif echo "$VERSION_OUT" | grep -qi "AppName:"; then
    APPNAME_SHOWN=$(echo "$VERSION_OUT" | grep -i "AppName:" | head -1)
    echo "   ⚠️  Version muestra: $APPNAME_SHOWN (verificar manualmente)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ⚠️  Version no muestra AppName explícitamente"
    WARNINGS=$((WARNINGS + 1))
fi

# Test 4: Ejemplos en comandos principales
echo ""
echo "🧪 Test 4: Ejemplos en comandos principales"
FOUND_OLD=0

for cmd in "testnet --help"; do
    CMD_OUTPUT=$($NEW_COMMAND $cmd 2>&1 || echo "")
    if echo "$CMD_OUTPUT" | grep -qi "$NEW_COMMAND "; then
        echo "   ✅ $cmd muestra '$NEW_COMMAND' en ejemplos"
    elif echo "$CMD_OUTPUT" | grep -qi "$OLD_COMMAND "; then
        echo "   ❌ $cmd aún muestra '$OLD_COMMAND' en ejemplos"
        ERRORS=$((ERRORS + 1))
        FOUND_OLD=1
    fi
done

if [ $FOUND_OLD -eq 0 ]; then
    echo "   ✅ No se encontraron ejemplos con '$OLD_COMMAND'"
fi

# Test 5: Funcionalidad básica
echo ""
echo "🧪 Test 5: Funcionalidad básica"
if $NEW_COMMAND version >/dev/null 2>&1; then
    echo "   ✅ Comando '$NEW_COMMAND' funciona correctamente"
else
    echo "   ❌ Comando '$NEW_COMMAND' NO funciona"
    ERRORS=$((ERRORS + 1))
fi

# Test 6: Verificar que el comando viejo ya no funciona (o funciona diferente)
echo ""
echo "🧪 Test 6: Comando viejo (si existe)"
if command -v "$OLD_COMMAND" &> /dev/null; then
    echo "   ⚠️  El comando '$OLD_COMMAND' aún existe en el sistema"
    echo "   (Puede ser el binario viejo. Considera eliminarlo después de validar)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "   ✅ El comando '$OLD_COMMAND' ya no está disponible (esperado)"
fi

# Resumen final
echo ""
echo "========================================="
echo "📊 RESUMEN"
echo "========================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ TODOS LOS TESTS PASARON"
    echo ""
    echo "El comando '$NEW_COMMAND' está configurado correctamente."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "✅ TESTS FUNCIONALES PASARON (con $WARNINGS advertencia(s))"
    echo ""
    echo "El comando funciona, pero hay algunos puntos a revisar manualmente."
    exit 0
else
    echo "❌ $ERRORS ERROR(ES) ENCONTRADO(S)"
    if [ $WARNINGS -gt 0 ]; then
        echo "   + $WARNINGS advertencia(s)"
    fi
    echo ""
    echo "Por favor, revisa los errores arriba y corrige antes de continuar."
    exit 1
fi

