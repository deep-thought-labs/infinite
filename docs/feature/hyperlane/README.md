# Hyperlane — integración en Infinite Drive

**Estado:** la **integración en código** (Cosmos SDK) está documentada; lo que sigue es **operación**: despliegues y conexión real con el ecosistema Hyperlane — ver [OPERATIONS.md](OPERATIONS.md).

Este directorio enlaza la cadena **Infinite Improbability Drive** con [Hyperlane](https://hyperlane.xyz/) ([repo `infinite`](https://github.com/deep-thought-labs/infinite)).

## Qué hay en el código y qué no

- **`x/core` + `x/warp` en `infinited`** activan Hyperlane en la **parte Cosmos** del binario (estado nativo, Warp en Go, convivencia con IBC y EVM ya existentes).
- Eso **no** sustituye el trabajo **on-chain** que falta: en la práctica hay que tratar **Cosmos** y **EVM** como **dos líneas de trabajo** si quieres ambas experiencias — cada una con su despliegue, registry donde corresponda y consideración de **relayers** (sin relayers, los mensajes no completan el circuito). [OPERATIONS.md](OPERATIONS.md) resume objetivos pendientes, relayers y una noción breve de **seguridad (ISM)**.

## Documentos en esta carpeta

| Documento | Contenido |
|-----------|-----------|
| [**INTEGRATION.md**](INTEGRATION.md) | Código: repo, matriz técnica, upgrade de stores, tests. |
| [**OPERATIONS.md**](OPERATIONS.md) | Contexto **después del código**: dualidad Cosmos/EVM, qué queda por hacer, relayers, ISM a alto nivel, enlaces a la doc oficial. |
| [**README.md**](README.md) | Este índice. |

**Resumen técnico (código):** `hyperlane-cosmos@v1.2.0-rc.0` en [`infinited/go.mod`](../../../infinited/go.mod); [`infinited/app.go`](../../../infinited/app.go); [`infinited/config/permissions.go`](../../../infinited/config/permissions.go); stores en [`infinited/upgrades.go`](../../../infinited/upgrades.go) — [migración `infinite-v0.1.10-to-v0.1.12`](../../migrations/infinite_v0.1.10_to_v0.1.12.md). Pruebas: [`infinited/tests/integration/hyperlane_test.go`](../../../infinited/tests/integration/hyperlane_test.go).

## Trazabilidad y mantenimiento del fork

- **Registro de divergencia / extensiones:** [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto (fork)](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork).
- **Bitácora de cierre (fase código):** [logs/2026-04-03-hyperlane-integration.md](../../fork-maintenance/logs/2026-04-03-hyperlane-integration.md).

## Referencias cruzadas

- Mantenimiento del fork: [`docs/fork-maintenance/README.md`](../../fork-maintenance/README.md)
- Tests: [`docs/guides/development/TESTING.md`](../../guides/development/TESTING.md)
