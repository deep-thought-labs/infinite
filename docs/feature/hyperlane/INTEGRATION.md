# Hyperlane en Infinite Drive — registro técnico de integración

## Propósito de este documento (lectores humanos y modelos de IA)

Este archivo está pensado para **auditoría y revisión cruzada**:

- **Entrada A:** una guía tipo tutorial para integrar Hyperlane en una app Cosmos (pasos `go.mod`, `app` con `depinject`, `app.yaml`, codec opcional, compilación).
- **Entrada B:** lo que **realmente implementó** este repositorio ([**infinite**](https://github.com/deep-thought-labs/infinite), cadena Infinite Drive) y **por qué** se desvió de la guía donde lo hizo.

Un revisor (humano o IA) debe poder:

1. Comparar **cada paso de la guía original** con **el equivalente en código** (o su ausencia intencional).
2. Juzgar si las desviaciones son **coherentes** con la arquitectura existente del proyecto y si mantienen **equivalencia funcional** donde aplica.
3. Identificar **lagunas** (p. ej. CLI Hyperlane, puente ERC-20) que no equivalen a “incorrecto”, sino a **trabajo pendiente documentado**.

La narrativa técnica detallada vive aquí; el índice breve está en [README.md](README.md). **Operación y funcionalidad completa** (deploy Cosmos, registry, EVM): [OPERATIONS.md](OPERATIONS.md). **Bitácora de cierre de fase código:** [logs/2026-04-03-hyperlane-integration.md](../../fork-maintenance/logs/2026-04-03-hyperlane-integration.md).

---

## Revisión externa (resumen a retener)

Se contrastó este documento y el cableado con la documentación de referencia de **hyperlane-cosmos** `v1.2.0-rc.0` (README + `tests/simapp`). **Conclusión revisor:** la integración es **funcionalmente equivalente** a la guía oficial; las desviaciones (sin `depinject`/`app.yaml`, `go.mod` en `infinited`, Bech32 del fork) son **intencionales y coherentes** con el patrón manual de `NewExampleApp`.

**Riesgos o seguimiento (no invalidan el módulo Cosmos):**

- **Orden y firmas de constructores** de keepers: si `hyperlane-cosmos` cambia APIs en versiones futuras, revisar `app.go`.
- **Cadenas vivas:** los stores deben crearse en el **software-upgrade** previsto; aquí quedan ligados al plan **`infinite-v0.1.10-to-v0.2.0`** (ver abajo y [`infinited/upgrades.go`](../../../infinited/upgrades.go)).
- **EVM / ERC-20:** Warp mintea en **bank**; visibilidad en MetaMask/Blockscout como ERC-20 puede requerir trabajo adicional vía **`x/erc20`** o precompilados (fuera del alcance de la integración “solo módulos Cosmos” de esta fase).
- **Contratos Solidity Hyperlane:** la CLI de despliegue EVM es **fase posterior** si se busca la experiencia dual Cosmos + contratos.

---

## Contexto del proyecto

**Repositorio GitHub:** [**deep-thought-labs/infinite**](https://github.com/deep-thought-labs/infinite) (nombre del repo: `infinite`) — fork de **[cosmos/evm](https://github.com/cosmos/evm)** que implementa la cadena **Infinite Improbability Drive** (“Infinite Drive”).

**Stack:** Cosmos SDK + CometBFT + **EVM** (`x/vm`), ERC-20, IBC, feemarket, etc., con **identidad propia** (denominación base `drop`, chain IDs, prefijos Bech32, binario **`infinited`** en lugar del **`evmd`** de ejemplo upstream). La política identidad vs alineación upstream: [UPSTREAM_DIVERGENCE_RECORD.md](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md).

**Estructura monorepo relevante:**

| Ubicación | Módulo Go | Rol |
|-----------|-----------|-----|
| Raíz del repo | `github.com/cosmos/evm` | Librería Cosmos EVM, tests, `x/*`; **no** construye el daemon con Hyperlane en este diseño. |
| **`infinited/`** | `github.com/cosmos/evm/infinited` | Daemon **`infinited`**, `NewExampleApp`, `go.mod` con dependencia Hyperlane, CLI raíz. |

**Papel de Hyperlane:** capa **Hyperlane** (`x/core`, `x/warp`) **adicional** al stack anterior; **no** reemplaza IBC ni el EVM. Convive en la misma `BaseApp` que el resto de módulos.

**Documentación general del fork:** [docs/README.md](../../README.md), [docs/guides/README.md](../../guides/README.md).

---

## Alcance de la integración Hyperlane

| Ítem | Valor |
|------|--------|
| Repositorio módulo | [github.com/bcp-innovations/hyperlane-cosmos](https://github.com/bcp-innovations/hyperlane-cosmos) |
| Versión usada | **`v1.2.0-rc.0`** (recomendación abril 2026 en la guía de referencia) |
| Submódulos integrados | **`x/core`** (mailbox, ISM, post-dispatch), **`x/warp`** (tokens colateral / sintético) |
| Nombres de módulo on-chain | `hyperlane` (`hyperlanetypes.ModuleName`), `warp` (`warptypes.ModuleName`) |
| Binario | **`infinited`** (no `hypd` del tutorial genérico) |

---

## Guía de referencia original (resumen fiel de los pasos esperados)

La siguiente numeración reproduce la **lógica** de una guía estándar de integración (p. ej. instrucciones internas alineadas con el `simapp` de `hyperlane-cosmos`), **no** es texto literal de un PDF. Sirve como **contrato** para la tabla de equivalencias más abajo.

1. **Dependencias:** `go get github.com/bcp-innovations/hyperlane-cosmos@v1.2.0-rc.0` y `go mod tidy` en la **raíz del proyecto** (donde viva el `go.mod` de la app).
2. **`app.go`:** imports side-effect `_` de `x/core` y `x/warp`, tipos `keeper` de core y warp; struct `App` con `HyperlaneKeeper` y `WarpKeeper`; en `New`, **`depinject.Inject`** con `AppConfig()`, `Supply(logger, appOpts)`, punteros a **todos** los keepers incluyendo `HyperlaneKeeper` y `WarpKeeper`.
3. **Upgrade de stores (si mainnet ya existe):** `storetypes.StoreUpgrades{Added: []string{hyperlane, warp}}` + `SetStoreLoader` con altura de upgrade.
4. **`app.yaml` (config de módulos):** `runtime.init_genesis` incluye `hyperlane` y `warp`; en `auth`, `module_account_permissions` para cuentas `hyperlane` y `warp` (warp con `minter`, `burner`); bloques `name: hyperlane` y `name: warp` con `@type` de módulo protobuf y `enabled_tokens: [1, 2]` en warp.
5. **Codec (opcional):** `hyperlanetypes.RegisterInterfaces` / `warptypes.RegisterInterfaces` si hiciera falta fuera del flujo automático.
6. **Compilar y ejecutar:** `make build`, arranque con el binario de la cadena (ej. `hypd start` en la guía genérica).

**Referencia upstream del módulo:** [tests/simapp](https://github.com/bcp-innovations/hyperlane-cosmos/tree/main/tests/simapp) en `hyperlane-cosmos` (`app.yaml` embebido, `depinject`, `runtime.App`).

---

## Matriz: guía original → implementación en el repositorio infinite

| Paso guía | Qué dictaba la guía | Qué hicimos en este repo | Por qué | ¿Equivalencia funcional? |
|-----------|---------------------|---------------------------|---------|---------------------------|
| 1 `go.mod` | `go get` en **raíz** del proyecto | `require` en **`infinited/go.mod`** (`module github.com/cosmos/evm/infinited`) | El daemon y `NewExampleApp` viven en el submódulo `infinited/`; la raíz es otro módulo Go. | **Sí** para el binario `infinited`. La raíz no necesita la dependencia para compilar el daemon. |
| 2a Imports | `_` core + warp + aliases keeper | Imports **nombrados** `hyperlanecore`, `hyperlanekeeper`, `hyperlanetypes`, `hyperlanewarp`, `warpkeeper`, `warptypes` (sin solo `_`) | Se usan `NewAppModule` y tipos explícitos; los `_` solo fuerzan side-effects innecesarios aquí. | **Sí** — los paquetes se enlazan y registran vía `NewAppModule`. |
| 2b Struct App | Campos `HyperlaneKeeper`, `WarpKeeper` | Campos homónimos en **`EVMD`** en [`infinited/app.go`](../../../infinited/app.go) | Misma app struct pattern que el resto del fork (`EVMD`). | **Sí.** |
| 2c `depinject.Inject` | Un único `Inject` que rellena keepers | **No** se usa `depinject` para Hyperlane | `NewExampleApp` ya cablea decenas de keepers a mano (patrón cosmos/evm + fork). Introducir `runtime.App` + YAML solo para Hyperlane fragmentaría la app. | **Sí a nivel de módulos registrados y keepers**, con **distinto** mecanismo de composición. |
| 2d Orden / init keepers | Inyectado por framework | Tras `Erc20Keeper`: `hyperlanekeeper.NewKeeper` → puntero en `HyperlaneKeeper`; luego `warpkeeper.NewKeeper(..., app.HyperlaneKeeper, []int32{1,2})` | Warp debe registrar rutas en el `AppRouter` del core; el orden es obligatorio. | **Sí.** |
| 3 `app.yaml` | Módulos y permisos en YAML | **No hay `app.yaml`** para la app | No se adoptó `appconfig`/Compose en `infinited`. Permisos replicados en Go (`permissions.go`); módulos en `module.NewManager`. | **Sí** para permisos y presencia de módulos; **no** hay paridad de formato YAML. |
| 3b `init_genesis` YAML | Lista incluye `hyperlane`, `warp` | Mismo orden lógico en `SetOrderInitGenesis` / `SetOrderExportGenesis` (`hyperlane` antes de `warp`) | Coherencia con dependencia warp→core. | **Sí.** |
| 3c `bech32_prefix: hyp` en ejemplo YAML | — | Se mantiene el prefijo Bech32 **del fork Infinite Drive** (configuración existente de cadena), no se forzó `hyp` | `hyp` era ejemplo del simapp genérico; cambiar el HRP rompería identidad y tests del fork. | **Desviación intencional** respecto al **ejemplo** YAML; **correcta** para esta cadena. |
| 4 Store upgrade | `SetStoreLoader` + `Added` stores | **`StoreUpgrades.Added`** con `hyperlane` y `warp` en el plan **`infinite-v0.1.10-to-v0.2.0`** ([`infinited/upgrades.go`](../../../infinited/upgrades.go)) | Decisión de producto: **un solo plan** de gobernanza ya previsto para redes que suben de `v0.1.10` a la línea que incluye Hyperlane; evita un segundo nombre de plan solo para stores. | **Sí** para cadenas que ejecutan ese upgrade. Génesis nueva: las keys ya están en `NewKVStoreKeys` (el loader en altura no aplica). |
| 5 Codec | Opcional `RegisterInterfaces` | **Sí:** `hyperlanetypes.RegisterInterfaces` y `warptypes.RegisterInterfaces` justo después de `evmencoding.MakeConfig` | Equivalente al paso opcional, antes de `BasicModuleManager.RegisterInterfaces`. | **Sí.** |
| 6 Build / binario | `hypd` o binario del ejemplo | `infinited` — `go build ./cmd/infinited`, `make build-from-infinited` | Nombre del binario del fork. | **Sí** (mismo rol operativo). |

---

## Inventario concreto de cambios en el código

### `infinited/go.mod`

- `require github.com/bcp-innovations/hyperlane-cosmos v1.2.0-rc.0` (y dependencias transitivas resueltas por MVS).

### `infinited/app.go`

- **Registry:** tras `evmencoding.MakeConfig(evmChainID)` → `RegisterInterfaces` de `hyperlanetypes` y `warptypes`.
- **Store keys:** en `storetypes.NewKVStoreKeys(...)`, entradas `hyperlanetypes.ModuleName` y `warptypes.ModuleName` (strings de módulo `"hyperlane"`, `"warp"`).
- **Struct `EVMD`:** campos `HyperlaneKeeper *hyperlanekeeper.Keeper`, `WarpKeeper warpkeeper.Keeper`.
- **Keepers:** `NewKeeper` de core con `appCodec`, `AccountKeeper.AddressCodec()`, `runtime.NewKVStoreService(keys[hyperlanetypes.ModuleName])`, **`authAddr`** (misma autoridad gobierno que el resto de la app), `BankKeeper`. Warp con los mismos más `HyperlaneKeeper` y `[]int32{1, 2}`.
- **`ModuleManager`:** `hyperlanecore.NewAppModule(appCodec, app.HyperlaneKeeper)`, `hyperlanewarp.NewAppModule(appCodec, app.WarpKeeper)`.
- **Orden:** `hyperlane` y `warp` añadidos a `SetOrderPreBlockers`, `SetOrderBeginBlockers`, `SetOrderEndBlockers`, y a la lista `genesisModuleOrder` (**hyperlane** antes de **warp**).

### `infinited/config/permissions.go`

- `maccPerms`: clave `hyperlane` sin permisos extra; clave `warp` con `minter` y `burner` (análogo al YAML de referencia).

### `infinited/upgrades.go`

- Para **`UpgradeName` = `infinite-v0.1.10-to-v0.2.0`**, `UpgradeStoreLoader` añade stores **`hyperlane`** y **`warp`** (`hyperlanetypes.ModuleName`, `warptypes.ModuleName`). Debe coincidir con el plan en gobernanza y con [migrations/infinite_v0.1.10_to_v0.2.0.md](../../migrations/infinite_v0.1.10_to_v0.2.0.md).

### `infinited/tests/integration/hyperlane_test.go`

- Pruebas **`TestHyperlane_*`** (paquete `integration`, mismo directorio que el resto de tests que usan `CreateEvmd`): validación del wiring sin levantar red; ver sección *Verificación local*.

### Documentación y trazabilidad

- [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto (fork)](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork): referencia cruzada.

---

## Decisiones ampliadas (síntesis)

1. **Manual vs `depinject`:** misma **superficie** de módulos Cosmos (genesis, begin/end, gRPC, mensajes), distinto **ensamblado** — alineado con `NewExampleApp` existente.
2. **`go.mod` en `infinited`:** refleja la **realidad del build** del daemon en este monorepo.
3. **Sin `app.yaml`:** configuración equivalente expresada en Go; reduce duplicación de fuentes de verdad.
4. **Bech32:** se preserva la identidad Infinite Drive, no el prefijo de ejemplo `hyp` del tutorial.
5. **Upgrade on-chain:** los stores de Hyperlane se incorporan al plan existente **`infinite-v0.1.10-to-v0.2.0`** (`StoreUpgrades.Added`), alineado con la intención de gobernanza y con el harness `TestChainUpgrade` que ya usa ese nombre de plan.
6. **CLI:** sin subcomandos Hyperlane dedicados en `root.go` en esta fase; API/gRPC vía módulos registrados.

---

## Cómo debe validar un revisor (checklist)

- [ ] Los nombres de store / módulo coinciden con los esperados por `hyperlane-cosmos` (`hyperlane`, `warp`).
- [ ] **Warp** se construye **después** de **core** y recibe el puntero al core keeper que implementa `CoreKeeper`.
- [ ] `enabled_tokens` `[1,2]` coincide con el YAML de referencia del simapp (colateral + sintético).
- [ ] Permisos de módulo para **warp** incluyen acuñación/quema según necesite el módulo.
- [ ] `RegisterInterfaces` está antes del uso masivo del codec en registro de módulos.
- [ ] `cd infinited && go test -race -tags=test -run TestHyperlane -count=1 ./tests/integration/` (cableado Hyperlane).
- [ ] Compilación: `cd infinited && go build -o /dev/null ./cmd/infinited` y/o `make build-from-infinited`.
- [ ] Para **red existente** que aún no pasó el upgrade: el plan **`infinite-v0.1.10-to-v0.2.0`** debe ejecutarse con un binario que incluya este `upgrades.go` para crear stores `hyperlane` / `warp` antes de usar los módulos en producción.
- [ ] Tras merge de **cosmos/evm**, `infinited/app.go` sigue conteniendo los bloques Hyperlane sin pérdida accidental.

---

## Verificación local

**Pruebas unitarias / de cableado (Hyperlane):** construyen `NewExampleApp` en memoria y comprueban store keys (`hyperlane`, `warp`), registro en `ModuleManager`, orden `InitGenesis` (core antes que warp), `HyperlaneKeeper` no nulo y presencia de módulos en `DefaultGenesis()`.

```bash
cd infinited && go test -race -tags=test -run TestHyperlane -count=1 ./tests/integration/
```

Archivo: [`infinited/tests/integration/hyperlane_test.go`](../../../infinited/tests/integration/hyperlane_test.go).

Compilación del binario:

```bash
cd infinited && go build -o /dev/null ./cmd/infinited
```

Desde la raíz del repo:

```bash
make build-from-infinited
```

Suite amplia del submódulo (incluye el paquete raíz `infinited`):

```bash
make test-infinited
```

---

## Relación con la política del fork

Hyperlane es una **extensión de producto** documentada frente a [cosmos/evm](https://github.com/cosmos/evm) en [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto (fork)](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork). Los merges upstream deben tratar **`infinited/app.go`** y **`infinited/go.mod`** como zonas sensibles.

---

## Referencias externas

- [Hyperlane — Cosmos SDK module (documentación)](https://docs.hyperlane.xyz/docs/alt-vm-implementations/cosmos-sdk)
- [bcp-innovations/hyperlane-cosmos](https://github.com/bcp-innovations/hyperlane-cosmos)
- [docs/fork-maintenance/README.md](../../fork-maintenance/README.md)

---

## Mantenimiento al integrar upstream

1. Resolver conflictos en **`infinited/app.go`** preservando orden de keepers y listas de módulos.
2. No subir de versión `hyperlane-cosmos` sin revisar notas de release y actualizar este documento si cambian APIs.
3. Anotar en la [bitácora de merge](../../fork-maintenance/logs/README.md) si el merge tocó Hyperlane.
