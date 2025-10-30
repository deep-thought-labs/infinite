# Validadores en el Génesis - Preguntas Frecuentes

## ¿Puede una cadena arrancar sin validadores?

**❌ NO**. Una cadena de Cosmos SDK **requiere al menos un validador** en el Genesis para poder producir bloques.

---

## ¿Qué pasa si el Genesis no tiene validadores?

Si intentas iniciar una cadena con un Genesis sin validadores:

1. **El Genesis es técnicamente válido** - `infinited genesis validate-genesis` puede pasar ✅
2. **PERO la cadena NO producirá bloques** - CometBFT no puede llegar a consenso sin un validator set
3. **El nodo iniciará** pero estará "atascado" esperando bloques que nunca llegarán

### Comportamiento esperado:

```
$ infinited start \
  --chain-id infinite_421018-1 \
  --evm.evm-chain-id 421018
...
I[2025-01-XX|...] starting ABCI with CometBFT
I[2025-01-XX|...] Starting node
...
# ⚠️ Aquí el nodo está corriendo pero NO produce bloques
# CometBFT esperará infinitamente por validadores que nunca aparecerán
```

---

## ¿Qué hacer para que la cadena funcione?

### Opción 1: Validadores desde el Bloque 0 (Recomendado para Mainnet)

Agregar validadores al Genesis **antes del lanzamiento**:

```bash
# 1. Generar Genesis base (con el script setup_genesis.sh)
./scripts/setup_genesis.sh mainnet my-moniker

# 2. Para cada validador inicial:
#    a. Crear clave del validador
infinited keys add validator-1 --keyring-backend file

#    b. Agregar cuenta con fondos para staking
infinited genesis add-genesis-account validator-1 10000000000000000000000drop \
  --keyring-backend file

#    c. Crear gentx (genesis transaction del validador)
infinited genesis gentx validator-1 1000000000000000000000drop \
  --chain-id infinite_421018-1 \
  --commission-rate "0.10" \
  --commission-max-rate "0.20" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "1000000000000000000" \
  --keyring-backend file

# 3. Recolectar TODOS los gentxs de todos los validadores
infinited genesis collect-gentxs

# Esto agrega todos los validadores al Genesis
# Ahora el Genesis tiene validadores y la cadena puede empezar a producir bloques
```

**Ventajas:**
- ✅ La cadena puede empezar inmediatamente
- ✅ Los validadores iniciales están definidos antes del launch
- ✅ No requiere propuestas de governance

**Desventajas:**
- ⚠️ Todos los validadores deben coordinar y enviar sus gentxs ANTES del launch
- ⚠️ Requiere confianza y coordinación entre los validadores iniciales

---

### Opción 2: Genesis sin Validadores (Solo para casos especiales)

Si realmente necesitas un Genesis sin validadores iniciales:

1. **Generar Genesis** (como siempre)
2. **NO ejecutar `collect-gentxs`**
3. **Distribuir el Genesis** a todos los nodos
4. **Problema**: La cadena NO producirá bloques hasta que alguien agregue validadores

**⚠️ ADVERTENCIA**: Esta opción tiene un problema fundamental:

- Sin validadores, no hay bloques
- Sin bloques, no se pueden enviar transacciones
- Sin transacciones, no se pueden crear propuestas de governance
- Sin governance, no se pueden agregar validadores

**En resumen**: Este escenario crea un "deadlock" y la cadena nunca empezará.

**La única forma de salir de esto** sería tener al menos un validador que pueda agregarse de forma especial (fuera de governance), pero esto requiere cambios en el código, lo cual no es práctico para producción.

---

## Recomendación para Infinite Drive

### Para Mainnet:

**✅ Usar Opción 1**: Definir validadores iniciales antes del launch.

**Proceso recomendado:**

1. **Fase de Preparación** (antes del launch):
   - Identificar los validadores iniciales (ej: 5-10 validadores confiables)
   - Cada validador debe:
     - Generar sus claves de manera segura
     - Crear su gentx con la cantidad correcta de tokens
     - Enviar el gentx a un coordinador
   - Coordinador recolecta todos los gentxs: `infinited genesis collect-gentxs`
   - Validar el Genesis final: `infinited genesis validate-genesis`
   - Distribuir el Genesis final a TODOS los nodos

2. **El Launch Day**:
   - Todos los nodos usan el mismo Genesis (con validadores incluidos)
   - La cadena empieza inmediatamente a producir bloques
   - Los validadores iniciales están activos desde el bloque 0

3. **Después del Launch**:
   - Nuevos validadores pueden unirse mediante:
     - Enviar transacciones de `create-validator` (después de acumular suficientes tokens)
     - Procesos de governance para agregar validadores institucionales

### Para Testnet:

Similar a Mainnet, pero puedes ser más flexible:
- Menos validadores iniciales (3-5 es suficiente)
- Tokens de testnet son fáciles de obtener
- Puedes tener un validador "de desarrollo" controlado por el equipo

---

## Mejoras al Script `setup_genesis.sh`

El script actual genera el Genesis base pero **no agrega validadores automáticamente**. Esto es **intencional** porque:

1. **Seguridad**: Agregar validadores requiere claves privadas y debe hacerse manualmente
2. **Flexibilidad**: Cada proyecto tiene diferentes requisitos sobre quiénes son los validadores iniciales
3. **Coordinación**: Los validadores deben ser recolectados de múltiples fuentes

**El script DEBE documentar claramente** que:
- ✅ Genera un Genesis válido
- ⚠️ PERO el Genesis NO tiene validadores
- ⚠️ Se DEBEN agregar validadores antes del launch
- 📝 Proporciona instrucciones claras sobre cómo agregarlos

---

## Checklist: Preparando Genesis con Validadores

Antes de lanzar:

- [ ] Genesis generado y configurado (usando `setup_genesis.sh`)
- [ ] Todos los parámetros configurados (denoms, governance, etc.)
- [ ] Validadores iniciales identificados (lista de direcciones/operadores)
- [ ] Cada validador ha generado sus claves de forma segura
- [ ] Cada validador ha creado su gentx y lo ha enviado
- [ ] Todos los gentxs recolectados: `infinited genesis collect-gentxs`
- [ ] Genesis validado: `infinited genesis validate-genesis`
- [ ] Genesis final distribuido a TODOS los nodos
- [ ] Verificar que el Genesis tiene validadores: `jq '.app_state.staking.validators | length' genesis.json` (debe ser > 0)
- [ ] Verificar que hay delegaciones: `jq '.app_state.staking.delegations | length' genesis.json` (debe ser > 0)

---

## Comandos Útiles

### Verificar validadores en Genesis:

```bash
# Contar validadores
jq '.app_state.staking.validators | length' genesis.json

# Ver lista de validadores
jq '.app_state.staking.validators[].operator_address' genesis.json

# Ver poder (staking) de cada validador
jq '.app_state.staking.validators[] | {operator: .operator_address, tokens: .tokens}' genesis.json

# Ver delegaciones
jq '.app_state.staking.delegations | length' genesis.json
```

### Verificar que el Genesis puede arrancar:

```bash
# Validar estructura
infinited genesis validate-genesis

# Verificar que hay validators en el validator set
jq '.validators | length' genesis.json  # Debe ser > 0
```

---

## Resumen

| Escenario | ¿Genesis Válido? | ¿Produce Bloques? | ¿Recomendado? |
|-----------|------------------|-------------------|---------------|
| **Sin validadores** | ✅ Sí (técnicamente) | ❌ NO | ❌ NO |
| **Con 1+ validadores** | ✅ Sí | ✅ Sí | ✅ SÍ |

**Conclusión**: Siempre necesitas al menos un validador en el Genesis para que la cadena funcione. El script `setup_genesis.sh` prepara el Genesis base, pero **debes agregar validadores manualmente** usando `infinited genesis gentx` y `infinited genesis collect-gentxs` antes del launch.

