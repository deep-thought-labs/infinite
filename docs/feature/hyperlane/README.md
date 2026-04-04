# Hyperlane — integración en Infinite Drive

**Estado:** implementación base en `infinited` (rama de trabajo típica: `feature/hyperlane`).

Este directorio concentra la **documentación de la integración** con [Hyperlane](https://hyperlane.xyz/) en la cadena Infinite Improbability Drive.

## Documentos en esta carpeta

| Documento | Contenido |
|-----------|-----------|
| [**INTEGRATION.md**](INTEGRATION.md) | **Registro canónico y documento de auditoría:** contexto del proyecto, resumen de la **guía original** frente a la **implementación real**, matriz paso a paso, inventario de código, checklist para revisores (humanos o IA) y decisiones justificadas. |
| *(futuro)* | Operación de relayers, génesis de red, diseño IBC/mensajería según avance del producto. |

Resumen ejecutivo: dependencia **`hyperlane-cosmos@v1.2.0-rc.0`** en [`infinited/go.mod`](../../../infinited/go.mod); cableado en [`infinited/app.go`](../../../infinited/app.go) y permisos en [`infinited/config/permissions.go`](../../../infinited/config/permissions.go). Detalle y justificación → **[INTEGRATION.md](INTEGRATION.md)**.

**Registro en mantenimiento del fork:** [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto (fork)](../../fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork).

## Trazabilidad

- **Changelog (pista Infinite):** entrada bajo `FEATURES` en [`CHANGELOG.md`](../../../CHANGELOG.md) (sección UNRELEASED hasta publicar versión).

## Referencias cruzadas

- Mantenimiento frente a upstream: [`docs/fork-maintenance/`](../../fork-maintenance/README.md)
- Tests e integración del binario: [`docs/guides/development/TESTING.md`](../../guides/development/TESTING.md)
