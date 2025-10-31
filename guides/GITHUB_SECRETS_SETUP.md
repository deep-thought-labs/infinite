# Configuración de Secrets en GitHub Actions

**Copyright (c) 2025 Deep Thought Labs**  
Guía para configurar secrets necesarios para workflows de GitHub Actions.

---

## Secrets Requeridos

### 1. BUF_TOKEN (Opcional - Solo si usas Buf Schema Registry)

**Cuándo necesitas esto**: Si el workflow `bsr-push.yml` está habilitado y quieres hacer push a Buf Schema Registry.

**Cómo configurarlo**:

#### Paso 1: Obtener Token de Buf

1. Ve a https://buf.build/ e inicia sesión
2. Ve a tu perfil: https://buf.build/settings/user
3. En la sección **"Tokens"**, haz click en **"Create Token"**
4. Dale un nombre descriptivo (ej: "GitHub Actions - Infinite Drive")
5. **Copia el token inmediatamente** (solo se muestra una vez)

#### Paso 2: Agregar como Secret en GitHub

1. Ve a tu repositorio: `https://github.com/deep-thought-labs/infinite`
2. Click en **Settings** (configuración del repositorio)
3. En el menú lateral izquierdo, ve a **Secrets and variables** → **Actions**
4. Click en **New repository secret**
5. Nombre: `BUF_TOKEN` (exactamente así, case-sensitive)
6. Valor: Pega el token que copiaste
7. Click en **Add secret**

#### Paso 3: Verificar

Después de agregar el secret, el workflow debería funcionar. Para verificar:

```bash
# Crear una tag de prueba
git tag v0.1.5 HEAD
git push origin v0.1.5
```

El workflow `bsr-push.yml` debería ejecutarse sin errores.

---

## ¿Necesitas BUF_TOKEN?

**Sí, necesitas el token si**:
- ✅ Quieres publicar tus archivos Protobuf en Buf Schema Registry
- ✅ Usas Buf para gestionar versiones de tus schemas
- ✅ Otros proyectos consumen tus Protobuf desde Buf Schema Registry

**No, no necesitas el token si**:
- ❌ Solo usas Protobuf localmente
- ❌ No usas Buf Schema Registry
- ❌ Solo necesitas generar código desde .proto localmente

---

## Deshabilitar Workflow BSR Push (Si no lo necesitas)

Si **NO** planeas usar Buf Schema Registry, puedes deshabilitar el workflow:

### Opción 1: Agregar condición para deshabilitar

Edita `.github/workflows/bsr-push.yml`:

```yaml
jobs:
  push:
    runs-on: ubuntu-latest
    if: false  # Deshabilitado - no se usa Buf Schema Registry
    steps:
      ...
```

### Opción 2: Eliminar el workflow

```bash
rm .github/workflows/bsr-push.yml
git add .github/workflows/bsr-push.yml
git commit -m "chore: Remove BSR push workflow (not using Buf Schema Registry)"
```

### Opción 3: Modificar trigger (solo manual)

Cambia el trigger para que solo se ejecute manualmente:

```yaml
on:
  workflow_dispatch:  # Solo manual, no automático en tags
```

---

## Verificar Secrets Configurados

### Ver qué secrets existen:

1. Ve a: `https://github.com/deep-thought-labs/infinite/settings/secrets/actions`
2. Verás la lista de secrets del repositorio
3. Los secrets no muestran sus valores (por seguridad)

### Verificar que el workflow puede acceder:

El workflow usa el secret así:

```yaml
buf_token: ${{ secrets.BUF_TOKEN }}
```

Si el secret existe con ese nombre exacto, el workflow puede acceder a él.

---

## Troubleshooting

### "a buf authentication token was not provided"

**Causa**: El secret `BUF_TOKEN` no existe o tiene nombre incorrecto.

**Solución**:
1. Verifica Settings → Secrets → Actions
2. Verifica que el nombre es exactamente `BUF_TOKEN` (sin espacios, case-sensitive)
3. Si no existe, créalo siguiendo los pasos arriba

### "Invalid authentication token"

**Causa**: El token es inválido o ha expirado.

**Solución**:
1. Genera un nuevo token en buf.build
2. Actualiza el secret en GitHub con el nuevo token

### El workflow no se ejecuta después de configurar el token

**Posibles causas**:
- La tag ya fue pusheada antes de configurar el token (el workflow solo se ejecuta en push de tags)
- El workflow está deshabilitado

**Solución**:
- Crea una nueva tag o actualiza la tag existente para trigger el workflow nuevamente

---

## Recomendación Rápida

**Para Infinite Drive**:

Si no estás usando activamente Buf Schema Registry:
1. **Deshabilita el workflow** agregando `if: false` en el job
2. O elimina el archivo `.github/workflows/bsr-push.yml`
3. No necesitas configurar el token

Si planeas usar Buf Schema Registry:
1. Configura el token siguiendo los pasos arriba
2. Asegúrate de que el repositorio existe en buf.build o créalo

---

*Last updated: 2025*

