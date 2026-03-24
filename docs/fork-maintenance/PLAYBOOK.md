# Playbook: merge con upstream

Procedimiento detallado para integrar cambios de [cosmos/evm](https://github.com/cosmos/evm) (u otro remoto configurado como upstream) en el fork Infinite Drive, minimizando regresiones y pérdida de personalización de identidad.

## Principios (no negociables)

1. **Identidad solo donde toca** — Token, chain IDs, bech32, nombre `infinited`, branding y archivos añadidos por el fork se conservan según [UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md).
2. **Prioridad upstream en lo técnico** — Lógica compartida, dependencias alineadas con upstream, rutas de import `github.com/cosmos/evm/...` sin sustituir por paths del fork.
3. **Decisiones explícitas en fork-only** — Archivos que upstream eliminó y nosotros mantenemos (p. ej. `ante/evm/10_gas_wanted.go`) no se resuelven “a ciegas”: se documenta en la bitácora.
4. **CI como extensión del merge** — La alineación de **GitHub Actions** con `upstream/main` forma parte del plan de integración (mismo PR o PR dedicado), conservando **release** y aplicando deltas `infinited` — ver [MERGE_STRATEGIES.md — §4](MERGE_STRATEGIES.md#4-github-actions-alinear-con-upstream-en-el-plan-de-merge) y [Fase 3b](#fase-3b--alineación-de-github-actions-con-upstream).

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
| 0.6 | **CI (planificación):** decidir si la alineación de `.github/workflows/` con `upstream/main` ocurre **en este mismo ciclo** o en un **PR inmediatamente posterior**; anotarlo en la bitácora. Política detallada: [MERGE_STRATEGIES.md — §4](MERGE_STRATEGIES.md#4-github-actions-alinear-con-upstream-en-el-plan-de-merge). |

## Fase 1 — Integración

Alternativas (merge por defecto, etapas, ramas largas, qué zonas no pisar): [MERGE_STRATEGIES.md](MERGE_STRATEGIES.md).

| Paso | Acción |
|------|--------|
| 1.1 | `git merge upstream/main` (o la rama/tag acordado). Si preferís otra estrategia (merge vs rebase), que sea **decisión explícita del equipo**; con muchos renombres `evmd`→`infinited`, merge suele ser más trazable. |
| 1.2 | Si hay conflictos, **no** hacer `git checkout --theirs` masivo sobre paths de identidad o `infinited/` sin revisar. |
| 1.3 | **Antes de `git commit`** del merge (o del primer commit que cierre la integración): comprobar que **no queden marcadores de conflicto** en el árbol (ver [Apéndice A](#apéndice-a-cierre-del-merge-y-trampas-frecuentes)). Un merge “cerrado” con `<<<<<<<` en el repo es un incidente evitable. |

## Fase 2 — Resolución de conflictos

Orden sugerido (ajustar según el diff real):

1. **Módulos y dependencias** — `go.mod`, `go.sum`: alinear con upstream salvo lo documentado en [UPSTREAM_DIVERGENCE_RECORD.md](UPSTREAM_DIVERGENCE_RECORD.md); luego **`go mod tidy`** y revisar que no convivan imports **`github.com/cosmos/evm/evmd`** (módulo upstream del binario) con el árbol local **`infinited/`** (ver [Apéndice A](#apéndice-a-cierre-del-merge-y-trampas-frecuentes)).
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

Ejecutar en este orden (o CI equivalente). Detalle en [VERIFICATION.md](VERIFICATION.md). Incluir al menos la comprobación de marcadores de conflicto del apéndice si el merge fue voluminoso o hubo resolución manual masiva.

| Orden | Comando / acción |
|-------|------------------|
| 1 | `./scripts/validate_customizations.sh` |
| 2 | `make build` o `make install` |
| 3 | Tests unitarios como mínimo: `make test-unit` |
| 4 | **`make test-infinited`** — suite del binario `infinited` (IBC + integración bajo `infinited/tests/`); obligatoria en este fork. |
| 5 | Si el merge es amplio: `make test-all` o el subconjunto que el equipo considere obligatorio |

### Matriz de regresión por área (referencia rápida)

Usar como guía cuando sepas qué directorios tocaste; no sustituye la batería completa de la Fase 3.

| Área / riesgo | Comando o comprobación sugerida |
|---------------|----------------------------------|
| Identidad (denom `drop`, bech32 `infinite`, chain IDs) | `./scripts/validate_customizations.sh` + [VERIFICATION.md](VERIFICATION.md) (greps de identidad) |
| Módulo binario `infinited` vs restos `evmd` | `grep` de imports `github.com/cosmos/evm/evmd` y ausencia de árbol `evmd/` residual (ver [Apéndice A](#apéndice-a-cierre-del-merge-y-trampas-frecuentes), sección **A.2**) |
| `Makefile` / rutas con espacios | `make build` en el mismo path de trabajo que usará el equipo |
| Ante / feemarket / mempool / EIP-712 | `cd infinited && go test ./tests/integration/...` (o subpaquete concreto si el cambio es local) |
| IBC (helpers `testutil/ibc`, tests bajo `infinited/tests/ibc`) | `make test-infinited` o `cd infinited && go test -tags=test ./tests/ibc/...` |
| Integración amplia `infinited` | `make test-infinited` |
| Cobertura máxima antes de release | `make test-all` (si el tiempo lo permite) |

## Fase 3b — Alineación de GitHub Actions con upstream

Objetivo: que la **estructura lógica** de los workflows coincida con **`upstream/main`** en el SHA acordado, con **ajustes mínimos** para `infinited/` y el entorno del fork, y **sin reemplazar** el flujo de release propio.

| Paso | Acción |
|------|--------|
| 3b.1 | `git fetch upstream`. Tomar como referencia el **SHA** de `upstream/main` que documentarás en la bitácora (misma integración de código o la más reciente si el PR de CI es posterior). |
| 3b.2 | Sustituir o fusionar ficheros bajo `.github/workflows/` con los de upstream **excepto** [`.github/workflows/release.yml`](../../.github/workflows/release.yml) (versión del fork). Revisar también [`.github/labeler.yml`](../../.github/labeler.yml) u otros si upstream los cambió. |
| 3b.3 | Aplicar **deltas del fork**: rutas `evmd` → `infinited`, pasos que llamen al binario correcto, reaplicar jobs acordados (p. ej. **fuzz** en `test.yml`, **CodeQL** si aplica). Revisar **`runs-on`**: sin Depot, usar **`ubuntu-latest`** (ver [MERGE_STRATEGIES §4.3](MERGE_STRATEGIES.md#43-deltas-obligatorios-en-el-fork-tras-copiarfusionar-yaml)). |
| 3b.4 | Revisar **secretos** del repositorio (Codecov, Buf, docs dispatch, etc.): o bien configurados, o jobs deshabilitados/documentados en la bitácora. |
| 3b.5 | Abrir o actualizar **PR** y comprobar que la **CI en GitHub** refleja los mismos gates que el equipo espera; completar la sección **GitHub Actions** de la bitácora. |
| 3b.6 | Si el merge tocó la raíz del repo o añadió/cambió [`.markdownlint.yml`](../../.markdownlint.yml) / [Makefile](../../Makefile) upstream: conservar **MD013** `code_block_line_length: 200` y **`markdownlint_cli2_version`** alineada con **`markdownlint-cli2-action@v16`** en [lint.yml](../../.github/workflows/lint.yml) (política del fork). Detalle: [MERGE_STRATEGIES.md — §4.6](MERGE_STRATEGIES.md#46-markdownlint). |

Checklist extendida: [MERGE_STRATEGIES.md — §4.5 y §4.6](MERGE_STRATEGIES.md#45-checklist-antes-de-dar-por-buena-la-alineación).

## Fase 4 — Cierre

| Paso | Acción |
|------|--------|
| 4.1 | Actualizar [CHANGELOG.md](../../CHANGELOG.md) con entradas upstream pertinentes. |
| 4.2 | Completar la bitácora en `docs/fork-maintenance/logs/` (incl. CI si aplica). |
| 4.3 | Opcional: nuevo listado post-merge según [REFERENCE.md](REFERENCE.md). |
| 4.4 | PR de revisión con enlace a la bitácora en la descripción. |
| 4.5 | Si la alineación de CI fue **PR aparte**: enlazar ese PR en la bitácora del merge de código o en una nota de seguimiento; cerrar ambos antes de considerar el ciclo completo. |

## Si algo sale mal

- **Revertir el merge** antes de push compartido: `git merge --abort` (si aún no completaste el merge) o `git reset` según política del equipo.
- **Después de push**: revertir con commit de revert o fix forward; dejar constancia en la bitácora.

## Apéndice A — Cierre del merge y trampas frecuentes

Lecciones de integraciones reales (p. ej. merge con dejar conflictos sin limpiar, o convivencia errónea de módulos `evmd` / `infinited`).

### A.1 Marcadores de conflicto en el árbol

Antes de considerar el merge cerrado y **obligatorio antes de push**:

```bash
# Debe no devolver coincidencias en checkout limpio tras resolución
grep -R -n '^<<<<<<<' . --exclude-dir=.git || echo "OK: sin marcadores"
```

Incluir también `=======` y `>>>>>>>` si se usaron herramientas que dejaron solo parte del marcador (raro pero posible). En CI/review, cualquier `<<<<<<<` en diff es señal de alarma.

### A.2 Solo `infinited` como módulo del binario en este fork

- El path de módulo del binario en este repo es **`github.com/cosmos/evm/infinited`**, no `.../evmd`.
- **No** debe existir un árbol paralelo **`evmd/`** en la raíz del módulo salvo que upstream lo traiga de forma explícita y acordada: en forks renombrados, solemos **eliminar restos** de `evmd/` y usar solo `infinited/`.
- Los imports en código del fork deben apuntar a **`github.com/cosmos/evm/infinited`** (y subpaquetes) donde corresponda al binario y tests de integración bajo ese árbol. Mantener imports **`github.com/cosmos/evm/evmd`** junto con `replace` local hacia `./infinited` provoca ambigüedad con el módulo remoto homónimo y fallos de `go mod tidy` / compilación.
- Revisar módulos anidados: p. ej. si **`tests/speedtest/go.mod`** usa `replace` a `infinited`, la ruta relativa debe seguir coincidiendo tras movimientos de carpetas.

### A.3 Makefile y rutas con espacios

Si el clone vive bajo un directorio con espacios en el nombre, las reglas de `make` que usen `mkdir`, `cd`, `-o` o `cp` con `BUILDDIR` / rutas al binario deben ir **entrecomilladas** en la receta shell. Tras un merge que sobrescriba el `Makefile`, volver a probar **`make build`** en esa ruta. Mitigación alternativa: clonar el repo en una ruta sin espacios.

### A.4 Binario nombre `evmd` y tag legacy en pruebas de sistema

Algunos scripts de **system test** / `test-system` pueden esperar el binario con nombre **`evmd`** aunque el proyecto use **`infinited`** como nombre lógico. Tras resolver conflictos en playbooks o scripts de test, verificar que la copia o el symlink al ejecutable coincida con lo que documenta la guía de tests del momento (p. ej. ruta `tests/systemtests/binaries/v0.5/evmd` para el baseline).

El `Makefile` define **`SYSTEMTEST_LEGACY_TAG`**: commit etiquetado desde el que se construye ese binario “viejo” para el escenario de upgrade on-chain. **En el fork Infinite Drive** el valor por defecto apunta al **último release del propio repositorio** (p. ej. **`v0.1.10`**), no al tag que documente cosmos/evm (`v0.5.1`, etc.), que puede **no existir** en el fork. El tag debe estar **creado y empujado** en este repo; no se debe asumir un fetch automático desde upstream. Detalle y tabla de verificación: bitácora [2026-03-merge-upstream-main.md](logs/2026-03-merge-upstream-main.md#system-tests-y-upgrades-on-chain-fork).

Cuando los artefactos del baseline sean Linux-only, `build-v05` puede descargarlos del release del fork (`SYSTEMTEST_LEGACY_REPO`) y verificar `checksums.txt` antes de copiarlos a `tests/systemtests/binaries/v0.5/evmd`. Para hosts macOS, usar `make test-system-docker` (ejecución Linux en contenedor) reduce diferencias con CI y evita incompatibilidades de toolchain en tags legacy.

### A.5 CI y jobs preservados del fork

Si upstream simplifica **`.github/workflows`**, revisar jobs que el fork **debe conservar** (p. ej. **`test-fuzz`** u otros acordados) y fusionar YAML en lugar de sustituir ciegamente por la versión upstream.

Política completa (snapshot upstream + `release.yml` + deltas `infinited`): [MERGE_STRATEGIES.md — §4](MERGE_STRATEGIES.md#4-github-actions-alinear-con-upstream-en-el-plan-de-merge) y [Fase 3b](#fase-3b--alineación-de-github-actions-con-upstream).

**Runners:** upstream puede usar **`depot-ubuntu-*`**; en el fork, sin Depot contratado, usar **`ubuntu-latest`** (detalle en [MERGE_STRATEGIES — §4.3](MERGE_STRATEGIES.md#43-deltas-obligatorios-en-el-fork-tras-copiarfusionar-yaml)).

### A.6 Imports muertos tras resolver conflictos

Un conflicto mal fusionado puede dejar **`import` sin uso** que rompe `go build`. Tras `go mod tidy`, ejecutar **`make build`** y corregir lo que el compilador marque (incluidos test helpers en `infinited/`).

### A.7 Tests y APIs tras merge upstream

Lecciones cuando **`make test-unit`** o integración fallan tras sincronizar con cosmos/evm, por cambios de API o por identidad del fork.

**Dónde viven los tests**

- El módulo raíz **`github.com/cosmos/evm`** ejecuta la mayoría de paquetes con `go test` / `make test-unit` desde la **raíz del repo**.
- Varios tests de integración (p. ej. suite **`TestEvmUnitAnteTestSuite`**) están bajo **`infinited/tests/integration/...`**: conviene validarlos con `cd infinited && go test ./tests/integration/...` (o path equivalente), no solo con tests en la raíz.

**`BlockGasLimit` vs `BlockGasMeter`**

- En este repo, `ante/types.BlockGasLimit` obtiene el tope de **`ConsensusParams().Block.MaxGas`**, no del `BlockGasMeter` del contexto (ver `ante/types/block.go`).
- Los tests que quieran el caso “gas pedido por la tx > límite de bloque” deben bajar **`MaxGas`** vía **`WithConsensusParams`** (copiando bien los params; ver siguiente punto), no confiar solo en **`WithBlockGasMeter`**.

**Trampa: copia superficial de `ConsensusParams` en tests**

- `ctx.ConsensusParams()` devuelve un struct **por valor**, pero el campo **`Block` suele ser un puntero** compartido con el estado de la app/red en tests de integración.
- Si se hace `cp := base.ConsensusParams(); cp.Block.MaxGas = …` sin clonar el bloque, se **muta el estado global** del `UnitTestNetwork` y los subtests siguientes ven un `MaxGas` inesperado (fallos enrevesados tipo “tx gas exceeds block gas limit (90000)” en casos que deberían pasar).
- Mitigación: copiar el mensaje antes de tocarlo, p. ej. `block := *cp.Block` (tras nil-check), `block.MaxGas = …`, `cp.Block = &block`; o **`proto.Clone`** sobre el proto completo si se prefiere.

**Identidad del fork en tests (denom, bech32)**

- Expectativas de fees/denoms en tests deben alinearse con **`testutil/constants`** y el token del fork (p. ej. **`drop`**, no sufijos genéricos tipo `atom` de ejemplos upstream).
- Con prefijo bech32 **`infinite`**, tests que armen `encoding.MakeConfig`, firmas o `GetSigners` deben fijar prefijos del fork **en el orden correcto** (p. ej. `TestMain` o init **antes** de construir el config global; en mempool, prefijos coherentes con la app **antes** de `MakeConfig`). Si no, errores tipo `hrp does not match` o checksum bech32 inválido en EIP-712.

**APIs de keepers eliminadas o renombradas**

- Tras el merge, puede desaparecer métodos que los tests de integración llamaban (ej. histórico **`GetTransientGasWanted`** en feemarket). **`go build`** del paquete `tests/integration/...` debe pasar; actualizar aserciones o eliminar checks obsoletos frente a la API real del keeper.

## Referencias rápidas

- [VERIFICATION.md](VERIFICATION.md)
- [REFERENCE.md](REFERENCE.md)
- [docs/guides/development/DEVELOPMENT.md](../guides/development/DEVELOPMENT.md)
