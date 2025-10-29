#!/bin/bash
#
# Copyright (c) 2025 Deep Thought Labs
# All rights reserved.
#
# This file is part of the internal tooling for command name rebranding
# validation and audit processes.
#
# Purpose: Audit script to identify command name references that require
#          modification (evmd → infinited) in executable command definitions.
#

set -e

OLD_COMMAND="evmd"
NEW_COMMAND="infinited"

echo "========================================="
echo "🔍 AUDITORÍA DE NOMBRE DE COMANDO"
echo "========================================="
echo "Buscando referencias a '$OLD_COMMAND' que aparecen como"
echo "nombre del comando ejecutable (no código interno)"
echo ""

REPORT_FILE="audit_report_$(date +%Y%m%d_%H%M%S).txt"
touch "$REPORT_FILE"

# Función para agregar al reporte
add_to_report() {
    echo "$1" | tee -a "$REPORT_FILE"
}

add_to_report "=== REPORTE DE AUDITORÍA ==="
add_to_report "Fecha: $(date)"
add_to_report "Comando actual: $OLD_COMMAND"
add_to_report "Comando deseado: $NEW_COMMAND"
add_to_report ""

# 1. Nombre del comando en Cobra (Use:)
add_to_report "1️⃣  NOMBRE DEL COMANDO (Use: en Cobra)"
add_to_report "----------------------------------------"
RESULT=$(grep -rn 'Use:\s*"' infinited/cmd/ 2>/dev/null | grep "\"$OLD_COMMAND\"" || echo "No encontrado")
if [ -n "$RESULT" ] && [ "$RESULT" != "No encontrado" ]; then
    echo "$RESULT" | head -10 | tee -a "$REPORT_FILE"
    add_to_report ""
    add_to_report "✅ ENCONTRADO: Debe cambiarse Use: \"$OLD_COMMAND\" → Use: \"$NEW_COMMAND\""
else
    add_to_report "⚠️  No se encontró Use: con \"$OLD_COMMAND\""
fi
add_to_report ""

# 2. Ejemplos en comandos
add_to_report "2️⃣  EJEMPLOS DE COMANDOS (Example/Long)"
add_to_report "----------------------------------------"
RESULT=$(grep -rn 'Example:\|Long:' infinited/cmd/ 2>/dev/null | grep -i "$OLD_COMMAND" || echo "No encontrado")
if [ -n "$RESULT" ] && [ "$RESULT" != "No encontrado" ]; then
    echo "$RESULT" | head -15 | tee -a "$REPORT_FILE"
    add_to_report ""
    add_to_report "✅ ENCONTRADO: Deben cambiarse ejemplos que muestren '$OLD_COMMAND'"
else
    add_to_report "⚠️  No se encontraron ejemplos con \"$OLD_COMMAND\""
fi
add_to_report ""

# 3. svrcmd.Execute
add_to_report "3️⃣  SVRCmd Execute (nombre del binario)"
add_to_report "----------------------------------------"
if grep -rn "svrcmd\.Execute" infinited/cmd/infinited/main.go 2>/dev/null | grep "$OLD_COMMAND"; then
    grep -rn "svrcmd\.Execute" infinited/cmd/infinited/main.go | grep "$OLD_COMMAND" | tee -a "$REPORT_FILE"
    add_to_report ""
    add_to_report "✅ ENCONTRADO: Debe cambiarse svrcmd.Execute(..., \"$OLD_COMMAND\", ...)"
else
    add_to_report "⚠️  No se encontró svrcmd.Execute con \"$OLD_COMMAND\" (puede estar ya cambiado)"
fi
add_to_report ""

# 4. Mensajes de build en Makefile
add_to_report "4️⃣  MENSAJES DE BUILD (Makefile)"
add_to_report "----------------------------------------"
if grep -rn "@echo\|echo " Makefile 2>/dev/null | grep "$OLD_COMMAND"; then
    grep -rn "@echo\|echo " Makefile | grep "$OLD_COMMAND" | tee -a "$REPORT_FILE"
    add_to_report ""
    add_to_report "✅ ENCONTRADO: Mensajes de build deben actualizarse"
else
    add_to_report "⚠️  No se encontraron mensajes de build con \"$OLD_COMMAND\""
fi
add_to_report ""

# 5. EXAMPLE_BINARY en Makefile
add_to_report "5️⃣  EXAMPLE_BINARY en Makefile"
add_to_report "----------------------------------------"
if grep -rn "EXAMPLE_BINARY.*:=" Makefile 2>/dev/null | grep "$OLD_COMMAND"; then
    grep -rn "EXAMPLE_BINARY.*:=" Makefile | grep "$OLD_COMMAND" | tee -a "$REPORT_FILE"
    add_to_report ""
    add_to_report "✅ ENCONTRADO: EXAMPLE_BINARY debe cambiarse a $NEW_COMMAND"
else
    EXAMPLE_CURRENT=$(grep "EXAMPLE_BINARY.*:=" Makefile 2>/dev/null | head -1 || echo "No encontrado")
    add_to_report "Valor actual: $EXAMPLE_CURRENT"
fi
add_to_report ""

# 6. Directorio home (si usa nombre del comando)
add_to_report "6️⃣  DIRECTORIO HOME"
add_to_report "----------------------------------------"
RESULT=$(grep -rn "GetNodeHomeDirectory" infinited/config/ 2>/dev/null | grep -E "\.$OLD_COMMAND" || echo "No encontrado")
if [ -n "$RESULT" ] && [ "$RESULT" != "No encontrado" ]; then
    echo "$RESULT" | tee -a "$REPORT_FILE"
    add_to_report ""
    add_to_report "✅ ENCONTRADO: Directorio home usa .$OLD_COMMAND (cambiar a .$NEW_COMMAND)"
else
    DIR_CURRENT=$(grep "GetNodeHomeDirectory" infinited/config/config.go 2>/dev/null | head -1 || echo "No encontrado")
    add_to_report "Directorio actual: $DIR_CURRENT"
fi
add_to_report ""

# 7. Verificar flags de versión
add_to_report "7️⃣  FLAGS DE VERSIÓN (ldflags)"
add_to_report "----------------------------------------"
if grep -rn "version\.AppName\|version\.Name" Makefile 2>/dev/null; then
    grep -rn "version\.AppName\|version\.Name" Makefile | tee -a "$REPORT_FILE"
    add_to_report ""
    add_to_report "ℹ️  Verificar si estos flags deben usar $NEW_COMMAND"
else
    add_to_report "⚠️  No se encontraron flags de versión"
fi
add_to_report ""

# Resumen final
add_to_report "========================================="
add_to_report "📋 RESUMEN"
add_to_report "========================================="
add_to_report ""
add_to_report "Reporte guardado en: $REPORT_FILE"
add_to_report ""
add_to_report "PRÓXIMOS PASOS:"
add_to_report "1. Revisar el reporte: cat $REPORT_FILE"
add_to_report "2. Verificar cada hallazgo en su contexto"
add_to_report "3. Aplicar cambios de forma incremental"
add_to_report "4. Validar después de cada cambio"
add_to_report ""

echo ""
echo "✅ Auditoría completada. Reporte: $REPORT_FILE"

