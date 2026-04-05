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

## SHAs / PR (opcional)

*(Enlaces o commits de referencia.)*

---

## Notas para próximos merges con cosmos/evm

Revisar **`infinited/app.go`**, **`x/bank/**`**, **`infinited/go.mod`**, **`infinited/upgrades.go`** si hubo migraciones. Ver [MERGE_STRATEGIES.md — §1 Zonas protegidas](../MERGE_STRATEGIES.md#1-zonas-protegidas-no-resolver-a-ciegas-con-upstream).
