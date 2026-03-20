# Referencia: diffs y listados frente a upstream

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

Cifras del tipo “~122 archivos”, “~141 diferencias”, etc., son **instantáneas antiguas** de comparaciones `migration` vs `main` y **pueden estar obsoletas**. No usarlas como verdad absoluta: regenerar siempre con:

```bash
./scripts/list_all_customizations.sh upstream/main
```

Después de un merge grande, conviene guardar el output en la bitácora bajo `logs/` o adjuntarlo al PR.

## Línea base pre/post merge

1. Antes del merge: `./scripts/list_all_customizations.sh upstream/main > /tmp/diff-pre.txt`
2. Después del merge resuelto: mismo comando a `diff-post.txt`
3. Comparar o archivar en la bitácora del merge

Ver [PLAYBOOK.md](PLAYBOOK.md) fase 0 y 4.
