# Bitácora de merge upstream — marzo 2026 (`upstream/main` → fork)

**Estado:** cerrada (2026-03-21).  
Procedimiento: [PLAYBOOK.md](../PLAYBOOK.md), [UPSTREAM_DIVERGENCE_RECORD.md](../UPSTREAM_DIVERGENCE_RECORD.md). Estrategias de integración futuras: [MERGE_STRATEGIES.md](../MERGE_STRATEGIES.md).

## Metadatos

| Campo | Valor |
|--------|--------|
| Fecha inicio | 2026-03-19 |
| Fecha cierre | 2026-03-21 |
| Responsable(s) | — (sesión de integración; completar si aplica política interna) |
| Rama local de trabajo | `red/merge-cosmos-evm` |
| Rama/ref upstream fusionada | `upstream/main` (integrada vía rama `upstream-main`) |
| SHA upstream (punta fusionada) | `50b4817017187cbda2a0af767fda39a895b9989a` — *fix: handle replacement txs in TxStore (#1074)* |
| SHA local (antes del merge commit) | `69b445a9ca6b68c92e18ba9086c0584962a60cfb` |
| SHA commit de merge | `8bc0bd3364a779b278b4fef6135bd78b30170c0f` — *Merge branch 'upstream-main' into red/merge-cosmos-evm* |
| SHA commit de cierre documental | Resolver con `git log -1 --format=%H -- docs/fork-maintenance/logs/2026-03-merge-upstream-main.md` en la rama donde se fusione esta bitácora (commit que archiva este archivo). |

## Objetivo

Integrar `upstream/main` en el fork Infinite Drive, resolver conflictos y estabilizar tests (`infinited`) tras el merge. Los **workflows de GitHub Actions** quedan fuera del cierre funcional de esta bitácora: se planifica una **pasada dedicada** de alineación con upstream conservando `release.yml` (ver [MERGE_STRATEGIES.md](../MERGE_STRATEGIES.md) y seguimiento post-merge).

## Línea base (opcional)

- Ruta o adjunto del output de `./scripts/list_all_customizations.sh upstream/main` antes del merge:  
  `/tmp/diff-pre-merge-upstream-main.txt`

## Conflictos resueltos

| Archivo | Tipo | Resumen de la decisión | Riesgo / notas |
|---------|------|-------------------------|----------------|
| `go.mod` | manual | Contenido de dependencias indirectas y versiones `golang.org/*` acorde a upstream; se mantiene `replace github.com/cosmos/evm => ./` del fork. | Ejecutar `go mod tidy` localmente si el entorno tiene Go. |
| `go.sum` | manual | Entradas nuevas upstream (p. ej. jhump/protoreflect, mockery, wlynxg/anet, golang.org/x/mod). | Verificar con `go mod tidy` + build. |
| `README.md` | ours + limpieza | README de marca Infinite Drive; se descarta el bloque promocional de “What is Cosmos EVM?” del upstream. | — |
| `Makefile` | manual | Build sigue siendo `infinited` (`INFINITED_DIR`); `test-system` usa `build-v05` con **`SYSTEMTEST_LEGACY_TAG`** apuntando al release del **fork** en GitHub (no `v0.5.1` de cosmos/evm). El binario legacy se obtiene **solo** por descarga verificada desde ese release; el binario de la rama actual se copia como `binaries/evmd`. | Requiere release con artefactos Linux + `checksums.txt` en GitHub; ver *System tests y upgrades*. |
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
- **Makefile / systemtests**: binario real `infinited` en `build/`; copia con nombre `evmd` solo para la suite que aún espera ese nombre. Baseline de upgrade: **`SYSTEMTEST_LEGACY_TAG`** + descarga desde **GitHub Releases** (defecto **`v0.1.11`**) — ver *System tests y upgrades on-chain (fork)*.
- **CI**: conservar fuzz tests del fork en `test.yml` hasta la **alineación dedicada** de workflows con upstream.

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

Estado final (sesión de estabilización): **OK** (suite `infinited` completa en verde).

## Verificación (cierre de bitácora)

| Check | Resultado (OK / falló / N/A) | Notas |
|-------|------------------------------|-------|
| Sin marcadores `<<<<<<<` en el árbol (`grep -R '^<<<<<<<' . --exclude-dir=.git`) | OK | Sin coincidencias en código/markdown/yaml relevante. |
| `go mod tidy` (raíz y `infinited/`) | OK | Ejecutado al cierre de bitácora. |
| Sin imports `github.com/cosmos/evm/evmd` / sin árbol `evmd/` residual en raíz | OK | Sin imports `evmd` en `*.go`; sin directorio `evmd/` en la raíz del módulo. |
| `./scripts/validate_customizations.sh` | OK | Advertencias esperadas: `go.mod` / `go.sum` difieren de upstream más allá de `replace`. |
| `make build` | OK | Genera `build/infinited`. |
| `make install` | N/A en entorno de cierre | Verificar en máquina con `GOPATH`/`GOBIN` escribible (p. ej. CI o laptop del equipo). |
| `make test-unit` | pendiente | Recomendado antes de fusionar PR a `main`; no ejecutado en esta sesión de cierre. |
| `make test-system` | pendiente / validar | Requiere Foundry, **release en GitHub** para `$(SYSTEMTEST_LEGACY_TAG)` (artefactos + `checksums.txt`) y compatibilidad runtime del binario legacy; ver *System tests y upgrades on-chain (fork)*. |
| `make test-infinited` | OK | Ejecutado al cierre (~10 min); todos los paquetes listados OK. |
| `cd infinited && go test ./tests/integration/...` (focalizado) | OK | Cubierto por `make test-infinited`. |
| Otros (p. ej. `make test-all`) | pendiente | Fuera del alcance de este cierre. |

## GitHub Actions (alineación con upstream)

Rama de trabajo: `red/ci-align-upstream-2026-03` (PR sugerido → `red/merge-cosmos-evm` o `main` según política del equipo).

| Campo | Valor |
|--------|--------|
| SHA `upstream/main` usado como fuente de workflows | `50b4817017187cbda2a0af767fda39a895b9989a` (misma punta que el merge `8bc0bd33`) |
| ¿`release.yml` conservado del fork sin cambios? | **Sí** |
| Jobs fork-only | **CodeQL** (`codeql-analysis.yml`); patrones ampliados con `infinited/go.mod`, `infinited/go.sum` |
| Ajustes `evmd` → `infinited` | `build.yml`, `test.yml` (patrones diff), `jsonrpc-compatibility.yml`, nombres de paso en `tests-compatibility-*.yml` |
| Novedades tomadas de upstream | `dependencies.yml`, `stale.yml`. Tras copiar upstream, runners **`depot-ubuntu-*`** sustituidos por **`ubuntu-latest`** (fork sin Depot) en `lint`, `test`, `system-test`, `jsonrpc`, `build`. |
| `make test-fuzz` | **No** reañadido: upstream no incluye job y el `Makefile` actual no define `test-fuzz` (reintroducir job + target si el equipo lo retoma). |
| Secretos / jobs | `trigger-docs-update` / `bsr-push` siguen requiriendo secretos del org; sin secretos, fallarán hasta configurarlos o deshabilitar. |

## System tests y upgrades on-chain (fork)

Upstream asume a menudo un **git tag** en el mismo repositorio para compilar el binario “viejo” del escenario de upgrade (`build-v05`). En **cosmos/evm** suele documentarse **`v0.5.1`**; en **este fork** ese tag puede no existir. La adaptación acordada: baseline **solo** desde **GitHub Releases** (sin `git checkout` del tag).

| Aspecto | Implementación en el fork |
|---------|---------------------------|
| Tag baseline | **`SYSTEMTEST_LEGACY_TAG`** en el `Makefile` (por defecto **`v0.1.11`**, release publicado en este repo). Sobreescribible: `make SYSTEMTEST_LEGACY_TAG=… test-system`. |
| Existencia del release | Debe existir en GitHub un **release** para ese tag con artefactos Linux (`infinite_Linux_*.tar.gz`) y `checksums.txt`. No hace falta tener el tag en el clon local para `build-v05`; CI descarga por HTTPS como en Linux. |
| Binarios (legacy baseline) | `build-v05` obtiene el binario **solo** desde el release del fork (**`SYSTEMTEST_LEGACY_REPO`**, default `deep-thought-labs/infinite`) con verificación SHA256 (`checksums.txt`) y assets Linux (`infinite_Linux_x86_64.tar.gz`, `infinite_Linux_ARM64.tar.gz`). No hay fallback a `git checkout` ni compilación local del tag. |
| Binarios (rama actual) | `test-system` sigue compilando la rama actual y copia `build/infinited` (o `EXAMPLE_BINARY`) a `tests/systemtests/binaries/evmd` para la suite. |
| Test de upgrade | `tests/systemtests/chainupgrade/v0_1_10_to_v0_1_12.go`: nombre del plan on-chain **`v0.1.10-to-v0.1.12`** — debe coincidir con **`UpgradeNameSystemTest`** en `infinited/upgrades.go` (este plan name es específico del system test). |
| CI | `.github/workflows/system-test.yml`: `fetch-depth: 0`, `fetch-tags: true`; el paso `make test-system` solo corre si **`GIT_DIFF`** matchea rutas relevantes (`.go`, `go.mod`, `*.toml`, workflow, etc.), igual que en upstream. |
| Ejecución local macOS | Nuevo target `make test-system-docker` ejecuta la prueba en contenedor Linux (`golang:1.25-trixie` + Foundry; glibc suficiente para binarios legacy que exijan p. ej. GLIBC_2.38+), recomendado cuando los artefactos legacy son Linux-only o el host presenta incompatibilidades de toolchain. |
| Correcciones posteriores | Se corrigió resolución de `docker` en `Makefile` para evitar `run: command not found` / `docker: command not found` por PATH incompleto en shells locales. También se eliminó `tests/systemtests/mempool/interface.go` (residuo conflictivo) que redeclaraba `TestSuite` y rompía compilación de system tests. |

**Verificación:** tras cambiar el tag o el flujo, ejecutar localmente `make test-system` o forzar un PR que toque rutas disparadoras del workflow y revisar el job *System Test*.

## Aprendizajes y puntos a recordar

Documentación canónica: [PLAYBOOK.md — A.7](../PLAYBOOK.md#a7-tests-y-apis-tras-merge-upstream).

- **`BlockGasLimit`**: en `ante/types/block.go` el límite sale de **`ConsensusParams().Block.MaxGas`**, no del `BlockGasMeter`; tests que simulen “tx gas > límite de bloque” deben usar **`WithConsensusParams`** y **clonar `BlockParams`** antes de mutar `MaxGas` (evita contaminar el `UnitTestNetwork` para subtests posteriores).
- **Identidad**: expectativas de denom (**`drop`**) y bech32 **`infinite`** en tests (`fee_checker`, EIP-712, mempool); orden de init de prefijos vs `MakeConfig`.
- **APIs**: keepers pueden perder métodos usados solo en integración (p. ej. **`GetTransientGasWanted`**); actualizar `tests/integration/ante` hasta que **`go build`** del paquete pase.
- **CI / runners:** al traer workflows de upstream, revisar **`runs-on`**: `depot-ubuntu-*` solo si hay Depot; si no, **`ubuntu-latest`**. Ver [MERGE_STRATEGIES §4.3](../MERGE_STRATEGIES.md#43-deltas-obligatorios-en-el-fork-tras-copiarfusionar-yaml).

## Seguimiento post-merge

- [ ] CHANGELOG actualizado (opcional hasta publicar versión; completar si el PR lo exige).
- [ ] [UPSTREAM_DIVERGENCE_RECORD.md](../UPSTREAM_DIVERGENCE_RECORD.md) actualizado — *omitir si no cambió inventario ni política en esta sesión*.
- [ ] Guía de migración consultada o actualizada (`docs/migrations/`) si aplica salto mayor.
- [x] **PR dedicado CI**: rama `red/ci-align-upstream-2026-03` — alineación con `upstream/main` @ `50b48170`, `release.yml` preservado, deltas `infinited` + CodeQL — ver [MERGE_STRATEGIES.md](../MERGE_STRATEGIES.md).
- [x] `make test-infinited` en verde al cierre de bitácora.
- [ ] CI en PR verde (tras abrir PR y completar `make test-unit` / jobs acordados).

## Referencias

- PR(s): *(añadir al abrir PR de `red/merge-cosmos-evm` → `main`)*  
- Issues: —
