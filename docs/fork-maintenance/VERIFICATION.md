# Verificación tras merge o cambios de identidad

## Script automatizado (recomendado)

```bash
./scripts/validate_customizations.sh
```

Comprueba valores críticos de identidad y ausencia de paths incorrectos. No depende del nombre de la rama actual.

Tras un merge, si el script avisa por `go.mod` / `go.sum` respecto a upstream, **revisar** que sea intencional (fork + `infinited`) y no un conflicto mal cerrado.

## Marcadores de conflicto (obligatorio tras resolver merge)

Antes de commit/push de la integración:

```bash
grep -R -n '^<<<<<<<' . --exclude-dir=.git && echo "ERROR: Quedan conflictos" && exit 1 || echo "OK: sin ^<<<<<<<"
```

## Búsquedas manuales (identidad)

```bash
# Token / denom
grep -r "Improbability\|drop\|42" --include="*.go" --include="*.sh" --include="*.json"

# Chain IDs
grep -r "421018\|infinite_421018" --include="*.go" --include="*.sh"

# Bech32
grep -r "infinitevaloper\|infinitevalcons" --include="*.go"

# Binario
grep -r "infinited" --include="Makefile" --include="*.sh"
```

## Compliance frente a upstream

```bash
# No debe aparecer path de fork incorrecto en código/módulos
grep -r "deep-thought-labs/infinite" --include="*.go" --include="*.mod" || echo "OK: sin paths incorrectos"

# go.mod / go.sum vs upstream (salvo línea module si aplica)
git diff upstream/main go.mod | grep -v "^module" | grep -v "^+++" | grep -v "^---" || echo "OK: go.mod alineado salvo module"
git diff upstream/main go.sum | head -5 || echo "OK: go.sum"

# Imports github.com/cosmos/evm/evmd: en fork Infinite, el binario local vive en infinited; cuerpo vacío = bien
grep -R 'github.com/cosmos/evm/evmd' --include='*.go' . --exclude-dir=.git && echo "REVISAR: cada coincidencia (suele migrarse a .../infinited)" || echo "OK: sin imports evmd en .go"
```

Ajustar `upstream/main` si la integración usa otra rama.

## Build local

- **`make build`** o **`make install`** tras **`go mod tidy`**.
- Si el path del clone contiene **espacios**, el `Makefile` debe usar rutas entrecomilladas en las recetas relevantes; si falla tras merge, ver [PLAYBOOK.md — Apéndice A.3](PLAYBOOK.md#apéndice-a-cierre-del-merge-y-trampas-frecuentes).

## Tests tras merge

- Ejecutar al menos **`make test-unit`** desde la raíz del módulo `cosmos/evm`.
- Para paridad con CI de cobertura: el workflow **Tests** ejecuta **cuatro** bloques (`make test-unit-cover-evm-core`, `…-evm-integration`, `…-infinited-core`, `…-infinited-integration`); un fallo aislado en **`infinited/tests/integration`** ya no enmascara los otros tres. Detalle: [TESTING.md — Granular coverage blocks](../guides/development/TESTING.md#granular-coverage-blocks-test-unit-cover).
- Parte de la integración vive en el submódulo **`infinited/`** (p. ej. `TestEvmUnitAnteTestSuite` en `infinited/tests/integration/ante`). Si solo pasan los tests de la raíz pero falló algo en ante/EIP-712/mempool, validar explícitamente:  
  `cd infinited && go test ./tests/integration/...`
- Si aparecen fallos por denom/bech32, por límites de gas de bloque en tests, o por **compilación** en `tests/integration/**`, revisar [PLAYBOOK.md — Apéndice A.7](PLAYBOOK.md#a7-tests-y-apis-tras-merge-upstream).

## Más contexto

- Guía de desarrollo: [docs/guides/development/DEVELOPMENT.md](../guides/development/DEVELOPMENT.md)
- Scripts: [docs/guides/development/SCRIPTS.md](../guides/development/SCRIPTS.md)
- Flujos de validación: [docs/guides/testing/VALIDATION.md](../guides/testing/VALIDATION.md) (scripts: [docs/guides/development/SCRIPTS.md](../guides/development/SCRIPTS.md))
