# Referencia: diffs y listados frente a upstream

## Remoto Git `upstream`

Origen del código de referencia: [cosmos/evm](https://github.com/cosmos/evm) — URL del remoto: `https://github.com/cosmos/evm.git`.

Varios scripts y comprobaciones usan la ref `**upstream/main**`. El remoto debe apuntar al **origen upstream**, no al fork del equipo.

**Añadir** (si aún no existe):

```bash
git remote add upstream https://github.com/cosmos/evm.git
git fetch upstream
```

**Si ya existe `upstream` pero con otra URL**, corregir:

```bash
git remote set-url upstream https://github.com/cosmos/evm.git
git fetch upstream
```

**Comprobar:**

```bash
git remote -v
# upstream  https://github.com/cosmos/evm.git (fetch)
# upstream  https://github.com/cosmos/evm.git (push)
```

`origin` suele ser el fork (p. ej. `deep-thought-labs/infinite`); `upstream` es **solo** cosmos/evm.

## Script `list_all_customizations.sh`

Lista archivos que difieren entre `HEAD` y una referencia Git (por defecto `upstream/main`).

```bash
./scripts/list_all_customizations.sh [ref]
```

Ejemplos:

```bash
./scripts/list_all_customizations.sh upstream/main
./scripts/list_all_customizations.sh main
./scripts/list_all_customizations.sh main > comparison_report.txt
```

Salida típica:

- Añadidos (A)
- Modificados (M)
- Eliminados en upstream pero presentes en el fork (D)

**Nota:** La ref debe existir (`refs/remotes/upstream/main` o rama local). El script compara contra el remoto upstream del repositorio oficial, no necesariamente contra la `main` del fork.

## Estadísticas “esperadas” (snapshot histórico)

Cifras del tipo “~~122 archivos”, “~~141 diferencias”, etc., son **instantáneas antiguas** de comparaciones `migration` vs `main` y **pueden estar obsoletas**. No usarlas como verdad absoluta: regenerar siempre con:

```bash
./scripts/list_all_customizations.sh upstream/main
```

Después de un merge grande, conviene guardar el output en la bitácora bajo `logs/` o adjuntarlo al PR.

## Línea base pre/post merge

1. Antes del merge: `./scripts/list_all_customizations.sh upstream/main > /tmp/diff-pre.txt`
2. Después del merge resuelto: mismo comando a `diff-post.txt`
3. Comparar o archivar en la bitácora del merge

Ver [PLAYBOOK.md](PLAYBOOK.md) fase 0 y 4.

## Chequeos post-merge (anti-regresión)

Complementan [VERIFICATION.md](VERIFICATION.md) y el [Apéndice A de PLAYBOOK.md](PLAYBOOK.md#apéndice-a-cierre-del-merge-y-trampas-frecuentes).

### Conflictos no resueltos

```bash
grep -R -n '^<<<<<<<' . --exclude-dir=.git || echo "OK"
```

### Mezcla prohibida `evmd` / `infinited` en imports

```bash
# En raíz del repo; evaluar cada coincidencia (en fork: suele tener que desaparecer evmd como path de binario local)
grep -R 'github.com/cosmos/evm/evmd' --include='*.go' . --exclude-dir=.git
```

### Organización esperada del árbol

- Binario y main package: carpeta `**infinited/**`, no una duplicada `**evmd/**` en la raíz del mismo módulo.
- Tras ediciones amplias: `**go mod tidy**` desde la raíz y, si existe, desde submódulos bajo `**tests/**` que tengan su propio `go.mod`.

### Dependencias Go vs upstream

Tras cerrar el merge, es normal que `go.mod` / `go.sum` difieran de upstream *más allá* del nombre del submódulo `infinited` (deps solo-fork, `go mod tidy`, indirectas podadas). [validate_customizations.sh](../../scripts/validate_customizations.sh) muestra **avisos informativos** al comparar con `upstream/main`, sin fallar el script por ello. Conviene **documentar** en la bitácora si hubo cambios de `replace`, exclusiones o líneas solo-fork.
