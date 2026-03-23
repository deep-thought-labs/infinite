# Mantenimiento del fork (Infinite Drive ↔ cosmos/evm)

Punto único en el repositorio para **divergencia frente a upstream**, **procedimiento de merge**, **diffs**, **verificación** y **bitácoras**. La raíz del proyecto permanece libre de estos documentos.

## Contenido de esta carpeta

| Documento | Descripción |
|-----------|-------------|
| [**UPSTREAM_DIVERGENCE_RECORD.md**](UPSTREAM_DIVERGENCE_RECORD.md) | Registro técnico de valores, rutas y artefactos que difieren de [cosmos/evm](https://github.com/cosmos/evm) en *este* repositorio. |
| [**PLAYBOOK.md**](PLAYBOOK.md) | Procedimiento de integración con upstream (antes, durante, después), incluye **Apéndice A** (marcadores de conflicto, `evmd`/`infinited`, Make con espacios, CI, **tests/APIs post-upstream** [A.7](PLAYBOOK.md#a7-tests-y-apis-tras-merge-upstream)). |
| [**MERGE_STRATEGIES.md**](MERGE_STRATEGIES.md) | Alternativas de integración, zonas protegidas, **§4 GitHub Actions** (alinear workflows con `upstream/main`, conservar `release.yml`, deltas `infinited`), **§4.6** [`.markdownlint.yml`](../../.markdownlint.yml) + [Makefile](../../Makefile) (`markdownlint_cli2_version`, `make lint-md` / `make lint`) y documentación por ciclo. |
| [**REFERENCE.md**](REFERENCE.md) | Uso de `list_all_customizations.sh`, informes de diff y notas sobre estadísticas esperadas. |
| [**VERIFICATION.md**](VERIFICATION.md) | Comprobaciones manuales y script `validate_customizations.sh`. |
| [**templates/MERGE_LOG_TEMPLATE.md**](templates/MERGE_LOG_TEMPLATE.md) | Plantilla para bitácoras de merge. |
| [**logs/**](logs/) | Bitácoras cerradas por integración. |
| [**../migrations/**](../migrations/) | Guías por salto de versión (fuera de esta carpeta, enlazadas desde el playbook). |

## Relación entre documentos

- **Registro de divergencia** = *qué* difiere y política de identidad vs upstream.
- **Playbook** = *cómo* ejecutar el merge de forma segura; **estrategias** = *qué enfoque* usar y qué no pisar ([MERGE_STRATEGIES.md](MERGE_STRATEGIES.md)).
- **Reference / Verification** = *cómo* medir y validar esas diferencias.
- **logs/** = *qué ocurrió* en cada merge concreto.

## Flujo resumido

1. Leer [PLAYBOOK.md](PLAYBOOK.md) (preparación) y [UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md) (archivos sensibles).
2. Opcional: línea base con `./scripts/list_all_customizations.sh` (ver [REFERENCE.md](REFERENCE.md)).
3. Merge desde `upstream/...`; resolver conflictos según playbook y registro.
4. Verificar con [VERIFICATION.md](VERIFICATION.md) y tests ([Fase 3](PLAYBOOK.md#fase-3--verificación)).
5. **CI:** alinear `.github/workflows/` con `upstream/main` según [MERGE_STRATEGIES.md §4](MERGE_STRATEGIES.md#4-github-actions-alinear-con-upstream-en-el-plan-de-merge) y [PLAYBOOK — Fase 3b](PLAYBOOK.md#fase-3b--alineación-de-github-actions-con-upstream) (mismo PR o PR dedicado; conservar `release.yml`).
6. Archivar bitácora en `logs/` usando la plantilla (incl. sección **GitHub Actions** si hubo alineación).

## Scripts (permanecen en `scripts/`)

- `scripts/list_all_customizations.sh` — inventario de diff frente a una ref.
- `scripts/validate_customizations.sh` — comprobaciones automatizadas de identidad y compliance.
