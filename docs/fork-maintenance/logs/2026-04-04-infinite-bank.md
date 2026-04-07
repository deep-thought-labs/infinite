# Bitácora — feature Infinite Bank (módulo `infinitebank`)

**Tipo:** integración de **feature del fork** (no merge con [cosmos/evm](https://github.com/cosmos/evm) upstream).  
**Objetivo:** trazabilidad de la extensión **`github.com/cosmos/evm/x/bank`** (`ModuleName` **`infinitebank`**) que expone **`MsgSetDenomMetadata`** para gobernanza.

---

## Metadatos

| Campo | Valor |
|--------|--------|
| Fecha apertura (documental) | 2026-04-04 |
| Estado | Implementación base entregada en repo; bitácora actualizable si se añaden mensajes, migraciones o más tests |
| Documentación de feature | Inglés: [`docs/feature/infinite-bank/README.md`](../../feature/infinite-bank/README.md) · [`INTEGRATION.md`](../../feature/infinite-bank/INTEGRATION.md) |
| Registro de divergencia | [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto](../UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork) |

---

## Alcance en código (referencia)

- Mensaje **`MsgSetDenomMetadata`**, autoridad = módulo **gov**, delegación en **`SetDenomMetaData`** del keeper del SDK **x/bank**.
- Proto **`cosmos.evm.bank.v1`**, código en **`x/bank/`**, registro en **`infinited/app.go`** (módulo SDK **`sdkbank`** + extensión **`bank`**).

---

## Entregables

- [x] Definición protobuf / `MsgSetDenomMetadata` y autorización en handler.
- [x] Cableado en `infinited` (`AppModule`, orden genesis / begin / end).
- [x] Pruebas mínimas en paquete `x/bank/types` (p. ej. type URL).
- [x] Documentación operativa en [INTEGRATION.md](../../feature/infinite-bank/INTEGRATION.md).
- [ ] Si en el futuro aplica: upgrade on-chain y entrada en `docs/migrations/`.

---

## Verificación ejecutada (referencia)

Ejemplos coherentes con el árbol actual del repo:

```bash
cd /ruta/al/repo && go test ./x/bank/... -count=1
cd infinited && go build -o /dev/null ./cmd/infinited
```

*(Añadir SHAs de commit o enlace a PR si la política interna lo pide.)*

---

## CI / `golangci-lint` sobre `x/bank` (2026-04-05)

En el job de **lint** (p. ej. artefacto de logs tipo `logs_63353780992` en PR **#7**), **`golangci-lint`** falló solo en paquetes tocados por este feature. Causas y remedios:

| Linter | Archivos | Causa | Corrección |
|--------|-----------|--------|------------|
| **gci** | `x/bank/keeper/msg_server.go`, `msg_server_test.go`, `module.go`, `types/typeurl_test.go` | Orden de imports distinto al definido en [`.golangci.yml`](../../../.golangci.yml) (`standard` → `github.com/cosmos` → `cosmossdk.io` → `github.com/cosmos/cosmos-sdk`, etc.). | `golangci-lint run --fix ./x/bank/...` (o `make lint-fix` en la raíz del repo). |
| **staticcheck SA1019** | `msg_server_test.go` | Uso de **`sdk.WrapSDKContext`**, deprecado: `sdk.Context` ya implementa `context.Context`. | Devolver el `sdk.Context` de `testutil.DefaultContext(...).WithEventManager(...)` directamente como `context.Context`; **`UnwrapSDKContext`** sigue funcionando por type assert. |
| **unconvert** | `msg_server_test.go` | `string(attrs[i].Key)` / `string(attrs[i].Value)` redundantes: en CometBFT **`EventAttribute.Key` y `Value` ya son `string`**. | Comparar con `attrs[i].Key` y `attrs[i].Value` sin conversión. |
| **staticcheck SA1019** | `module.go` | `var _ module.AppModule = AppModule{}` usa tipo deprecado en el SDK (sigue siendo útil para comprobación en compilación con **`module.Manager`**). | **`//nolint:staticcheck`** en la línea anterior, con comentario explicando el motivo; el comentario debe ir **solo en su línea** para no romper **gci**. |

**Verificación local recomendada** (paridad con CI):

```bash
cd /ruta/al/repo
$(go env GOPATH)/bin/golangci-lint run --timeout=15m ./x/bank/...
go test -race -tags=test ./x/bank/... -count=1
```

### `test-unit-cover` / integración: timeout y Ledger (contexto ya documentado en el fork)

En CI, el workflow **Tests** ejecuta la cobertura en **cuatro bloques** (matriz sobre `make test-unit-cover-*`): ver [TESTING.md — Granular coverage blocks](../../guides/development/TESTING.md#granular-coverage-blocks-test-unit-cover) y [CI_CD.md — Path filtering](../../guides/infrastructure/CI_CD.md#path-filtering-docs-only-changes). Un fallo por timeout en **`infinited/tests/integration`** aparece entonces como **entrada de matriz** (p. ej. objetivo **`test-unit-cover-infinited-integration`**), sin enmascarar el resto de bloques.

El bloque **`test-unit-cover-infinited-integration`** (misma suite que antes formaba parte del monolito **`make test-unit-cover`**) puede terminar en **`panic: test timed out after 15m0s`** en el paquete **`github.com/cosmos/evm/infinited/tests/integration`** (ej. observado alrededor de **`TestGenesisTestSuite` / `TestExportGenesis`**), con volcados donde aparecen **godbus/dbus** y mensajes tipo **“check your Ledger”**: en GitHub Actions **no hay dispositivo ni daemon** esperado, así que el proceso puede **bloquearse hasta el límite de `go test` del bloque** (`-timeout=15m` en `COMMON_COVER_ARGS` del `Makefile`).

**Esto no viene del feature `x/bank` en sí**; es de la misma **familia de riesgos** que ya se trató en otras partes del historial documental del repo (sin repetir aquí el análisis técnico completo):

| Dónde | Qué documenta |
|--------|----------------|
| [Bitácora merge 2026-03-21 — estabilización `infinited`](2026-03-21-merge-upstream-main.md#cambios-aplicados) | Correcciones a **tests de wallets / Ledger** bajo **`tests/integration/wallets/`** (HRP `infinite`, fixtures, checksum amino). Mismo eje **integración + Ledger**, **otro path** que `infinited/tests/integration`. |
| [Bitácora merge 2026-03-21 — addendum CI](2026-03-21-merge-upstream-main.md#addendum--ci-y-codeql-tras-abrir-pr-2026-04-01) | Flakes bajo **`-race`** y cobertura CI (ej. mempool Krakatoa); enfoque **timing bajo `-race`**, no Ledger. |
| [`TESTING.md` — Mempool Krakatoa](../../guides/development/TESTING.md#mempool-krakatoa-tests-under-test-unit-cover) | Krakatoa bajo **`-race`** en el bloque **`test-unit-cover-evm-core`** (antes, segunda pasada monolítica en raíz). |
| [`TESTING.md` — Granular coverage blocks](../../guides/development/TESTING.md#granular-coverage-blocks-test-unit-cover) | Cuatro bloques `make test-unit-cover-*`, matriz en **`test.yml`**, Codecov por `flags`. |
| [`UPSTREAM_DIVERGENCE_RECORD.md` — § Estabilidad CI (tests Go)](../UPSTREAM_DIVERGENCE_RECORD.md#estabilidad-ci-tests-go) | Krakatoa (`AllowUnsafeSyncInsert`, `TestKrakatoaMempool_ReapNewBlock`, **`require.Eventually`**) y **`CheckTxsQueuedAsync`** frente a flakes en **`test-unit-cover`**. |
| [CHANGELOG — Infinite Drive UNRELEASED / BUG FIXES](../../../CHANGELOG.md) | [\#5](https://github.com/deep-thought-labs/infinite/pull/5), [\#6](https://github.com/deep-thought-labs/infinite/pull/6) (Krakatoa, `CheckTxsQueuedAsync`) como **deflakes de CI** ya integrados. |

**Seguimiento sugerido** si el timeout en **`infinited/tests/integration`** se reproduce: revisar si algún subtest o dependencia intenta **Ledger real** en CI (skip con build tag / env, mock, o separar job), alineado con lo ya hecho para **`tests/integration/wallets`**. [PLAYBOOK.md — A.7](../PLAYBOOK.md#a7-tests-y-apis-tras-merge-upstream) y [VERIFICATION.md](../VERIFICATION.md) recuerdan validar explícitamente **`infinited/tests/integration/...`**.

---

## SHAs / PR (opcional)

*(Enlaces o commits de referencia.)*

---

## Notas para próximos merges con cosmos/evm

Revisar **`infinited/app.go`**, **`x/bank/**`**, **`infinited/go.mod`**, **`infinited/upgrades.go`** si hubo migraciones. Ver [MERGE_STRATEGIES.md — §1 Zonas protegidas](../MERGE_STRATEGIES.md#1-zonas-protegidas-no-resolver-a-ciegas-con-upstream).
