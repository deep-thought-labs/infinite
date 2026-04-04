# Bitácora — integración Hyperlane en `infinited` (cierre de fase código)

**Tipo:** integración de **feature del fork** (no merge con [cosmos/evm](https://github.com/cosmos/evm) upstream).  
**Objetivo:** dejar trazabilidad en `docs/fork-maintenance/logs/` para operadores y futuros merges.

---

## Metadatos

| Campo | Valor |
|--------|--------|
| Fecha cierre (documental) | 2026-04 |
| Módulo externo | [github.com/bcp-innovations/hyperlane-cosmos](https://github.com/bcp-innovations/hyperlane-cosmos) **`v1.2.0-rc.0`** |
| Binario | `infinited` (`github.com/cosmos/evm/infinited`) |
| Plan on-chain de stores | **`infinite-v0.1.10-to-v0.1.12`** — `StoreUpgrades.Added`: `hyperlane`, `warp` |

---

## Entregables en código

- Dependencia y cableado: [`infinited/go.mod`](../../../infinited/go.mod), [`infinited/app.go`](../../../infinited/app.go), [`infinited/config/permissions.go`](../../../infinited/config/permissions.go).
- Upgrade: [`infinited/upgrades.go`](../../../infinited/upgrades.go).
- Pruebas de cableado: [`infinited/tests/integration/hyperlane_test.go`](../../../infinited/tests/integration/hyperlane_test.go) (`TestHyperlane_*`).
- Documentación feature: [`docs/feature/hyperlane/`](../../feature/hyperlane/README.md) — [INTEGRATION.md](../../feature/hyperlane/INTEGRATION.md), [OPERATIONS.md](../../feature/hyperlane/OPERATIONS.md).
- Registro de divergencia: [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto](../UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork).

---

## Verificación ejecutada (referencia)

- `cd infinited && go build ./cmd/infinited`
- `cd infinited && go test -race -tags=test -run TestHyperlane -count=1 ./tests/integration/`
- `make build-from-infinited` / `make test-infinited` según política del equipo antes de fusionar rama.

*(Completar SHAs de commit o enlace a PR si la política interna lo exige.)*

---

## Qué queda fuera de esta fase (operación Hyperlane)

El código **no** sustituye:

- `hyperlane core deploy` / **ISM+Mailbox** on-chain con **`HYP_KEY_COSMOSNATIVE`**.
- Registro en **Hyperlane Registry** (`metadata.yaml`, domainId, RPC, etc.).
- **Warp Routes** operativos (`hyperlane warp deploy`).
- Despliegue **EVM** separado (contratos en `x/vm`, clave `HYP_KEY`, metadata protocolo ethereum).

Detalle y orden recomendado: [**docs/feature/hyperlane/OPERATIONS.md**](../feature/hyperlane/OPERATIONS.md).

---

## Notas para próximos merges upstream

Al sincronizar con `cosmos/evm`, revisar conflictos en **`infinited/app.go`**, **`infinited/go.mod`** y **`infinited/upgrades.go`** preservando módulos `hyperlane` / `warp` y la dependencia pinnada salvo decisión explícita. Ver [MERGE_STRATEGIES.md — §1 Zonas protegidas](../MERGE_STRATEGIES.md#1-zonas-protegidas-no-resolver-a-ciegas-con-upstream).
