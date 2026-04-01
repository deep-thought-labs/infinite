# Registro de divergencia frente a upstream (Infinite Drive)

**Ámbito:** inventario técnico del repositorio **infinite-b** respecto a [cosmos/evm](https://github.com/cosmos/evm). Documento interno de mantenimiento y trazabilidad; **no** constituye especificación reutilizable para otras cadenas o forks.

**Procedimiento de merge, diffs y verificación:** [README.md](README.md) de esta carpeta, [PLAYBOOK.md](PLAYBOOK.md), [REFERENCE.md](REFERENCE.md), [VERIFICATION.md](VERIFICATION.md).

---

## Política (identidad vs upstream)

### Principio

Solo se personalizan aspectos de **identidad** de la cadena Infinite Drive. Lo técnico y operativo compartido con upstream debe alinearse con el árbol de [cosmos/evm](https://github.com/cosmos/evm).

### Ámbito permitido (identidad)

- Configuración de token (denominaciones, símbolos, nombres, metadatos)
- Chain IDs (Cosmos y EVM)
- Prefijos Bech32
- Nombre del binario y directorio: `infinited` (equivalente upstream: `evmd`)
- Marca (copyright, README, documentación propia)
- Archivos añadidos por este fork (guías, scripts, CI de release, etc.)

### Fuera de personalización arbitraria (prioridad upstream)

- `go.mod` / `go.sum` alineados con upstream (salvo nombre de módulo en `infinited/go.mod`)
- Dependencias y versiones
- Rutas de import: `github.com/cosmos/evm/...` (no `github.com/deep-thought-labs/infinite`)
- Lógica funcional compartida, correcciones y features procedentes de upstream
- Configuración técnica de build/CI salvo branding acordado

### Rutas de módulo

- Raíz: `github.com/cosmos/evm`
- Submódulo binario: `module github.com/cosmos/evm/infinited` (análogo a `evmd` upstream)
- Imports: `github.com/cosmos/evm/...` para el resto del árbol; **`github.com/cosmos/evm/infinited`** para el binario y tests bajo ese árbol
- **No** mezclar con imports **`github.com/cosmos/evm/evmd`** en código que deba usar el fork renombrado: Go resolvería también el módulo remoto upstream y genera conflictos con `go mod tidy` y árboles duplicados (`evmd/` residual vs `infinited/`). Tras merge, eliminar restos de `evmd/` en raíz si no son intencionales.
- Directiva `replace github.com/cosmos/evm => ./` solo para desarrollo local

### Disciplina en integraciones con upstream

No duplicar aquí el procedimiento detallado: seguir [PLAYBOOK.md](PLAYBOOK.md). Tras integrar, validar según [VERIFICATION.md](VERIFICATION.md) y, para listados de diff, [REFERENCE.md](REFERENCE.md). **GitHub Actions:** alinear workflows con `upstream/main` como parte del plan de merge, conservando `release.yml` y `.goreleaser.yml` del fork; detalle en [MERGE_STRATEGIES.md — §4](MERGE_STRATEGIES.md#4-github-actions-alinear-con-upstream-en-el-plan-de-merge).

---

## Token

### Valores

- Base denom: `drop`
- Display denom: `Improbability`
- Symbol: `42`
- Name: `Improbability`
- Description: `Improbability Token — Project 42: Sovereign, Perpetual, DAO-Governed`
- Decimals: `18`
- URI: `https://assets.infinitedrive.xyz/tokens/42/icon.png`

### Archivos

- `x/vm/types/params.go`: DefaultEVMDenom, DefaultEVMDisplayDenom, DefaultEVMChainID
- `testutil/constants/constants.go`: ExampleAttoDenom, ExampleDisplayDenom, ChainsCoinInfo[421018]
- `testutil/integration/evm/network/chain_id_modifiers.go`: GenerateBankGenesisMetadata (chain ID 421018)
- `infinited/genesis.go`: funciones de genesis que fijan denom `drop` (mint, staking, gov)
- `infinited/app.go`: `DefaultGenesis()` aplica los estados anteriores
- `infinited/tests/integration/create_app.go`: tests con configuración de identidad
- `scripts/customize_genesis.sh`: personalización de `genesis.json` por red (mainnet / testnet / creative); parámetros en JSON bajo `scripts/genesis-configs/`. Detalle operativo: [docs/guides/configuration/GENESIS.md](../guides/configuration/GENESIS.md)
- `scripts/genesis-configs/mainnet.json`, `testnet.json`, `creative.json`
- `scripts/setup_module_accounts.sh` y `scripts/genesis-configs/*-module-accounts.json`
- `local_node.sh`: desarrollo local con genesis ya ajustada
- `assets/pre-mainet-genesis.json`: metadatos de token

---

## Chain IDs

### Valores

- **Mainnet:** Cosmos `infinite_421018-1`, EVM `421018` (hex `0x66c9a`)
- **Testnet:** Cosmos `infinite_421018001-1`, EVM `421018001`
- **Creative:** Cosmos `infinite_421018002-1`, EVM `421018002`

### Archivos

- `testutil/constants/constants.go`, `x/vm/types/params.go`, `local_node.sh`
- `scripts/genesis-configs/*.json`, `scripts/customize_genesis.sh` (`configure_cosmos_chain_id`)

---

## Bech32

- Account: `infinite`
- Validator: `infinitevaloper`
- Consensus: `infinitevalcons`
- Archivo: `infinited/config/bech32.go`

---

## Rebranding y binario

- Paths de módulo: ver sección *Rutas de módulo* arriba.
- Directorio/binario: `infinited/` (upstream: `evmd/`).
- `Makefile`, `NOTICE`, `README.md` (raíz del proyecto).

Renombres representativos: `evmd/app.go` → `infinited/app.go`, `evmd/cmd/evmd/` → `infinited/cmd/infinited/`, etc. Entradas “deleted” bajo `evmd/tests/integration/` suelen corresponder a renombre a `infinited/tests/integration/`.

---

## Configuración técnica asociada a identidad

- **Power reduction:** `infinited/app.go` — `sdk.DefaultPowerReduction = utils.AttoPowerReduction` (comentario: `1 42 = 10^18 drop`)
- **Genesis por defecto:** `infinited/genesis.go` + `infinited/app.go` — denoms de mint/staking/gov en `drop` frente al default `stake` del SDK

---

## Archivos añadidos (no presentes en upstream)

### Documentación

- `docs/guides/*.md` y resto de guías bajo `docs/guides/`
- `docs/fork-maintenance/` (este registro y documentos de mantenimiento del fork)
- `tests/solidity/README.md` — guía específica del harness Solidity (`make test-solidity`) y convenciones del fork (prefijos Bech32, denom `drop`, estabilidad)

### Scripts

- `scripts/audit_command_name.sh`, `check_build_prerequisites.sh`, `compare_outputs.sh`, `infinite_health_check.sh`, `list_all_customizations.sh`, `test_outputs_before.sh`, `validate_customizations.sh`, `validate_token_config.sh`, `verify_command_name.sh`, `scripts/README_SCRIPTS.md`

### Configuración / tooling

- `assets/pre-mainet-genesis.json`, `.goreleaser.yml`, `.goreleaser.linux-only.yml`, `.github/workflows/release.yml`, `local_node.sh`
- [`.markdownlint.yml`](../../.markdownlint.yml) — calidad de documentación: **MD013** con `code_block_line_length: 200` en bloques de código (política del fork frente a líneas largas en ejemplos shell). Al fusionar con upstream, conservar este valor salvo acuerdo explícito; ver [MERGE_STRATEGIES.md — §4.6](MERGE_STRATEGIES.md#46-markdownlint).
- [Makefile](../../Makefile) — **`markdownlint_cli2_version`**: misma versión de `markdownlint-cli2` que empaqueta **`markdownlint-cli2-action@v16`** en CI ([`lint.yml`](../../.github/workflows/lint.yml)); **`make lint-md`** / **`make lint`** para reproducir localmente (Node `npx`). Exclusiones de `.md` bajo `tests/systemtests/Counter`, `tests/evm-tools-compatibility` y `**/node_modules/**` (deps vendorizadas por los harnesses JS): [`.markdownlint-cli2.jsonc`](../../.markdownlint-cli2.jsonc). Si se actualiza la etiqueta de la acción en GitHub, actualizar la variable en el mismo ciclo; ver [MERGE_STRATEGIES.md — §4.6](MERGE_STRATEGIES.md#46-markdownlint). **`SYSTEMTEST_LEGACY_TAG`** y `build-v05`: baseline de `make test-system` con descarga verificada (checksums) desde artefactos Linux del release en GitHub del fork; sin compilación local del tag; `test-system-docker` para hosts macOS; ver [bitácora — System tests y upgrades](logs/2026-03-merge-upstream-main.md#system-tests-y-upgrades-on-chain-fork).

### Estabilidad CI (harnesses JS)

- `scripts/compile_smart_contracts/compile_smart_contracts.py`: compila Solidity con Hardhat; se añadieron **reintentos** para evitar fallos transitorios de red al descargar `solc` en CI.
- `local_node.sh`: exporta `GOPATH`/`PATH` para asegurar que el binario instalado (`make install`) sea resoluble en shells locales.

### Alineación CI con upstream (Buf / protos)

- `.github/workflows/proto.yml`: el job `buf-breaking-action` compara `proto/` contra **`cosmos/evm` `main`** (upstream) en lugar de comparar contra el `main` del fork. Esto evita falsos “breaking changes” causados por protos que existían históricamente solo en el fork (p.ej. `precisebank`).

### Estabilidad CI (tests Go)

- `mempool/krakatoa_mempool_test.go`: el test `TestKrakatoaMempool_ReapPromoteDemotePromote` usa `require.Eventually` tras `Sync()` para evitar flakes bajo `-race`/CI (timing/concurrencia), sin cambiar la lógica funcional del mempool.

### Tests

- `infinited/tests/integration/create_app.go` (identidad)
- `infinited/tests/integration/*` (renombrados desde `evmd/`)
- `tests/integration/ante/test_evm_fee_market.go`, `tests/integration/ante/test_evm_unit_10_gas_wanted.go`

### Otros

- `ante/evm/10_gas_wanted.go` — eliminado en upstream; retenido en este fork
- Este archivo: `docs/fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md`
