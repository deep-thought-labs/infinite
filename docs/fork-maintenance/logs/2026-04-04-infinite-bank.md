# Bitácora — feature Infinite Bank (extensión `x/bank`)

**Tipo:** integración de **feature del fork** (no merge con [cosmos/evm](https://github.com/cosmos/evm) upstream).  
**Objetivo:** abrir trazabilidad desde el inicio de la implementación de **mensajes personalizados** sobre el módulo Bank; completar entregables y verificación al cerrar la fase.

---

## Metadatos

| Campo | Valor |
|--------|--------|
| Fecha apertura (documental) | 2026-04-04 |
| Estado | **En curso** — diseño e implementación de mensajes |
| Documentación de feature | [`docs/feature/infinite-bank/README.md`](../../feature/infinite-bank/README.md) · [`INTEGRATION.md`](../../feature/infinite-bank/INTEGRATION.md) |
| Registro de divergencia | [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto](../UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork) |

---

## Alcance declarado

- Extender el módulo **Bank** con al menos un **mensaje Cosmos personalizado** (detalle de tipos y semántica: pendiente en INTEGRATION.md).
- Mantener alineación con la política del fork (identidad vs upstream) descrita en [UPSTREAM_DIVERGENCE_RECORD.md](../UPSTREAM_DIVERGENCE_RECORD.md).

---

## Entregables (ir completando)

*(Añadir conforme se fusionen cambios en el repositorio.)*

- [ ] Definición protobuf / `Msg*` y autorización.
- [ ] Cableado en `infinited` (keepers, módulos, router).
- [ ] Pruebas (unitarias o integración).
- [ ] Actualización de [INTEGRATION.md](../../feature/infinite-bank/INTEGRATION.md) con rutas de archivos finales.
- [ ] Si aplica: plan de upgrade on-chain y entrada en `docs/migrations/`.

---

## Verificación ejecutada (referencia)

*(Completar al cerrar la fase: comandos `go build` / `go test`, `make`, etc.)*

---

## SHAs / PR (opcional)

*(Enlaces o commits de referencia cuando la política interna lo exija.)*

---

## Notas para próximos merges upstream

Revisar **`infinited/app.go`**, **`x/bank`** (o rutas del módulo elegido), **`infinited/go.mod`** y **`infinited/upgrades.go`** si hubo migraciones. Ver [MERGE_STRATEGIES.md — §1 Zonas protegidas](../MERGE_STRATEGIES.md#1-zonas-protegidas-no-resolver-a-ciegas-con-upstream).
