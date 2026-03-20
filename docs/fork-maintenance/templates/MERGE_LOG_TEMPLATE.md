# Bitácora de merge upstream — PLANTILLA

> Copiar este archivo a `../logs/` y renombrar según [logs/README.md](../logs/README.md).  
> Eliminar bloques de ayuda comentados al cerrar la bitácora.

## Metadatos

| Campo | Valor |
|--------|--------|
| Fecha inicio | YYYY-MM-DD |
| Fecha cierre | YYYY-MM-DD |
| Responsable(s) | |
| Rama local de trabajo | p. ej. `merge/upstream-2026-03-19` |
| Rama/ref upstream fusionada | p. ej. `upstream/main` |
| SHA upstream (antes del merge) | |
| SHA local (antes del merge) | |
| SHA merge resultante (tras cerrar) | |

## Objetivo

Breve descripción (p. ej. “Sincronizar con cosmos/evm main hasta PR #NNN”, “Preparar v0.x”).

## Línea base (opcional)

- Ruta o adjunto del output de `./scripts/list_all_customizations.sh upstream/main` antes del merge:  
  `___________________________`

## Conflictos resueltos

| Archivo | Tipo (theirs/ours/manual) | Resumen de la decisión | Riesgo / notas |
|---------|---------------------------|-------------------------|----------------|
| | | | |
| | | | |

*(Añadir filas según sea necesario.)*

## Decisiones de fork (no triviales)

- Ej.: mantener `ante/evm/10_gas_wanted.go`, cambios en `infinited/app.go` frente a `evmd`, renombres, etc.

## Verificación

| Check | Resultado (OK / falló) | Notas |
|-------|------------------------|-------|
| `./scripts/validate_customizations.sh` | | |
| `make build` / `make install` | | |
| `make test-unit` | | |
| Otros (p. ej. `make test-all`) | | |

## Seguimiento post-merge

- [ ] CHANGELOG actualizado
- [ ] [UPSTREAM_DIVERGENCE_RECORD.md](../UPSTREAM_DIVERGENCE_RECORD.md) actualizado (solo si cambió el inventario o la política)
- [ ] Guía de migración consultada o actualizada (`docs/migrations/`)
- [ ] CI en PR verde

## Referencias

- PR(s): 
- Issues: 
