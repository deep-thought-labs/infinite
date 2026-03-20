# Verificación tras merge o cambios de identidad

## Script automatizado (recomendado)

```bash
./scripts/validate_customizations.sh
```

Comprueba valores críticos de identidad y ausencia de paths incorrectos. No depende del nombre de la rama actual.

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
```

Ajustar `upstream/main` si la integración usa otra rama.

## Más contexto

- Guía de desarrollo: [guides/development/DEVELOPMENT.md](../../guides/development/DEVELOPMENT.md)
- Scripts: [guides/development/SCRIPTS.md](../../guides/development/SCRIPTS.md)
- Validación general: [guides/testing/VALIDATION.md](../../guides/testing/VALIDATION.md)
