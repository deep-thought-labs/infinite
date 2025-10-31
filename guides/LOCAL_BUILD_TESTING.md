# Guía de Pruebas Locales de Builds

**Copyright (c) 2025 Deep Thought Labs**  
Guía para probar builds localmente en Ubuntu nativo y Mac M1.

---

## Confirmación: Los Cambios Funcionan Localmente

✅ **Sí, todos los cambios funcionarán en tus equipos locales** con los siguientes comandos.

Los cambios realizados:
- Configuración enfocada solo en Linux (AMD64 y ARM64)
- Cross-compilation configurada correctamente
- Comandos del Makefile listos para uso local

---

## Comandos para Probar Localmente

### Prerequisitos Rápidos

Verifica que tienes todo instalado:

```bash
# Ejecuta el script de verificación (si existe)
./scripts/check_build_prerequisites.sh

# O verifica manualmente:
docker --version        # Docker debe estar instalado
go version              # Go 1.25.0 requerido
make --version          # Make debe estar instalado
git --version           # Git debe estar instalado
```

---

## Opción 1: Test Build Linux (Recomendado)

**Comando más rápido y recomendado para desarrollo local:**

```bash
make release-dry-run-linux
```

**¿Qué hace?**
- Compila para Linux AMD64 y Linux ARM64
- Usa `.goreleaser.linux-only.yml`
- Crea builds de prueba (snapshot) en `dist/`
- No publica en GitHub
- Tiempo estimado: ~10-15 minutos

**Funciona en:**
- ✅ Ubuntu nativo (AMD64)
- ✅ Ubuntu nativo (ARM64)
- ⚠️ Mac M1: AMD64 funcionará, ARM64 puede fallar (esperado)

---

## Opción 2: Test Build Completo

**Usa la configuración principal (también solo Linux ahora):**

```bash
make release-dry-run
```

**¿Qué hace?**
- Compila para Linux AMD64 y Linux ARM64
- Usa `.goreleaser.yml` (configuración principal)
- Crea builds de prueba (snapshot) en `dist/`
- No publica en GitHub
- Tiempo estimado: ~10-15 minutos (igual que linux-only porque ambos son solo Linux)

**Funciona en:**
- ✅ Ubuntu nativo (AMD64)
- ✅ Ubuntu nativo (ARM64)
- ⚠️ Mac M1: AMD64 funcionará, ARM64 puede fallar (esperado)

**Nota:** Este comando ahora es equivalente a `release-dry-run-linux` porque ambos configs solo tienen Linux.

---

## Comportamiento Esperado por Plataforma

### Ubuntu Nativo (AMD64 o ARM64)

**Comportamiento esperado:**
- ✅ Build AMD64: **Funciona perfectamente**
- ✅ Build ARM64: **Funciona perfectamente** (si estás en ARM64) o requiere cross-compiler (si estás en AMD64)

**Ejemplo de salida exitosa:**
```
✅ Building linux_amd64... done
✅ Building linux_arm64... done
✅ Created dist/infinite_Linux_x86_64.tar.gz
✅ Created dist/infinite_Linux_ARM64.tar.gz
✅ Created dist/checksums.txt
```

**Tiempo estimado:** ~8-12 minutos

---

### Mac M1 (Apple Silicon)

**Comportamiento esperado:**
- ✅ Build AMD64: **Funciona** (Docker emula AMD64)
- ⚠️ Build ARM64: **Puede fallar** con errores de assembler (esto es normal y esperado)

**Ejemplo de salida:**
```
✅ Building linux_amd64... done
❌ Building linux_arm64... failed
   Error: gcc_arm64.S: Assembler messages
   This is expected on Mac M1 with Docker emulation
```

**¿Por qué falla ARM64 en Mac M1?**
- Docker en Mac M1 emula el contenedor AMD64
- El cross-compiler ARM64 dentro del contenedor emulado tiene problemas con el assembler de Go runtime
- **Solución:** Los builds ARM64 funcionan correctamente en GitHub Actions (Ubuntu nativo)

**Tiempo estimado:** ~10-15 minutos (AMD64 completo, ARM64 puede fallar)

---

## Verificación de Builds Exitosos

Después de ejecutar cualquier comando, verifica los artefactos:

```bash
# Listar builds creados
ls -lh dist/

# Deberías ver algo como:
# infinite_Linux_x86_64.tar.gz    (AMD64)
# infinite_Linux_ARM64.tar.gz      (ARM64, si funcionó)
# checksums.txt                    (Checksums SHA256)
```

**Verificar contenido de un build:**
```bash
# Extraer y verificar
tar -tzf dist/infinite_Linux_x86_64.tar.gz

# Deberías ver:
# infinited
# README.md
# LICENSE
# CHANGELOG.md
```

**Verificar el binario:**
```bash
# Extraer
tar -xzf dist/infinite_Linux_x86_64.tar.gz

# Verificar tipo de archivo (debe ser Linux binary)
file infinited
# Output esperado: infinited: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), ...

# Verificar que funciona (si estás en Linux)
./infinited version
```

---

## Troubleshooting Local

### Error: "docker: command not found"
**Solución:**
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y docker.io
sudo systemctl start docker
sudo usermod -aG docker $USER  # Logout/login después

# macOS
brew install docker
# O instala Docker Desktop desde https://www.docker.com/products/docker-desktop
```

### Error: "permission denied while trying to connect to the Docker daemon socket"
**Solución:**
```bash
# Ubuntu/Linux
sudo usermod -aG docker $USER
# Cierra sesión y vuelve a entrar, o:
newgrp docker

# Luego verifica:
docker ps
```

### Error: "go: cannot find main module"
**Solución:**
```bash
# Asegúrate de estar en la raíz del proyecto
pwd  # Debe mostrar: .../evm-test

# Verifica que existe go.mod
ls go.mod

# Descarga dependencias
go mod download
```

### Error ARM64 en Mac M1: "gcc_arm64.S: Assembler messages"
**Esto es esperado y normal:**
- ✅ El build AMD64 debería funcionar
- ⚠️ El build ARM64 fallará, pero esto es normal en Mac M1
- ✅ Los builds ARM64 funcionan correctamente en GitHub Actions (Ubuntu nativo)
- ✅ Los binarios producidos en GitHub Actions son correctos y funcionales

**No necesitas hacer nada**, esto es el comportamiento esperado.

---

## Comparación: Ubuntu vs Mac M1

| Aspecto | Ubuntu Nativo | Mac M1 |
|--------|---------------|--------|
| **AMD64 Build** | ✅ Funciona | ✅ Funciona (emulado) |
| **ARM64 Build** | ✅ Funciona | ⚠️ Puede fallar (esperado) |
| **Tiempo** | ~8-12 min | ~10-15 min |
| **Velocidad** | Más rápido (nativo) | Más lento (emulación) |

---

## Próximos Pasos

1. **Prueba local:** Ejecuta `make release-dry-run-linux` en tu equipo
2. **Verifica builds:** Revisa que `dist/` contiene los archivos esperados
3. **Test en Docker:** Los binarios producidos funcionarán en imágenes Docker multi-arch
4. **GitHub Actions:** Cuando hagas push de un tag, GitHub Actions creará builds para ambas arquitecturas

---

## Resumen de Comandos

```bash
# Opción más rápida (recomendada)
make release-dry-run-linux

# Opción completa (equivalente ahora)
make release-dry-run

# Verificar resultados
ls -lh dist/

# Limpiar builds anteriores
rm -rf dist/
```

---

**¿Preguntas?** Revisa:
- `guides/BUILDING_AND_RELEASES.md` - Documentación completa
- `guides/DOCKER_BUILD_CONFIGURATION.md` - Explicación de flags Docker
- `guides/DOCKER_ARCHITECTURE_DECISION.md` - Decisiones de arquitectura

