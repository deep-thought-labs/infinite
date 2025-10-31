# GitHub Actions Troubleshooting

**Copyright (c) 2025 Deep Thought Labs**  
Common issues and solutions for GitHub Actions workflows.

---

## Workflow No Se Ejecuta al Crear Tag

### Problema: Tag Creado pero Workflow No Se Activa

**Síntoma**:
- Creaste un tag y lo pusheaste
- GitHub Actions no muestra ningún workflow ejecutándose
- No aparece ningún proceso en la pestaña "Actions"

### Causas Comunes

#### 1. Formato de Tag No Coincide con Patrón

**Problema más común**: El formato de tu tag no coincide con el patrón configurado en el workflow.

**Patrón actual en `.github/workflows/release.yml`**:
```yaml
tags:
  - 'v*.*.*'  # Requiere formato: v1.0.0, v0.2.3, v1.5.10
```

**Esto significa**: Tag debe tener formato `vMAJOR.MINOR.PATCH` (semantic versioning)

**Ejemplos**:
- ✅ `v1.0.0` - ✅ Funciona
- ✅ `v0.02.0` - ✅ Funciona
- ✅ `v2.5.10` - ✅ Funciona
- ❌ `v0.02` - ❌ **NO funciona** (solo tiene un punto)
- ❌ `v1.0` - ❌ **NO funciona** (solo tiene un punto)
- ❌ `v1` - ❌ **NO funciona** (sin puntos)

**Solución**:

1. **Eliminar tag incorrecta del remoto**:
```bash
# Eliminar tag del remoto
git push origin --delete v0.02

# O usando el formato alternativo
git push origin :refs/tags/v0.02
```

2. **Crear tag con formato correcto**:
```bash
# Crear tag con formato semántico
git tag v0.02.0 HEAD

# O si quieres mantener la versión anterior
git tag v0.2.0 HEAD

# Push del tag
git push origin v0.02.0
```

#### 2. Workflow No Existe en el Branch

**Problema**: El archivo `.github/workflows/release.yml` solo existe en `main`, no en tu branch.

**Verificar**:
```bash
# Ver si el workflow existe en tu branch actual
git ls-tree -r HEAD --name-only | grep ".github/workflows/release.yml"
```

**Solución**:
```bash
# Asegúrate de que el workflow esté en tu branch
git checkout migration
git merge main  # Si el workflow está en main
# O simplemente asegúrate de que el archivo esté commitado en tu branch
```

#### 3. Branch Protection o Permisos

**Problema**: El workflow requiere permisos que no están configurados.

**Verificar**:
- El workflow necesita `contents: write` para crear releases
- Si el repositorio tiene protección de branches, puede necesitar aprobaciones

**Solución**:
```yaml
# Verificar que esto esté en el workflow
permissions:
  contents: write  # Requerido para crear releases
  packages: write # Requerido si publicas packages
```

#### 4. Workflow Deshabilitado

**Problema**: El workflow puede estar deshabilitado en GitHub.

**Verificar**:
1. Ve a: `https://github.com/USER/REPO/actions`
2. Verifica que el workflow "Release" esté habilitado
3. Si está deshabilitado, habílitalo desde la configuración

#### 5. Tag No Fue Pusheada Correctamente

**Problema**: La tag existe localmente pero no en GitHub.

**Verificar**:
```bash
# Ver tags en remoto
git ls-remote --tags origin | grep "v0.02"

# Si no aparece, la tag no fue pusheada
```

**Solución**:
```bash
# Push específico de la tag
git push origin v0.02.0

# O push todas las tags
git push --tags
```

---

## Verificar Estado del Workflow

### 1. Verificar que el Workflow Existe

```bash
# En tu branch actual
git ls-tree -r HEAD --name-only | grep ".github/workflows"
```

### 2. Verificar Formato de Tag

```bash
# Ver todas tus tags
git tag -l

# Verificar que coincida con el patrón v*.*.*
# Debe tener exactamente 2 puntos
```

### 3. Verificar en GitHub

1. Ve a: `https://github.com/USER/REPO/actions`
2. Revisa si hay algún workflow ejecutándose o fallido
3. Revisa los logs para ver errores

### 4. Probar Manualmente

Puedes ejecutar el workflow manualmente:

1. Ve a: `https://github.com/USER/REPO/actions/workflows/release.yml`
2. Click en "Run workflow"
3. Selecciona el branch y ejecuta

Esto prueba que el workflow funciona, incluso si el trigger automático no funciona.

---

## Formato de Tags Recomendado

### Semantic Versioning

Usa siempre formato `vMAJOR.MINOR.PATCH`:

- `v1.0.0` - Primera release
- `v1.1.0` - Nueva feature (minor)
- `v1.1.1` - Bug fix (patch)
- `v2.0.0` - Breaking change (major)
- `v0.1.0` - Pre-release (alpha/beta)

### Pre-Releases

Para pre-releases, puedes usar:

- `v1.0.0-rc1` - Release candidate 1
- `v1.0.0-alpha1` - Alpha 1
- `v1.0.0-beta1` - Beta 1

**Nota**: El patrón actual `v*.*.*` NO coincide con pre-releases. Si necesitas pre-releases, ajusta el patrón.

---

## Ajustar Patrón del Workflow (Opcional)

Si quieres aceptar tags sin formato semántico estricto, puedes modificar el workflow:

### Opción 1: Aceptar cualquier tag que empiece con 'v'

```yaml
on:
  push:
    tags:
      - 'v*'  # Acepta v1, v0.02, v1.0.0, etc.
```

### Opción 2: Múltiples patrones

```yaml
on:
  push:
    tags:
      - 'v*.*.*'      # v1.0.0, v0.2.3
      - 'v*.*'        # v0.02, v1.0
      - 'v*'          # v1, v0
```

**Recomendación**: Mantener `v*.*.*` y usar formato semántico siempre.

---

## Checklist de Troubleshooting

Cuando un workflow no se ejecuta:

- [ ] ¿El formato de la tag coincide con el patrón `v*.*.*`?
- [ ] ¿La tag fue pusheada al remoto? (`git ls-remote --tags origin`)
- [ ] ¿El workflow existe en el branch? (`git ls-tree -r HEAD`)
- [ ] ¿El workflow está habilitado en GitHub? (Settings → Actions)
- [ ] ¿Tienes permisos para ejecutar workflows?
- [ ] ¿Revisaste la pestaña "Actions" en GitHub?
- [ ] ¿Probaste ejecutar manualmente desde GitHub UI?

---

## Solución Rápida

**Si tu tag no funciona**:

1. Elimina la tag incorrecta:
```bash
git push origin --delete v0.02
```

2. Crea tag con formato correcto:
```bash
git tag v0.02.0 HEAD
git push origin v0.02.0
```

3. Verifica en GitHub Actions que el workflow se ejecute.

---

## Error: "no releases were created: 404 Not Found"

### Problema

**Síntoma**:
```
failed to publish artifacts: no releases were created: 
github.com client: GET https://api.github.com/repos/.../releases/tags/v0.02.0: 404 Not Found
```

**Causa**: GoReleaser está configurado con `mode: replace`, que intenta **actualizar** un release existente. Si el release no existe (primera vez), falla con 404.

**Solución**:

Cambiar el modo de release en `.goreleaser.yml`:

```yaml
release:
  mode: auto  # Cambiar de "replace" a "auto"
```

**Modos disponibles**:
- `auto` - Crea release si no existe, actualiza si existe (recomendado)
- `replace` - Solo actualiza releases existentes (falla si no existe)
- `skip` - No crea ni actualiza releases
- `keep_existing` - No modifica releases existentes

**Cambio realizado**: Ya cambié `mode: replace` a `mode: auto` en `.goreleaser.yml`.

**Próximos pasos**:
1. Commit el cambio: `git add .goreleaser.yml && git commit -m "fix: Change release mode to auto"`
2. Push el cambio al branch
3. Crear nueva tag o esperar a la próxima tag para que funcione

---

*Last updated: 2025*

