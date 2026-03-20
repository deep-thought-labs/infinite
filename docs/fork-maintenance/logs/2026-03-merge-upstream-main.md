# Bitácora de merge upstream — PLANTILLA

> Copiar este archivo a `../logs/` y renombrar según [logs/README.md](../logs/README.md).  
> Eliminar bloques de ayuda comentados al cerrar la bitácora.

## Metadatos

| Campo | Valor |
|--------|--------|
| Fecha inicio | 2026-03-19 |
| Fecha cierre | 2026-03-19 (resolución conflictos pendiente cierre final) |
| Responsable(s) | — |
| Rama local de trabajo | `red/merge-cosmos-evm` |
| Rama/ref upstream fusionada | `upstream/main` (vía rama `upstream-main`) |
| SHA upstream (antes del merge) | *(ver `git merge-base` / historial; commit merge: `8bc0bd33`)* |
| SHA local (antes del merge) | *(bitácora previa en commit `69b445a9`)* |
| SHA merge resultante (tras cerrar) | *(tras commit de limpieza de conflictos)* |

## Objetivo

Integrar `upstream/main` en el fork Infinite Drive y **resolver marcadores de conflicto** que quedaron tras el merge inicial, según [PLAYBOOK.md](../PLAYBOOK.md) y [UPSTREAM_DIVERGENCE_RECORD.md](../UPSTREAM_DIVERGENCE_RECORD.md).

## Línea base (opcional)

- Ruta o adjunto del output de `./scripts/list_all_customizations.sh upstream/main` antes del merge:  
  `/tmp/diff-pre-merge-upstream-main.txt`

## Conflictos resueltos

| Archivo | Tipo | Resumen de la decisión | Riesgo / notas |
|---------|------|-------------------------|----------------|
| `go.mod` | manual | Contenido de dependencias indirectas y versiones `golang.org/*` acorde a upstream; se mantiene `replace github.com/cosmos/evm => ./` del fork. | Ejecutar `go mod tidy` localmente si el entorno tiene Go. |
| `go.sum` | manual | Entradas nuevas upstream (p. ej. jhump/protoreflect, mockery, wlynxg/anet, golang.org/x/mod). | Verificar con `go mod tidy` + build. |
| `README.md` | ours + limpieza | README de marca Infinite Drive; se descarta el bloque promocional de “What is Cosmos EVM?” del upstream. | — |
| `Makefile` | manual | Build sigue siendo `infinited` (`INFINITED_DIR`); `test-system` alinea con upstream `build-v05` / `v0.5.1` pero copia el binario como `evmd` donde `tests/systemtests` lo espera. | Los systemtests siguen usando flag `--binary evmd`. |
| `infinited/cmd/.../root.go` | manual | Imports sin duplicar; sin bloque conflictivo. | — |
| `infinited/cmd/.../testnet.go` | manual | Rutas `evmd` → `infinited` / `infinited/config` / `infinited/tests/network`. | — |
| `infinited/cmd/.../creator.go` | manual | Import `github.com/cosmos/evm/infinited` (no `evmd`). | — |
| `infinited/mempool.go` | theirs | Import de `github.com/cosmos/evm/mempool` (Krakatoa / experimental pool). | — |
| `infinited/upgrades.go` | theirs | Handler de upgrade solo `RunMigrations` como upstream; imports SDK `x/upgrade/types`. | Si la mainnet necesita lógica extra en ese upgrade, revisar aparte. |
| `infinited/test_helpers.go` | manual | `infinited/config` para bech32 en tests. | — |
| `testutil/.../chain_id_modifiers.go` | ours | Metadatos 421018 / `drop` / extended denom (identidad). | — |
| `infinited/tests/integration/balance_handler/helper.go` | manual | Unión: `evmibctesting` + `statedb` + `errorsmod`. | — |
| `infinited/tests/ibc/*.go` | manual | `infinited` + `integration` + `github.com/cosmos/evm` donde hace falta `evm.EvmApp`; recursive incluye `contracts`. | — |
| `.github/workflows/test.yml` | ours | Se mantiene el job `test-fuzz` del fork (upstream lo había eliminado). | — |

## Decisiones de fork (no triviales)

- **README**: prioridad identidad Infinite Drive frente al texto genérico de Cosmos EVM.
- **Makefile / systemtests**: binario real `infinited` en `build/`; copia con nombre `evmd` solo para la suite que aún espera ese nombre.
- **CI**: conservar fuzz tests del fork.

## Verificación

| Check | Resultado (OK / falló) | Notas |
|-------|------------------------|-------|
| `./scripts/validate_customizations.sh` | OK | Ejecutado tras limpiar marcadores. |
| `make build` / `make install` | pendiente en este entorno | `go` no está en PATH del runner; ejecutar en máquina dev/CI. |
| `make test-unit` | pendiente | — |
| Otros (p. ej. `make test-all`) | pendiente | — |

## Seguimiento post-merge

- [ ] CHANGELOG actualizado
- [ ] [UPSTREAM_DIVERGENCE_RECORD.md](../UPSTREAM_DIVERGENCE_RECORD.md) actualizado (solo si cambió el inventario o la política)
- [ ] Guía de migración consultada o actualizada (`docs/migrations/`)
- [ ] CI en PR verde

## Referencias

- PR(s): 
- Issues: 
