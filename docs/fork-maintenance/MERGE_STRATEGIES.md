# Estrategias de integración upstream (alternativas y protección del fork)

Este documento complementa [PLAYBOOK.md](PLAYBOOK.md) y [UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md). Resume **cómo** integrar cambios de [cosmos/evm](https://github.com/cosmos/evm) sin perder lo propio del fork (identidad, `infinited/`, release y CI), y **qué** documentar en cada ciclo.

## 1. Zonas protegidas (no resolver “a ciegas” con upstream)

Antes de elegir estrategia, conviene tener claro qué el merge **no debe destruir**. Alineado con la política del [registro de divergencia](UPSTREAM_DIVERGENCE_RECORD.md):

| Área | Qué proteger | Dónde queda reflejado |
|------|----------------|----------------------|
| Identidad | Denoms, chain IDs, bech32, genesis y tests que los fijan | `UPSTREAM_DIVERGENCE_RECORD.md`, bitácora |
| Binario y módulo | Árbol `infinited/`, imports `github.com/cosmos/evm/infinited`, sin `evmd/` residual no acordado | Mismo + conflictos en bitácora |
| Release y despliegue | `.goreleaser.yml`, `release.yml`, `guides/` de build, secretos y tokens de CI del org | Bitácora + sección “Decisiones de fork” |
| CI propio | Jobs que el fork debe conservar (p. ej. fuzz, CodeQL, runners alternativos) | Bitácora + [PLAYBOOK — A.5](PLAYBOOK.md#a5-ci-y-jobs-preservados-del-fork) |
| Documentación de proceso | `docs/fork-maintenance/`, plantillas, bitácoras | Siempre versión del fork; fusionar contenido si upstream añade equivalente |

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

## 4. Documentación obligatoria por merge (proceso único)

Cada integración debe dejar **trazabilidad** en tres capas:

1. **Bitácora** (`docs/fork-maintenance/logs/`, plantilla [MERGE_LOG_TEMPLATE.md](templates/MERGE_LOG_TEMPLATE.md)): conflictos, decisiones no triviales, verificación (incluido `make test-infinited`), SHAs y referencias a PR.
2. **[UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md):** actualizar solo si cambia inventario, política o lista de archivos sensibles (no duplicar el relato del merge).
3. **Este documento:** no hace falta editarlo en cada merge salvo que el equipo **adopte una nueva estrategia** (p. ej. pasar a integración por etapas) o quiera añadir una advertencia aprendida.

Opcional pero útil: una línea en [CHANGELOG.md](../../CHANGELOG.md) si el merge introduce cambios relevantes para operadores o nodos.

## 5. Resumen

| Prioridad | Estrategia |
|-----------|------------|
| Por defecto | **Merge** `upstream/main` en rama dedicada, resolver con prioridad técnica upstream y protección explícita de identidad y `infinited/`. |
| Saltos grandes o merges muy conflictivos | **Por etapas** + bitácora por bloque. |
| Rama larga de integración | **Merge frecuente** con `main` del fork en la rama de trabajo. |
| Evitar | Rebase masivo de historia publicada; `theirs` sobre zonas protegidas sin revisión. |

Para el procedimiento paso a paso, seguir siempre [PLAYBOOK.md](PLAYBOOK.md).
