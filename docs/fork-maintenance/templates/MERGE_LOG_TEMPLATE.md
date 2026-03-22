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
| Sin marcadores `<<<<<<<` en el árbol (`grep -R '^<<<<<<<' . --exclude-dir=.git`) | | |
| `go mod tidy` (raíz y submódulos `go.mod` tocados) | | |
| Sin imports indebidos `github.com/cosmos/evm/evmd` / sin árbol `evmd/` residual | | |
| `./scripts/validate_customizations.sh` | | |
| `make build` / `make install` (probar si el path del clone tiene espacios) | | |
| `make test-unit` | | |
| `make test-infinited` | | Obligatorio en este fork: suite del submódulo `infinited` (`tests/ibc`, `tests/integration`). |
| `cd infinited && go test ./tests/integration/...` (opcional, focalizado si solo tocaste ante/feemarket/mempool) | | |
| Otros (p. ej. `make test-all`) | | |

## GitHub Actions (alineación con upstream)

*Rellenar si en este ciclo se sincronizó `.github/` con `upstream/main` (mismo PR de merge o PR dedicado). Política: [MERGE_STRATEGIES.md — §4](../MERGE_STRATEGIES.md#4-github-actions-alinear-con-upstream-en-el-plan-de-merge).*

| Campo | Valor |
|--------|--------|
| SHA `upstream/main` usado como fuente de workflows | |
| ¿`release.yml` conservado del fork sin cambios? (sí / no + notas) | |
| Jobs fork-only reaplicados (p. ej. fuzz, CodeQL) | |
| Ajustes `evmd` → `infinited` (workflows tocados) | |
| Secretos / jobs deshabilitados (si aplica) | |
| PR de solo-CI (enlace) | |

## Aprendizajes y puntos a recordar

*Opcional; ayuda al siguiente merge. Ver también [PLAYBOOK.md — Apéndice A.7](../PLAYBOOK.md#a7-tests-y-apis-tras-merge-upstream).*

- **Identidad en tests** (denom, bech32, orden de init de codec/config):
- **Contexto SDK** (p. ej. `BlockGasLimit` ↔ `ConsensusParams`, no mutar punteros compartidos al ajustar `MaxGas` en tests):
- **APIs rotas** (métodos de keeper o paquetes públicos eliminados/renombrados; tests bajo `infinited/tests/...`):
- **Otros** (paths, CI, scripts):

## Seguimiento post-merge

- [ ] CHANGELOG actualizado
- [ ] [UPSTREAM_DIVERGENCE_RECORD.md](../UPSTREAM_DIVERGENCE_RECORD.md) actualizado (solo si cambió el inventario o la política)
- [ ] Guía de migración consultada o actualizada (`docs/migrations/`)
- [ ] Alineación de `.github/workflows/` con `upstream/main` completada o planificada (ver [MERGE_STRATEGIES.md §4](../MERGE_STRATEGIES.md#4-github-actions-alinear-con-upstream-en-el-plan-de-merge)); `release.yml` del fork preservado salvo acuerdo explícito
- [ ] Jobs fork-only necesarios reaplicados (p. ej. fuzz, CodeQL)
- [ ] CI en PR verde (merge de código y, si aplica, PR de CI)

## Referencias

- PR(s): 
- Issues: 
