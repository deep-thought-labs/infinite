# Docker Architecture Decision Guide

**Copyright (c) 2025 Deep Thought Labs**  
Guide to help decide which Linux architectures to compile for Docker deployments.

---

## La Pregunta Clave

**¿Necesito compilar para Linux ARM64 si mi binario corre en una imagen Docker Ubuntu?**

La respuesta depende de **dónde se ejecutará el contenedor Docker**, no de qué OS base tenga la imagen.

---

## Entendiendo Docker y Arquitecturas

### Concepto Fundamental

**La arquitectura del binario debe coincidir con la arquitectura del HOST donde corre Docker, NO con la imagen base.**

```
┌─────────────────────────────────────────┐
│  Host Machine (Mac M1 ARM64)            │
│  ┌───────────────────────────────────┐  │
│  │ Docker Engine                      │  │
│  │  ┌──────────────────────────────┐  │  │
│  │  │ Container (Ubuntu AMD64)    │  │  │
│  │  │  ┌────────────────────────┐  │  │  │
│  │  │  │ infinited (¿qué arch?) │  │  │  │
│  │  │  └────────────────────────┘  │  │  │
│  │  └──────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**Escenarios**:

1. **Host AMD64 + Binario AMD64** = ✅ **Funciona nativo (rápido)**
2. **Host ARM64 + Binario AMD64** = ⚠️ **Funciona con emulación (lento)**
3. **Host ARM64 + Binario ARM64** = ✅ **Funciona nativo (rápido)**
4. **Host AMD64 + Binario ARM64** = ❌ **No funciona (o muy lento con emulación inversa)**

---

## Escenarios de Uso

### Escenario 1: Solo Servidores Linux AMD64 en Producción

**Situación**:
- Producción: Servidores Linux AMD64 únicamente
- Desarrollo: Mac M1, Windows, etc. (solo para desarrollo)

**Decisión**: ✅ **Solo necesitas `linux_amd64`**

**Razón**:
- El binario corre en servidores AMD64 (nativo, rápido)
- Desarrollo local puede usar emulación (no importa, solo testing)
- Más simple, builds más rápidos

**Configuración recomendada**:
```yaml
# .goreleaser.linux-only.yml (modificar)
targets:
  - linux_amd64  # Solo esto es necesario
  # - linux_arm64  # Remover si no se necesita
```

---

### Escenario 2: Producción Multi-Arquitectura (Cloud/Servers Variados)

**Situación**:
- Producción: Mix de servidores AMD64 y ARM64
- Ejemplos: AWS Graviton (ARM64), servidores tradicionales (AMD64)
- Cloud providers que ofrecen instancias ARM64 más baratas

**Decisión**: ✅ **Necesitas AMBOS: `linux_amd64` Y `linux_arm64`**

**Razón**:
- Servidores ARM64 (AWS Graviton, etc.) son cada vez más comunes
- ARM64 puede ser más barato en cloud
- Rendimiento nativo es mucho mejor que emulación
- Usuarios pueden tener servidores ARM64 propios

**Configuración recomendada**:
```yaml
# .goreleaser.linux-only.yml (mantener como está)
targets:
  - linux_amd64   # Para servidores tradicionales
  - linux_arm64   # Para servidores ARM64 (AWS Graviton, etc.)
```

**Beneficio**: Una imagen Docker multi-arch puede contener ambos binarios y Docker selecciona el correcto automáticamente.

---

### Escenario 3: Desarrollo Local en Mac M1

**Situación**:
- Desarrollo local: Mac M1/M2/M3 (ARM64)
- Producción: Servidores Linux AMD64

**Decisión**: ⚠️ **Depende de tus prioridades**

**Opción A: Solo AMD64** (más simple)
- Producción: Funciona perfecto (nativo)
- Desarrollo local: Funciona con emulación (más lento, pero aceptable)
- Builds más rápidos

**Opción B: Ambos** (mejor rendimiento)
- Producción: Funciona perfecto (nativo)
- Desarrollo local: Puede usar ARM64 nativo (más rápido)
- Builds más lentos, pero mejor experiencia de desarrollo

---

## Rendimiento: Nativo vs Emulación

### Benchmark Típico

| Escenario | Rendimiento Relativo |
|-----------|---------------------|
| Host AMD64 + Binario AMD64 (nativo) | 100% (baseline) |
| Host ARM64 + Binario ARM64 (nativo) | 100% (baseline) |
| Host ARM64 + Binario AMD64 (emulación) | 30-50% (mucho más lento) |
| Host AMD64 + Binario ARM64 (emulación) | 20-30% (muy lento, raro) |

**Conclusión**: Emulación es **significativamente más lenta**. Si tienes usuarios con hosts ARM64, dales binarios ARM64.

---

## Imágenes Docker Multi-Architecture

### ¿Qué son?

Una imagen Docker multi-arch puede contener binarios para múltiples arquitecturas. Docker automáticamente selecciona el correcto:

```bash
# Imagen multi-arch (contiene ambos binarios)
docker pull infinited:latest

# En Mac M1 (ARM64): Docker automáticamente descarga/usa versión ARM64
# En Linux Server (AMD64): Docker automáticamente descarga/usa versión AMD64
```

### Cómo Crear Imágenes Multi-Arch

**Opción 1: Build separado por arch** (recomendado)
```dockerfile
# Dockerfile
FROM ubuntu:22.04
COPY infinited-${TARGETARCH} /usr/local/bin/infinited
```

```bash
# Build para AMD64
docker build --build-arg TARGETARCH=amd64 -t infinited:latest-amd64 .

# Build para ARM64
docker build --build-arg TARGETARCH=arm64 -t infinited:latest-arm64 .

# Crear manifest multi-arch
docker manifest create infinited:latest \
  infinited:latest-amd64 \
  infinited:latest-arm64
```

**Opción 2: Buildx automático**
```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t infinited:latest --push .
```

---

## Recomendación Basada en Tu Caso

### Análisis de Tu Situación

Según tu descripción:
- Binarios se usarán en imágenes Docker
- Hosts pueden ser: Mac M1, Intel Mac, Windows, Linux servers
- Imagen base: Ubuntu

### Recomendación: **AMBAS Arquitecturas** (AMD64 + ARM64)

**Razones**:

1. **Cobertura Completa**:
   - ✅ Servidores tradicionales (AMD64): Funciona nativo
   - ✅ Servidores modernos ARM64 (AWS Graviton, etc.): Funciona nativo
   - ✅ Desarrollo Mac M1: Puede usar ARM64 nativo (mejor rendimiento)

2. **Cloud Native**:
   - AWS Graviton2/Graviton3 (ARM64) son comunes y más baratos
   - Google Cloud tiene instancias ARM64
   - Kubernetes soporta multi-arch sin problemas

3. **Futuro-Proof**:
   - ARM64 está creciendo en datacenters
   - Más opciones para usuarios
   - No tendrás que agregarlo después

4. **Costo de Build**:
   - Solo afecta tiempo de compilación (no costo de runtime)
   - GitHub Actions lo hace gratis
   - Desarrollo local puede usar `linux-only` con solo AMD64

### Configuración Recomendada

**Para producción** (`.goreleaser.yml`):
```yaml
targets:
  - linux_amd64    # Servidores tradicionales
  - linux_arm64    # Servidores ARM64 modernos
  - darwin_amd64    # macOS Intel (opcional)
  - darwin_arm64    # macOS Apple Silicon (opcional)
  - windows_amd64   # Windows (opcional)
```

**Para desarrollo rápido** (`.goreleaser.linux-only.yml`):
```yaml
targets:
  - linux_amd64    # Suficiente para la mayoría de casos
  # - linux_arm64  # Opcional: agregar si desarrollas en Mac M1
```

---

## Cuándo NO Necesitas ARM64

**Puedes omitir ARM64 si**:

1. ✅ **Solo producción en servidores AMD64 tradicionales**
   - No usas AWS Graviton ni servidores ARM64
   - Todos tus servidores son x86_64

2. ✅ **Desarrollo local no es prioridad**
   - No importa si desarrollo es más lento (emulación)
   - Solo te importa producción

3. ✅ **Quieres builds más rápidos**
   - Menos plataformas = builds más rápidos
   - Simplicidad en mantenimiento

**En este caso**: Solo compila `linux_amd64`

---

## Decisión Rápida

**¿Tu producción incluye servidores ARM64?**
- ✅ Sí → **Compila AMBOS** (amd64 + arm64)
- ❌ No → **Solo AMD64** es suficiente

**¿Desarrollas en Mac M1 y te importa rendimiento?**
- ✅ Sí → **Compila ARM64** también
- ❌ No → Solo AMD64 está bien

**¿Quieres máxima compatibilidad sin pensar en arquitecturas?**
- ✅ Sí → **Compila AMBOS**
- ❌ No → Solo AMD64

---

## Cómo Modificar la Configuración

### Opción 1: Solo AMD64 (Simplificado)

Modifica `.goreleaser.linux-only.yml`:
```yaml
targets:
  - linux_amd64    # Solo esto
  # Remover: linux_arm64
```

Y `.goreleaser.yml` si también quieres simplificar producción:
```yaml
targets:
  - linux_amd64
  # Remover: linux_arm64
  - darwin_amd64
  - darwin_arm64
  - windows_amd64
```

### Opción 2: Mantener Ambos (Recomendado)

Deja la configuración actual como está. Tienes:
- ✅ Cobertura completa
- ✅ Máxima compatibilidad
- ✅ Futuro-proof

---

## Resumen

| Tu Situación | Recomendación |
|--------------|---------------|
| Solo servidores AMD64 en producción | Solo `linux_amd64` |
| Mix de servidores AMD64 y ARM64 | `linux_amd64` + `linux_arm64` |
| Desarrollo en Mac M1 importante | `linux_amd64` + `linux_arm64` |
| Máxima compatibilidad | `linux_amd64` + `linux_arm64` |
| Simplicidad > Compatibilidad | Solo `linux_amd64` |

**Para tu caso específico** (binarios en Docker, múltiples hosts):
**Recomendación: Mantén AMBOS** (`linux_amd64` + `linux_arm64`)

---

*Last updated: 2025*

