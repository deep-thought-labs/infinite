# 📋 Plan de Migración para Infinite Drive Blockchain

## Introducción
Este documento describe el plan paso a paso para personalizar el repositorio Cosmos EVM original en tu blockchain "Infinite Drive". El objetivo es aplicar todos los cambios definidos en BLOCKCHAIN_CONFIG.md de forma segura y consistente, evitando errores. 

La migración se hará usando herramientas como edit_file y search_replace para modificar archivos específicos. Al final, se verificará con compilación y tests.

**Fecha**: October 28, 2025  
**Versión original**: cosmos/evm  
**Versión target**: deep-thought-labs/infinite

---

## Valores Definidos (de BLOCKCHAIN_CONFIG.md)
- **Nombre oficial**: Infinite Drive
- **Nombre corto/técnico**: infinite
- **Organización GitHub**: deep-thought-labs
- **Proyecto**: infinite
- **Módulo Go**: github.com/deep-thought-labs/infinite
- **Repo URL**: https://github.com/deep-thought-labs/infinite.git
- **Binario**: infinited
- **Carpeta de datos**: .infinited
- **Token Symbol**: TEA
- **Token Name**: Improbability
- **Display Denom**: TEA
- **Base Denom**: drop
- **Relación**: 1 TEA = 10^18 drop
- **Decimales**: 18
- **Token Description**: The native token of Whole Sort of General Mish Mash
- **Supply inicial**: 42000000000000000000 (42 TEA)
- **EVM Chain ID**: 421018
- **Cosmos Chain ID**: infinite_421018-1
- **Prefijo general**: infinite
- **Bech32 Prefix**: infinite

---

## Plan de Cambios Paso a Paso
Aplicaré estos cambios en orden para minimizar errores. Cada paso incluye archivos afectados y acciones.

### 1. Renombrado Global del Módulo y Importaciones
- **Archivos**: go.mod (principal), todos los *.go en el repo.
- **Acciones**:
  - Cambiar module en go.mod a `github.com/deep-thought-labs/infinite`.
  - Reemplazar todas las importaciones de `github.com/cosmos/evm` por `github.com/deep-thought-labs/infinite` (usando search_replace en batch).
- **Herramienta**: search_replace para batch.

### 2. Nombre del Binario y Comandos
- **Archivos**: Makefile, infinited/cmd/infinited/main.go, infinited/config/config.go.
- **Acciones**:
  - Reemplazar `evmd` por `infinited` en nombres de binario, comandos y referencias.
  - Ajustar EXAMPLE_BINARY en Makefile a `infinited`.
- **Herramienta**: edit_file para ediciones precisas.

### 3. Carpeta de Datos y Home Directory
- **Archivo**: infinited/config/config.go.
- **Acciones**: Cambiar default home de `.evmd` a `.infinited`.
- **Herramienta**: edit_file.

### 4. Prefijo Bech32 y Direcciones
- **Archivo**: infinited/config/bech32.go.
- **Acciones**: Reemplazar `cosmos` por `infinite` en todos los Bech32 prefixes (cuentas, validadores, etc.).
- **Herramienta**: search_replace.

### 5. Token y Denominaciones
- **Archivos**: testutil/constants/constants.go, infinited/genesis.go, local_node.sh.
- **Acciones**:
  - Denoms: Cambiar `aatom` a `drop`, `atom` a `TEA`.
  - Símbolo y nombre: Actualizar a TEA / Improbability.
  - Description: Ajustar a "Improbability: A token powered by the most improbable drop in the galaxy.".
  - Supply inicial: Configurar genesis a 42000000000000000000 drop (42 TEA).
- **Herramienta**: edit_file y search_replace.

### 6. Chain IDs
- **Archivos**: testutil/constants/constants.go, local_node.sh.
- **Acciones**: Reemplazar Chain ID de 9001 por 421018, y Cosmos ID de `cosmos_9001-1` por `infinite_421018-1`.
- **Herramienta**: search_replace.

### 7. Nombre Oficial y Descripciones
- **Archivos**: README.md, infinited/README.md, local_node.sh (metadatos).
- **Acciones**: Actualizar referencias a "Infinite Drive" como nombre oficial, y ajustar descripciones temáticas.
- **Herramienta**: edit_file.

### 8. Repo URL y Build Info
- **Archivo**: Makefile.
- **Acciones**: Cambiar HTTPS_GIT a `https://github.com/deep-thought-labs/infinite.git`, y version.Name a `infinite`.
- **Herramienta**: edit_file.

### 9. Ajustes en Tests y Scripts
- **Archivos**: local_node.sh, testutil/*, tests/*.
- **Acciones**: Actualizar constantes, nombres en tests, y scripts para que usen los nuevos valores (e.g., chain ID, denoms, binario).
- **Herramienta**: search_replace y edit_file.

### 10. Renombrar Carpetas
- **Acciones**: Cambiar carpeta `evmd/` a `infinited/`.
- **Herramienta**: Manual o tool para renombrar.

---

## Verificación Final
- Compilar: `make install`.
- Probar: `./local_node.sh` para iniciar el nodo.
- Tests: `make test-unit` para verificar que todo funciona.
- Validar: Comprobar chain ID, token, direcciones con comandos como `infinited query vm params`.

Si hay errores, ajustarlos manualmente (e.g., linter errors con read_lints).

## Notas
- **Precauciones**: Hacer backup del repo antes de aplicar.
- **Tiempo estimado**: 10-20 minutos para todos los cambios.
- **Personalizaciones adicionales**: Si necesitas modules personalizados o EIPs, agregar después.
- **Referencia**: Basado en BLOCKCHAIN_CONFIG.md y buenas prácticas de Cosmos SDK.

¡Listo para ejecutar el plan! 🚀
