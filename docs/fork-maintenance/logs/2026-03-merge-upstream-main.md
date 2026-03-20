# Bitácora de merge upstream — PLANTILLA

> Copiar este archivo a `../logs/` y renombrar según [logs/README.md](../logs/README.md).  
> Eliminar bloques de ayuda comentados al cerrar la bitácora.

## Metadatos

| Campo | Valor |
|--------|--------|
| Fecha inicio | 2026-03-19 |
| Fecha cierre | 2026-03-20 (fecha informativa de último update; mismo proceso de merge) |
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

## Actualización de la misma sesión de merge (2026-03-19)

Se realizó una pasada de estabilización para dejar `make test-infinited` en verde tras la integración con upstream.

### Cambios aplicados

| Área | Archivo(s) | Decisión aplicada | Resultado |
|------|------------|-------------------|-----------|
| IBC test harness (SimApp vs EVM bech32) | `testutil/ibc/chain.go`, `infinited/tests/ibc/*` | Encapsular direcciones con helpers (`AccAddressForAccount`, `Bech32ForAccount`) y evitar uso directo de `GetAddress().String()` en cadenas SimApp. | Se eliminan errores `missing recipient address` y `hrp does not match ... expected 'cosmos' got 'infinite'` en suites IBC. |
| Setup de app para tests IBC/precompile | `infinited/tests/integration/create_app.go` | Inyectar en `SetupEvmd()` el estado ERC20 esperado por tests (`ExampleTokenPairs` + `WEVMOSContractMainnet`) sin cambiar defaults productivos de `infinited/genesis.go`. | `IsNativePrecompileAvailable` y flujos ICS20 precompile consistentes en tests. |
| Tests de wallets/ledger | `tests/integration/wallets/test_ledger_suite.go`, `tests/integration/wallets/test_legder.go` | Alinear HRP esperado con `sdk.GetConfig().GetBech32AccountAddrPrefix()`, normalizar direcciones de fixtures y corregir checksum inválido en dirección amino. | Se eliminan panics por prefijo (`expected infinite, got cosmos`) y mismatch de dirección esperada. |
| Tests ERC20 IBC callback | `tests/integration/x/erc20/test_ibc_callback.go` | Eliminar hardcode de `sdk.Bech32MainPrefix`; derivar direcciones desde bytes y recodificar con HRP activo. | Se eliminan fallos por `hrp does not match bech32 prefix`. |
| Tests EVM state transition | `tests/integration/x/vm/test_state_transition.go` | Reemplazar denom fijo `"aatom"` por `types.GetEVMCoinDenom()`. | Se corrigen fallos de refund/fee por mezcla de denoms (`aatom` vs `drop`). |

### Tests ejecutados en cierre

- `go test -tags=test -mod=readonly ./infinited/tests/ibc/...`
- `go test -tags=test -mod=readonly ./infinited/tests/integration -count=1`
- `make test-infinited`

Estado final: **OK** (suite `infinited` completa en verde).

## Verificación

| Check | Resultado (OK / falló) | Notas |
|-------|------------------------|-------|
| `./scripts/validate_customizations.sh` | OK | Ejecutado tras limpiar marcadores. |
| `make build` / `make install` | pendiente | No se ejecutó en este cierre (foco en estabilización de tests). |
| `make test-unit` | pendiente | No incluido en esta pasada. |
| `cd infinited && go test ./tests/integration/...` | OK | En verde tras correcciones de HRP/denom/tests. |
| `make test-infinited` | OK | En verde (incluye `tests/ibc` + `tests/integration` de `infinited`). |
| Otros (p. ej. `make test-all`) | pendiente | Fuera del alcance de este cierre. |

## Aprendizajes y puntos a recordar

Documentación canónica: [PLAYBOOK.md — A.7](../PLAYBOOK.md#a7-tests-y-apis-tras-merge-upstream).

- **`BlockGasLimit`**: en `ante/types/block.go` el límite sale de **`ConsensusParams().Block.MaxGas`**, no del `BlockGasMeter`; tests que simulen “tx gas > límite de bloque” deben usar **`WithConsensusParams`** y **clonar `BlockParams`** antes de mutar `MaxGas` (evita contaminar el `UnitTestNetwork` para subtests posteriores).
- **Identidad**: expectativas de denom (**`drop`**) y bech32 **`infinite`** en tests (`fee_checker`, EIP-712, mempool); orden de init de prefijos vs `MakeConfig`.
- **APIs**: keepers pueden perder métodos usados solo en integración (p. ej. **`GetTransientGasWanted`**); actualizar `tests/integration/ante` hasta que **`go build`** del paquete pase.

## Seguimiento post-merge

- [ ] CHANGELOG actualizado
- [ ] [UPSTREAM_DIVERGENCE_RECORD.md](../UPSTREAM_DIVERGENCE_RECORD.md) actualizado (solo si cambió el inventario o la política)
- [ ] Guía de migración consultada o actualizada (`docs/migrations/`)
- [x] CI local equivalente para `make test-infinited` en verde
- [ ] CI en PR verde

## Referencias

- PR(s): 
- Issues: 
