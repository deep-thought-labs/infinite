# Infinite Bank — integración técnica

**Estado:** borrador inicial; completar cuando existan tipos de mensaje, handlers y pruebas.

## Objetivo

Documentar cómo el fork **extiende el módulo Bank** con **mensajes personalizados** (`Msg*` / servicios gRPC), manteniendo compatibilidad con el stack Cosmos SDK y con el binario `infinited`.

## Diseño (pendiente)

Completar esta sección con:

- Lista de **mensajes nuevos** (nombre, protobuf, autorización).
- **Keeper / decoradores** involucrados (extensión del keeper estándar, módulo auxiliar o fork de `x/bank` si aplica).
- **Registro en la app:** cambios en [`infinited/app.go`](../../../infinited/app.go), orden de módulos, `RegisterServices`, `SetOrder*` si es necesario.
- **Upgrade on-chain:** si se añaden stores o migraciones, enlazar el plan en [`docs/migrations/`](../../migrations/) y [`infinited/upgrades.go`](../../../infinited/upgrades.go).

## Verificación (pendiente)

Añadir comandos concretos cuando exista código, por ejemplo:

- `cd infinited && go build ./cmd/infinited`
- `cd infinited && go test ...` (paquetes / integración relevantes)

## Notas para merges upstream

Al sincronizar con `cosmos/evm`, revisar conflictos en **`infinited/app.go`**, en cualquier ruta bajo **`x/bank`** (o módulo elegido) y en **`go.mod`**. Preservar la extensión salvo decisión explícita documentada en la [bitácora](../../fork-maintenance/logs/2026-04-04-infinite-bank.md).
