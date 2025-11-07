# Scripts Documentation

> **Copyright (c) 2025 Deep Thought Labs**  
> Internal tooling and automation scripts.

---

## Command Name Rebranding Scripts

> **Note**: These scripts are internal development tools and are not part of the
upstream repository. They have been developed for internal validation and
quality assurance processes.

### Descripción

Scripts para ayudar en el proceso seguro de cambio del nombre del comando de `evmd` a `infinited`.

## Scripts Disponibles

### 1. `audit_command_name.sh` - Auditoría Inicial

**Propósito**: Buscar todas las referencias al nombre del comando que deben cambiarse.

**Uso**:
```bash
chmod +x scripts/audit_command_name.sh
./scripts/audit_command_name.sh
```

**Qué hace**:
- Busca `Use: "evmd"` en comandos Cobra
- Busca ejemplos con `evmd` en comandos
- Busca `svrcmd.Execute` con el nombre del comando
- Busca mensajes de build en Makefile
- Busca `EXAMPLE_BINARY` en Makefile
- Busca directorio home que use el nombre del comando

**Output**: Crea `audit_report_YYYYMMDD_HHMMSS.txt` con todos los hallazgos.

---

### 2. `test_outputs_before.sh` - Capturar Estado Actual

**Propósito**: Guardar los outputs actuales ANTES de hacer cambios para comparar después.

**Uso**:
```bash
chmod +x scripts/test_outputs_before.sh
./scripts/test_outputs_before.sh
```

**Qué hace**:
- Captura `--help` del comando actual
- Captura `version`
- Captura `--help` de subcomandos (keys, query, tx, testnet)
- Guarda todo en `outputs_before_YYYYMMDD_HHMMSS/`

**Cuándo ejecutar**: ANTES de hacer cualquier cambio en el código.

---

### 3. `verify_command_name.sh` - Verificación Post-Cambio

**Propósito**: Verificar que los cambios funcionan correctamente DESPUÉS de modificar el código.

**Uso**:
```bash
chmod +x scripts/verify_command_name.sh
./scripts/verify_command_name.sh
```

**Qué hace**:
- Verifica que `infinited --help` muestra `infinited` como comando
- Verifica que NO aparece `evmd` como comando ejecutable
- Verifica que `infinited version` funciona
- Verifica que los ejemplos usan `infinited`
- Da un resumen con errores y advertencias

**Cuándo ejecutar**: DESPUÉS de cada cambio, o al final de todos los cambios.

---

### 4. `compare_outputs.sh` - Comparación Antes/Después

**Propósito**: Comparar los outputs antes y después de los cambios.

**Uso**:
```bash
chmod +x scripts/compare_outputs.sh
./scripts/compare_outputs.sh
```

**Requisitos**: Debes haber ejecutado `test_outputs_before.sh` primero.

**Qué hace**:
- Compara el help antes y después
- Compara la versión antes y después
- Busca si quedó algún `evmd` en los nuevos outputs
- Verifica que aparece `infinited` en los nuevos outputs

**Cuándo ejecutar**: DESPUÉS de hacer los cambios y compilar.

---

## Flujo de Trabajo Recomendado

### Paso 1: Preparación
```bash
# 1. Auditoría inicial
./scripts/audit_command_name.sh

# 2. Revisar el reporte
cat audit_report_*.txt

# 3. Capturar estado actual
./scripts/test_outputs_before.sh
```

### Paso 2: Hacer Cambios
Modificar los archivos identificados en la auditoría (ver `guides/PLAN_SEGURO_PERSONALIZACION.md`)

### Paso 3: Compilar y Verificar
```bash
# 1. Compilar
make clean
make install

# 2. Verificar cambios
./scripts/verify_command_name.sh

# 3. Comparar con estado anterior
./scripts/compare_outputs.sh
```

### Paso 4: Si algo falla
```bash
# Revertir cambios
git checkout <archivo>

# O volver al estado inicial
git checkout HEAD --
```

---

## Notas Importantes

1. **Ejecuta los scripts desde la raíz del proyecto**: Asegúrate de estar en el directorio raíz donde están `infinited/`, `Makefile`, etc.

2. **Permisos de ejecución**: Si los scripts no se ejecutan, dales permisos:
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Rutas relativas**: Los scripts asumen que estás en la raíz del proyecto. Si ejecutas desde otro lugar, ajusta las rutas.

4. **Git**: Es recomendable hacer commit o crear una rama antes de empezar:
   ```bash
   git checkout -b rebrand/command-name
   git add .
   git commit -m "checkpoint: before changing command name"
   ```

---

## Troubleshooting

### Error: "comando no encontrado"
Si el script dice que `evmd` o `infinited` no está en PATH:
- Verifica que compilaste: `make install`
- O especifica la ruta completa en el script

### Error: "No se encontró directorio de outputs"
Para `compare_outputs.sh`:
- Asegúrate de ejecutar `test_outputs_before.sh` primero

### Los scripts no encuentran archivos
- Verifica que estás en el directorio raíz del proyecto
- Verifica que las rutas `infinited/cmd/`, `Makefile`, etc. existen

