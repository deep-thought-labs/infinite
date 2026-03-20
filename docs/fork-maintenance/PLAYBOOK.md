# Playbook: merge con upstream

Procedimiento detallado para integrar cambios de [cosmos/evm](https://github.com/cosmos/evm) (u otro remoto configurado como upstream) en el fork Infinite Drive, minimizando regresiones y pérdida de personalización de identidad.

## Principios (no negociables)

1. **Identidad solo donde toca** — Token, chain IDs, bech32, nombre `infinited`, branding y archivos añadidos por el fork se conservan según [UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md).
2. **Prioridad upstream en lo técnico** — Lógica compartida, dependencias alineadas con upstream, rutas de import `github.com/cosmos/evm/...` sin sustituir por paths del fork.
3. **Decisiones explícitas en fork-only** — Archivos que upstream eliminó y nosotros mantenemos (p. ej. `ante/evm/10_gas_wanted.go`) no se resuelven “a ciegas”: se documenta en la bitácora.

## Prerrequisitos

- Remoto `upstream` apuntando al repo oficial y `git fetch upstream` reciente.
- Árbol de trabajo limpio (`git status`).
- Rama nueva para el trabajo de merge (no integrar directamente en `main` sin revisión si el equipo acuerda rama intermedia).

Comprobación rápida del remoto:

```bash
git remote -v
git fetch upstream
```

## Fase 0 — Preparación

| Paso | Acción |
|------|--------|
| 0.1 | Anotar **SHA** de `HEAD` local y de la rama upstream que vas a fusionar (p. ej. `upstream/main`). |
| 0.2 | Crear rama: `git switch -c merge/upstream-YYYY-MM-DD` (o nombre acordado). |
| 0.3 | **Línea base de divergencia** (recomendado): `./scripts/list_all_customizations.sh upstream/main > /tmp/diff-pre-merge.txt` — ver [REFERENCE.md](REFERENCE.md). |
| 0.4 | Si aplica un **salto de versión mayor**, abrir la guía en `docs/migrations/` correspondiente y tenerla a mano durante conflictos. |
| 0.5 | Copiar [templates/MERGE_LOG_TEMPLATE.md](templates/MERGE_LOG_TEMPLATE.md) a `docs/fork-maintenance/logs/` con nombre acordado (ver [logs/README.md](logs/README.md)) y rellenar ya metadatos y SHAs. |

## Fase 1 — Integración

| Paso | Acción |
|------|--------|
| 1.1 | `git merge upstream/main` (o la rama/tag acordado). Si preferís otra estrategia (merge vs rebase), que sea **decisión explícita del equipo**; con muchos renombres `evmd`→`infinited`, merge suele ser más trazable. |
| 1.2 | Si hay conflictos, **no** hacer `git checkout --theirs` masivo sobre paths de identidad o `infinited/` sin revisar. |

## Fase 2 — Resolución de conflictos

Orden sugerido (ajustar según el diff real):

1. **Módulos y dependencias** — `go.mod`, `go.sum`: alinear con upstream salvo lo documentado en [UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md); luego `go mod tidy`.
2. **Código compartido** (`x/`, `ante/`, etc.) — Preferir la versión upstream; re-aplicar manualmente solo lo imprescindible de identidad si el conflicto mezcla ambas.
3. **`infinited/`** — Mantener estructura y nombres del fork; incorporar cambios funcionales que upstream haya hecho en `evmd/` equivalente (comparar archivo a archivo).
4. **Archivos “solo fork”** — Scripts, guías, `docs/fork-maintenance/`: normalmente conservar la versión del fork; si upstream añadió algo equivalente, fusionar contenido.
5. **Casos especiales** — Revisar sección *Archivos añadidos* y *Otros* en [UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md).

Tras cada bloque grande de archivos resueltos, conviene compilar una vez para detectar errores tempranos:

```bash
make build
# o
make install
```

## Fase 3 — Verificación

Ejecutar en este orden (o CI equivalente). Detalle en [VERIFICATION.md](VERIFICATION.md).

| Orden | Comando / acción |
|-------|------------------|
| 1 | `./scripts/validate_customizations.sh` |
| 2 | `make build` o `make install` |
| 3 | Tests unitarios como mínimo: `make test-unit` |
| 4 | Si el merge es amplio: `make test-all` o el subconjunto que el equipo considere obligatorio |

## Fase 4 — Cierre

| Paso | Acción |
|------|--------|
| 4.1 | Actualizar [CHANGELOG.md](../../CHANGELOG.md) con entradas upstream pertinentes. |
| 4.2 | Completar la bitácora en `docs/fork-maintenance/logs/`. |
| 4.3 | Opcional: nuevo listado post-merge según [REFERENCE.md](REFERENCE.md). |
| 4.4 | PR de revisión con enlace a la bitácora en la descripción. |

## Si algo sale mal

- **Revertir el merge** antes de push compartido: `git merge --abort` (si aún no completaste el merge) o `git reset` según política del equipo.
- **Después de push**: revertir con commit de revert o fix forward; dejar constancia en la bitácora.

## Referencias rápidas

- [VERIFICATION.md](VERIFICATION.md)
- [REFERENCE.md](REFERENCE.md)
- [guides/development/DEVELOPMENT.md](../../guides/development/DEVELOPMENT.md)
