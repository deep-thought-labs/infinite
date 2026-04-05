# Infinite Bank — extensión del módulo `bank`

**Estado:** **Part A** — implementado **`MsgSetDenomMetadata`** (módulo on-chain `infinitebank`, ver [INTEGRATION.md](INTEGRATION.md)). Más mensajes u operación (CLI, pruebas de integración) pueden añadirse después.

Esta carpeta describe la extensión del módulo **Bank** del SDK en **Infinite Drive** (`infinited`) para incorporar **mensajes Cosmos personalizados** (además del comportamiento estándar de `x/bank`).

## Alcance previsto

- Extender o complementar la superficie de mensajes del módulo bank con operaciones propias del fork (detalle técnico pendiente de cierre de diseño).
- Mantener trazabilidad frente a [cosmos/evm](https://github.com/cosmos/evm) y procedimientos de merge del fork.

## Documentos en esta carpeta

| Documento | Contenido |
|-----------|-----------|
| [**INTEGRATION.md**](INTEGRATION.md) | Código, proto, rutas en repo; **[cómo usar](INTEGRATION.md#cómo-usar)** (propuesta gov, `proposal.json`, CLI); **[cómo probar](INTEGRATION.md#cómo-probar)** (tests, build, cadena local). |
| [**README.md**](README.md) | Este índice. |

## Contexto en el binario (referencia actual)

Hoy el keeper estándar se instancia en [`infinited/app.go`](../../../infinited/app.go) (`bankkeeper.NewBaseKeeper`, `bank.NewAppModule`). Cualquier extensión deberá actualizar esta documentación y el [registro de divergencia](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork).

## Trazabilidad y mantenimiento del fork

- **Divergencia / extensiones de producto:** [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto (fork)](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork).
- **Bitácora de la implementación:** [logs/2026-04-04-infinite-bank.md](../../fork-maintenance/logs/2026-04-04-infinite-bank.md).

## Referencias cruzadas

- Mantenimiento del fork: [`docs/fork-maintenance/README.md`](../../fork-maintenance/README.md)
- Pruebas: [`docs/guides/development/TESTING.md`](../../guides/development/TESTING.md)
