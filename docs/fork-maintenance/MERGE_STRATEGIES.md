# Estrategias de integración upstream (alternativas y protección del fork)

Este documento complementa [PLAYBOOK.md](PLAYBOOK.md) y [UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md). Resume **cómo** integrar cambios de [cosmos/evm](https://github.com/cosmos/evm) sin perder lo propio del fork (identidad, `infinited/`, release y CI), y **qué** documentar en cada ciclo.

## 1. Zonas protegidas (no resolver “a ciegas” con upstream)

Antes de elegir estrategia, conviene tener claro qué el merge **no debe destruir**. Alineado con la política del [registro de divergencia](UPSTREAM_DIVERGENCE_RECORD.md):

| Área | Qué proteger | Dónde queda reflejado |
|------|----------------|----------------------|
| Identidad | Denoms, chain IDs, bech32, genesis y tests que los fijan | `UPSTREAM_DIVERGENCE_RECORD.md`, bitácora |
| Binario y módulo | Árbol `infinited/`, imports `github.com/cosmos/evm/infinited`, sin `evmd/` residual no acordado | Mismo + conflictos en bitácora |
| Release y despliegue | `.goreleaser.yml`, `release.yml`, `docs/guides/` de build, secretos y tokens de CI del org | Bitácora + sección “Decisiones de fork” |
| CI propio | Jobs que el fork debe conservar (p. ej. fuzz, CodeQL, runners alternativos) | Bitácora + [PLAYBOOK — A.5](PLAYBOOK.md#a5-ci-y-jobs-preservados-del-fork) |
| Documentación de proceso | `docs/fork-maintenance/`, plantillas, bitácoras | Siempre versión del fork; fusionar contenido si upstream añade equivalente |
| Extensiones de producto | Funcionalidad fuera del `evmd` de ejemplo upstream (p. ej. Hyperlane en `infinited`) | [UPSTREAM_DIVERGENCE_RECORD.md — Extensiones de producto (fork)](UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork), [INTEGRATION.md](../feature/hyperlane/INTEGRATION.md), [OPERATIONS.md](../feature/hyperlane/OPERATIONS.md), [bitácora Hyperlane](logs/2026-04-03-hyperlane-integration.md) |

**Regla práctica:** `git checkout --theirs` masivo sobre `infinited/`, `scripts/**`, `docs/fork-maintenance/**` o archivos listados en el registro de divergencia está **prohibido** sin revisión explícita.

## 2. Alternativas de integración (ventajas y cuándo usarlas)

Todas suponen `git fetch upstream` y una rama de trabajo dedicada (p. ej. `merge/upstream-YYYY-MM-DD`), no merge directo a `main` sin revisión si el equipo acuerda rama intermedia.

### A. Merge de integración (`git merge upstream/main`)

- **Qué es:** Un commit de merge que trae **todo** el historial de upstream hasta el SHA elegido.
- **Ventajas:** Historial fiel; conflictos en un solo (o pocos) puntos; muy trazable en `git log`; encaja con renombres `evmd` → `infinited`.
- **Inconvenientes:** El árbol puede quedar “ruidoso” en el historial; los conflictos pueden ser grandes de golpe.
- **Recomendación:** **Estrategia por defecto** para este fork (ya reflejada en el playbook).

### B. Rebase interactivo o rebase de la rama de trabajo sobre `upstream/main`

- **Qué es:** Reaplicar commits propios encima de una rama upstream actualizada.
- **Ventajas:** Historial lineal en la rama de feature; útil si hay **pocos** commits propios y claros.
- **Inconvenientes:** Con mucho historial divergente o muchos merges ya hechos, **reescribe historia** y complica colaboración; conflictos repetidos; alto riesgo si la rama ya se publicó y otros la usan.
- **Recomendación:** Solo para ramas **locales o cortas**, no como sustituto estándar del merge de `main` del fork.

### C. Integración por etapas (rangos o temas)

- **Qué es:** Traer upstream en **varios** merges o cherry-picks (p. ej. por área: `ante/`, IBC, RPC), o fusionar primero un tag intermedio y luego `main`.
- **Ventajas:** Reduce el tamaño de cada resolución; permite revisar y documentar por bloque.
- **Inconvenientes:** Más tiempo; riesgo de estados intermedios inconsistentes si no se compila y prueba tras cada etapa.
- **Recomendación:** Cuando salte una **versión mayor** o el diff sea enorme; cada etapa debe cerrar con build + tests mínimos y una **entrada en la bitácora** (o subsección).

### D. Rama larga de integración + sincronización con `main` del fork

- **Qué es:** Mantener `merge/upstream-…` viva mientras se estabiliza; periódicamente `git merge origin/main` (o rebase de la rama de trabajo sobre el `main` del fork) para no divergir demasiado del día a día del equipo.
- **Ventajas:** El equipo sigue en paralelo; menos sorpresas al abrir el PR final.
- **Inconvenientes:** Requiere disciplina de integración frecuente; conflictos pueden fusionarse dos veces (fork vs upstream y fork interno).
- **Recomendación:** Integraciones largas o multi‑PR.

## 3. Compatibilidad: qué adaptar tras traer upstream

No basta con “aceptar” el merge: lo que upstream asume para `evmd` o su CI debe **reaplicarse** al contexto de Infinite Drive.

| Tipo de cambio upstream | Adaptación típica en el fork |
|-------------------------|------------------------------|
| Cambios bajo `evmd/` en upstream | Portar a `infinited/` (comparar archivo a archivo o con `git`/`diff` guiado). |
| `go.mod` / dependencias | Alinear con upstream; conservar solo excepciones documentadas en el registro de divergencia. |
| Workflows `.github/workflows/**` | Fusionar YAML: conservar jobs propios (release, fuzz, CodeQL); traer mejoras upstream; **reemplazar rutas `evmd` por `infinited`** donde el repo no tenga `evmd/`. |
| Tests que asumen HRP/denom “cosmos” | Ajustar a identidad del fork (ver [PLAYBOOK — A.7](PLAYBOOK.md#a7-tests-y-apis-tras-merge-upstream)). |
| Nuevas APIs en keepers | Actualizar tests bajo `infinited/tests/...` y ejecutar `make test-infinited`. |

Lista de verificación rápida: [VERIFICATION.md](VERIFICATION.md), `make build`, `make test-unit`, `make test-infinited`, y la tabla de la Fase 3 del playbook.

## 4. GitHub Actions: alinear con upstream en el plan de merge

**Objetivo:** que `.github/workflows/` (y archivos relacionados bajo `.github/`, p. ej. `labeler.yml`) reflejen **la misma lógica y estructura que `upstream/main` en el momento elegido**, con **ajustes mínimos** para que el fork sea funcional, y sin romper el **flujo de release** propio.

### 4.1 Invariantes del fork (no sobrescribir con upstream)

| Artefacto | Motivo |
|-----------|--------|
| `.github/workflows/release.yml` | Pipeline de release del proyecto (GoReleaser, tags, permisos). **Mantener la versión del fork** salvo revisión explícita conjunta con [`.goreleaser.yml`](../../.goreleaser.yml). |
| `.goreleaser.yml` | Define binarios `infinited` y metadatos de Infinite Drive. No sustituir por el de upstream (orientado a `evmd`). |

### 4.2 Qué tomar de upstream

- **Todo el resto** de workflows en `.github/workflows/` del snapshot de **`upstream/main`** (o del SHA acordado en la bitácora), salvo que el equipo decida desactivar explícitamente un job (p. ej. dispatch a repos de Cosmos sin secretos).
- Incluye mejoras de **versiones de acciones**, **runners**, workflows añadidos allí (p. ej. revisión de dependencias, `stale`, etc.).

### 4.3 Deltas obligatorios en el fork (tras copiar/fusionar YAML)

| Tema | Acción |
|------|--------|
| Rutas `evmd/` | Sustituir por **`infinited/`** donde el repo no tenga `evmd` (build, `paths`, `get-diff`, pasos que hagan `cd evmd`). |
| Nombre del binario en pasos descriptivos | Alinear con **`make build` / `make install`** del `Makefile` del fork (`infinited`). |
| Jobs que upstream no tiene y el fork sí quiere | **Reaplicar** encima del snapshot: p. ej. `test-fuzz` en `test.yml`, **CodeQL** si se mantiene política de escaneo en PR. |
| Secretos (`BUF_TOKEN`, `DOCS_REPO_TOKEN`, Codecov, etc.) | Comprobar en ajustes del repo GitHub; jobs sin secreto pueden fallar o deben deshabilitarse con criterio documentado en la bitácora. |
| Integraciones **solo upstream** (`trigger-docs-update.yml`, `bsr-push.yml`) | En este fork quedan **conservadas pero inactivas**: solo `workflow_dispatch` y `if: false` en el job hasta que haya token y política clara; instrucciones de reactivación en cabecera de cada YAML. |
| Runners **`depot-ubuntu-*`** (upstream) | [Depot](https://depot.dev) es un servicio aparte. Si la **org del fork no** tiene Depot contratado e integrado en GitHub, los jobs **no encontrarán runner** → sustituir por **`ubuntu-latest`** (o el hosted estándar acordado) en los YAML afectados. Si más adelante se contrata Depot, se puede volver a alinear con upstream. |

### 4.4 Cómo incorporarlo al proceso (mismo ciclo o PR dedicado)

- **Opción A — Mismo PR que el merge de código:** útil si el equipo quiere un solo cierre; el diff de YAML puede ser grande.
- **Opción B — PR dedicado inmediatamente después** (recomendado si el merge de código ya está cerrado): título claro, p. ej. `ci: align workflows with upstream/main @ <SHA>`, enlace a la bitácora de merge.

Comando típico para inspeccionar un fichero upstream sin checkout:

```bash
git fetch upstream
git show upstream/main:.github/workflows/test.yml | head
```

### 4.5 Checklist antes de dar por buena la alineación

- [ ] Anotado en bitácora el **SHA de `upstream/main`** usado como fuente de workflows.
- [ ] `release.yml` y `.goreleaser.yml` del fork **intactos** o cambiados solo con acuerdo explícito.
- [ ] Sin referencias rotas a `evmd/` donde el árbol sea solo `infinited/`.
- [ ] Reaplicados jobs **fork-only** acordados (fuzz, CodeQL, etc.).
- [ ] **Runners:** confirmado si se usan labels `depot-ubuntu-*` o **`ubuntu-latest`** según contratación real (ver §4.3).
- [ ] PR de CI **verde** o fallos documentados como aceptados temporalmente.
- [ ] [`.markdownlint.yml`](../../.markdownlint.yml) del fork: **MD013** con `code_block_line_length: 200` (ver [§4.6](#46-markdownlint)).
- [ ] [Makefile](../../Makefile): **`markdownlint_cli2_version`** coherente con **`markdownlint-cli2-action@v16`** en [lint.yml](../../.github/workflows/lint.yml); si bump de la acción, bump de la variable (ver [§4.6](#46-markdownlint)).

Procedimiento en el playbook: [Fase 3b](PLAYBOOK.md#fase-3b--alineación-de-github-actions-con-upstream).

### 4.6 Markdownlint

El lint de Markdown en CI usa [`.markdownlint.yml`](../../.markdownlint.yml) en la **raíz del repositorio** (no solo `.github/`).

**Política de este fork:** regla **MD013** — el texto corrido puede usar `line_length` alto; en **bloques de código** (`code_blocks: true`) se aplica **`code_block_line_length: 200`** para admitir ejemplos shell, `curl` y tuberías largas sin forzar reformateos innecesarios, y aun así detectar líneas claramente anómalas.

**Tras integrar upstream:** si el merge trae un `.markdownlint.yml` distinto, **no** sustituir ciegamente el del fork: fusionar y **conservar** `code_block_line_length: 200` salvo decisión explícita del equipo (anótala en la bitácora). Si upstream no tiene el archivo, mantener el del fork.

**Makefile (paridad local ↔ CI):** en la raíz, el [Makefile](../../Makefile) declara **`markdownlint_cli2_version`** (p. ej. `0.13.0`), alineada con la dependencia **`markdownlint-cli2`** empaquetada en **`DavidAnson/markdownlint-cli2-action@v16`** usada en [`.github/workflows/lint.yml`](../../.github/workflows/lint.yml). **`make lint-md`** ejecuta esa versión vía `npx`; **`make lint`** incluye **`lint-md`** (requiere **Node.js** con `npx`). Las exclusiones de Markdown **vendidos** (Foundry/OpenZeppelin bajo pruebas de compatibilidad) están en [`.markdownlint-cli2.jsonc`](../../.markdownlint-cli2.jsonc) (`ignores`) y se reflejan en [`.markdownlintignore`](../../.markdownlintignore); así CI y `make lint-md` omiten esos árboles sin duplicar globs en el `Makefile`.

**Tras subir la acción** `markdownlint-cli2-action` a otra etiqueta mayor: revisar el `package.json` de esa etiqueta y **actualizar `markdownlint_cli2_version` en el Makefile** en el mismo PR o de inmediato después, para no divergir de CI.

## 5. Documentación obligatoria por merge (proceso único)

Cada integración debe dejar **trazabilidad** en tres capas:

1. **Bitácora** (`docs/fork-maintenance/logs/`, plantilla [MERGE_LOG_TEMPLATE.md](templates/MERGE_LOG_TEMPLATE.md)): conflictos, decisiones no triviales, verificación (incluido `make test-infinited`), **sección GitHub Actions** si hubo alineación de CI, SHAs y referencias a PR.
2. **[UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md):** actualizar solo si cambia inventario, política o lista de archivos sensibles (no duplicar el relato del merge).
3. **Este documento:** no hace falta editarlo en cada merge salvo que el equipo **adopte una nueva estrategia** (p. ej. pasar a integración por etapas) o quiera añadir una advertencia aprendida.

Opcional pero útil: una línea en [CHANGELOG.md](../../CHANGELOG.md) si el merge introduce cambios relevantes para operadores o nodos.

## 6. Resumen

| Prioridad | Estrategia |
|-----------|------------|
| Por defecto | **Merge** `upstream/main` en rama dedicada, resolver con prioridad técnica upstream y protección explícita de identidad y `infinited/`. |
| Saltos grandes o merges muy conflictivos | **Por etapas** + bitácora por bloque. |
| Rama larga de integración | **Merge frecuente** con `main` del fork en la rama de trabajo. |
| Evitar | Rebase masivo de historia publicada; `theirs` sobre zonas protegidas sin revisión. |

Para el procedimiento paso a paso, seguir siempre [PLAYBOOK.md](PLAYBOOK.md) (incluye **Fase 3b** para CI).
