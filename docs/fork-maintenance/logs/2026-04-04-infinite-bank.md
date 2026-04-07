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

**Nota (otro artefacto de CI):** el job **`test-unit-cover`** puede fallar por **`panic: test timed out after 15m0s`** en `infinited/tests/integration` (p. ej. `TestGenesisTestSuite` / `TestExportGenesis`), con trazas que sugieren bloqueo en **D-Bus / Ledger** en un runner sin hardware; es un problema **distinto** del lint de `x/bank` y puede requerir exclusión en CI, mock o más tiempo según política del equipo (ver también entradas de deflake en [CHANGELOG.md](../../../CHANGELOG.md)).

---

## SHAs / PR (opcional)

*(Enlaces o commits de referencia.)*

---

## Notas para próximos merges con cosmos/evm

Revisar **`infinited/app.go`**, **`x/bank/**`**, **`infinited/go.mod`**, **`infinited/upgrades.go`** si hubo migraciones. Ver [MERGE_STRATEGIES.md — §1 Zonas protegidas](../MERGE_STRATEGIES.md#1-zonas-protegidas-no-resolver-a-ciegas-con-upstream).
