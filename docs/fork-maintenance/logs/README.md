# Bitácoras de merge upstream

Aquí van las **bitácoras cerradas** de cada integración con upstream: conflictos, decisiones y resultados de verificación.

## Convención de nombres

`YYYY-MM-descripcion-corta.md`

Ejemplos:

- `2026-03-merge-upstream-main.md`
- `2026-04-sync-cosmos-evm-v056.md`

Usar **solo minúsculas y guiones** en la descripción para consistencia con el resto del repo.

## Contenido mínimo

Cada archivo debe partir de [../templates/MERGE_LOG_TEMPLATE.md](../templates/MERGE_LOG_TEMPLATE.md) y conservar al menos:

- SHAs de referencia (upstream y local antes/después).
- Tabla de conflictos y cómo se resolvieron.
- Resultado de `validate_customizations.sh` y de los tests ejecutados.

## Privacidad

No incluir secretos, tokens ni datos internos sensibles; solo referencias técnicas y de proceso.
