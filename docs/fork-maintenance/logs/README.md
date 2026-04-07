# Bitácoras de merge upstream

Aquí van las bitácoras de **cada integración con upstream**. **No esperes a tener el merge cerrado para crear el archivo:** cópialo desde la [plantilla](../templates/MERGE_LOG_TEMPLATE.md) en cuanto **empieces** el trabajo (primera sesión de merge, apertura de la rama de integración o primer commit relevante), rellena metadatos y objetivo, y ve completando conflictos, SHAs y verificación conforme avanzas. La bitácora se considera **cerrada** cuando la integración está fusionada (o archivada en el `main` del fork) y las secciones obligatorias —incluida la verificación— están completas, sin huecos críticos.

## Convención de nombres

`YYYY-MM-DD-descripcion-corta.md` (fecha completa cuando ayude a distinguir varias bitácoras en el mismo mes). Si basta con precisión mensual, `YYYY-MM-descripcion-corta.md` también es válido.

Ejemplos:

- `2026-03-21-merge-upstream-main.md`
- `2026-04-03-hyperlane-integration.md`
- `2026-04-04-infinite-bank.md`

Usar **solo minúsculas y guiones** en la descripción para consistencia con el resto del repo.

## Contenido mínimo (al cierre)

Cada archivo debe partir de [../templates/MERGE_LOG_TEMPLATE.md](../templates/MERGE_LOG_TEMPLATE.md). **Al abrir** la bitácora basta con metadatos iniciales, rama y objetivo; **antes de dar el ciclo por cerrado** debe quedar documentado al menos:

- SHAs de referencia (upstream y local antes/después).
- Tabla de conflictos y cómo se resolvieron.
- Resultado de `validate_customizations.sh` y de los tests ejecutados.

## Bitácoras de integración de producto (no upstream)

Para **features grandes del fork** (p. ej. Hyperlane) que **no** son un merge de [cosmos/evm](https://github.com/cosmos/evm), se puede archivar una bitácora de **cierre de fase** aquí con el mismo esquema de nombres (recomendado `YYYY-MM-DD-…`), **sin** usar la plantilla de merge upstream salvo que el equipo quiera homogeneizar.

- **Ejemplo:** [2026-04-03-hyperlane-integration.md](2026-04-03-hyperlane-integration.md) — código + upgrade + enlaces a documentación operativa ([OPERATIONS.md](../../feature/hyperlane/OPERATIONS.md)).
- **Ejemplo (feature en curso):** [2026-04-04-infinite-bank.md](2026-04-04-infinite-bank.md) — extensión del módulo Bank; documentación técnica en inglés: [INTEGRATION.md](../../feature/infinite-bank/INTEGRATION.md).

---

## Privacidad

No incluir secretos, tokens ni datos internos sensibles; solo referencias técnicas y de proceso.
