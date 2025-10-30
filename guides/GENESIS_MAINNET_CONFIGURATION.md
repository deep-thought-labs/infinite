# Configuración del Génesis para Mainnet de Producción

Este documento detalla todos los aspectos que debes contemplar al crear el archivo Génesis definitivo para la Mainnet estable de Infinite Drive, asumiendo que en este momento no existe ningún validador.

**⚠️ IMPORTANTE**: Los ejemplos en las guías muestran cómo poblar el génesis con cuentas dummy o transacciones dummy para desarrollo. Este documento se enfoca en lo necesario para una **Mainnet de producción real**.

## Tabla de Contenidos

1. [¿Dónde se Configuran los Parámetros del Génesis?](#¿dónde-se-configuran-los-parámetros-del-génesis) - **LEE ESTO PRIMERO**
2. [Información Básica de la Cadena](#información-básica-de-la-cadena)
3. [Configuración de Módulos Cosmos SDK](#configuración-de-módulos-cosmos-sdk)
4. [Configuración de Módulos Específicos de Infinite Drive](#configuración-de-módulos-específicos-de-infinite-drive)
5. [Parámetros de Consenso (CometBFT/Tendermint)](#parámetros-de-consenso-cometbfttendermint)
6. [Configuración de Validadores Iniciales](#configuración-de-validadores-iniciales)
7. [Configuración de Cuentas y Balances](#configuración-de-cuentas-y-balances)
8. [Seguridad y Parámetros Económicos](#seguridad-y-parámetros-económicos)
9. [Verificación del Génesis](#verificación-del-génesis)
10. [Proceso Recomendado de Creación](#proceso-recomendado-de-creación)

---

## ¿Dónde se Configuran los Parámetros del Génesis?

**⚠️ Pregunta Crítica**: ¿Las configuraciones se hacen en el código del proyecto o directamente en el archivo Genesis JSON?

La respuesta es: **AMBAS**. Depende del tipo de parámetro:

### 🔷 Parámetros que Vienen del Código (Valores por Defecto)

Cuando ejecutas `infinited init`, el sistema genera un Genesis inicial usando valores por defecto del código:

1. **Valores por defecto de Cosmos SDK**:
   - Los módulos estándar (staking, bank, governance, mint, slashing) tienen valores por defecto definidos en el Cosmos SDK
   - Estos valores están hardcodeados en el código fuente de Cosmos SDK
   - Ejemplo: `unbonding_time: "1814400s"`, `max_validators: 100`, períodos de governance de `172800s` (2 días)

2. **Valores específicos de Infinite Drive** (modificados en código):
   - **Precompiles EVM**: Habilitados automáticamente desde `infinited/genesis.go`
   - **Denominación EVM**: El denom por defecto para EVM se configura en código (`testutil/constants/constants.go`: `ExampleAttoDenom = "drop"`)
   - **Token pairs ERC20**: Configuración inicial en `infinited/genesis.go`

**Ubicación del código**:
- `infinited/app.go` → `DefaultGenesis()`: Genera el Genesis base
- `infinited/genesis.go`: Define valores específicos para módulos EVM, ERC20, Mint, FeeMarket
- Cosmos SDK: Valores por defecto en los módulos estándar

### 🔷 Parámetros que se Configuran en el Genesis JSON

Después de ejecutar `infinited init`, debes **modificar manualmente** el archivo `genesis.json` para Mainnet:

1. **Denominaciones (Denoms)**:
   ```bash
   # Ejemplo usando jq (como en local_node.sh):
   jq '.app_state["staking"]["params"]["bond_denom"]="drop"' genesis.json > temp.json && mv temp.json genesis.json
   jq '.app_state["evm"]["params"]["evm_denom"]="drop"' genesis.json > temp.json && mv temp.json genesis.json
   jq '.app_state["mint"]["params"]["mint_denom"]="drop"' genesis.json > temp.json && mv temp.json genesis.json
   ```
   **Dónde**: Directamente en el archivo JSON del Genesis

2. **Parámetros de Governance**:
   - Períodos de votación (cambiar de `172800s` a valores apropiados)
   - Depósitos mínimos
   - Thresholds (quorum, threshold, veto_threshold)
   ```bash
   # Ejemplo: cambiar períodos de governance
   sed -i.bak 's/"max_deposit_period": "172800s"/"max_deposit_period": "172800s"/g' genesis.json
   sed -i.bak 's/"voting_period": "172800s"/"voting_period": "172800s"/g' genesis.json
   ```
   **Dónde**: Directamente en el archivo JSON del Genesis

3. **Metadata del Token**:
   ```bash
   jq '.app_state["bank"]["denom_metadata"]=[{...}]' genesis.json > temp.json && mv temp.json genesis.json
   ```
   **Dónde**: Directamente en el archivo JSON del Genesis

4. **Balances y Cuentas Iniciales**:
   ```bash
   infinited genesis add-genesis-account ADDRESS AMOUNTdrop
   ```
   **Dónde**: Usando comandos CLI que modifican el Genesis JSON

5. **Validadores Iniciales**:
   ```bash
   infinited genesis gentx validator AMOUNT --chain-id CHAIN_ID
   infinited genesis collect-gentxs
   ```
   **Dónde**: Usando comandos CLI que agregan transacciones al Genesis JSON

6. **Parámetros de Consenso**:
   ```bash
   jq '.consensus.params.block.max_gas="10000000"' genesis.json > temp.json && mv temp.json genesis.json
   ```
   **Dónde**: Directamente en el archivo JSON del Genesis

### 📋 Resumen: Configuración por Tipo de Parámetro

| Tipo de Parámetro | Dónde se Configura | ¿Se puede Cambiar sin Recompilar? |
|-------------------|-------------------|----------------------------------|
| **Valores por defecto de Cosmos SDK** | Código fuente del Cosmos SDK | ❌ No (hardcodeados en Cosmos SDK) |
| **Estructura de módulos disponibles** | `infinited/app.go` | ❌ No (requiere modificar código y recompilar) |
| **Precompiles EVM habilitados** | `infinited/genesis.go` | ✅ Sí (modificar JSON directamente) |
| **Denominaciones (bond_denom, evm_denom)** | Genesis JSON | ✅ Sí (usando jq o edición manual) |
| **Parámetros de governance** | Genesis JSON | ✅ Sí (usando jq, sed o edición manual) |
| **Metadata del token** | Genesis JSON | ✅ Sí (usando jq o edición manual) |
| **Balances iniciales** | Genesis JSON (vía CLI) | ✅ Sí (usando `genesis add-genesis-account`) |
| **Validadores iniciales** | Genesis JSON (vía CLI) | ✅ Sí (usando `genesis gentx` y `collect-gentxs`) |
| **Parámetros de consenso** | Genesis JSON | ✅ Sí (usando jq o edición manual) |

### 🔧 Proceso de Configuración Típico

1. **Generar Genesis inicial**:
   ```bash
   infinited init my-moniker --chain-id infinite_421018-1
   ```
   Esto genera `~/.infinited/config/genesis.json` con valores por defecto del código.

2. **Personalizar para Mainnet**:
   - Usar `jq` para modificar denoms
   - Usar `sed` o edición manual para cambiar períodos de governance
   - Usar comandos CLI para agregar cuentas y validadores
   - Editar manualmente parámetros específicos

3. **Validar**:
   ```bash
   infinited genesis validate-genesis
   ```

**Ejemplo práctico**: Ver `local_node.sh` líneas 233-256 para ver cómo se personaliza el Genesis después de `infinited init`.

### ⚠️ Limitaciones Importantes

1. **No puedes cambiar**:
   - Qué módulos Cosmos SDK están disponibles (requiere modificar `app.go` y recompilar)
   - La estructura básica del Genesis (definida en el código)
   - Los precompiles disponibles (aunque sí puedes habilitar/deshabilitarlos en el JSON)

2. **Puedes cambiar**:
   - Cualquier valor de parámetro dentro de los módulos existentes
   - Balances, cuentas, validadores
   - Metadata, denoms, períodos

### 🎯 Recomendación para Mainnet

1. **NO modifiques el código** a menos que necesites agregar módulos o funcionalidades nuevas
2. **SÍ modifica el Genesis JSON** para todos los parámetros específicos de tu Mainnet
3. **Documenta los cambios** que hagas manualmente para futuras referencias
4. **Valida siempre** después de cada modificación usando `infinited genesis validate-genesis`

---

## Información Básica de la Cadena

### 1. Chain ID

Debes definir dos Chain IDs que deben ser consistentes:

- **Cosmos Chain ID**: Formato `{nombre}_####-{versión}`
  - Ejemplo: `infinite_421018-1`
  - Este es el identificador de la cadena en Cosmos SDK

- **EVM Chain ID**: Número entero según EIP-155
  - Ejemplo: `421018`
  - Este es el identificador usado en contratos EVM y wallets

**Consideraciones**:
- El EVM Chain ID debe ser único y no colisionar con otras redes conocidas
- Una vez establecido, NO puede cambiar sin un hard fork
- El Cosmos Chain ID puede cambiar la versión (`-1`, `-2`, etc.) en upgrades

### 2. Denominaciones (Denoms)

Configuración del token nativo:

- **Base Denom**: La unidad más pequeña (equivalente a "wei" en Ethereum)
  - Ejemplo: `drop`
  - Se usa para todas las operaciones internas

- **Display Denom**: La unidad mostrada a usuarios
  - Ejemplo: `TEA`
  - Equivalente a "ETH" en Ethereum

- **Decimales**: Cantidad de decimales
  - Ejemplo: `18` (standard para compatibilidad EVM)
  - 1 TEA = 10^18 drop

**Metadata del Token** (para el módulo Bank):
```json
{
  "description": "Descripción oficial del token",
  "denom_units": [
    {
      "denom": "drop",
      "exponent": 0,
      "aliases": []
    },
    {
      "denom": "TEA",
      "exponent": 18,
      "aliases": []
    }
  ],
  "base": "drop",
  "display": "TEA",
  "name": "Nombre del Token",
  "symbol": "TEA"
}
```

### 3. Bech32 Prefix

El prefijo para direcciones Cosmos:
- Ejemplo: `infinite`
- Se usa en direcciones como: `infinite1abc...`

---

## Configuración de Módulos Cosmos SDK

### 1. Módulo Staking

**Parámetros críticos**:

```json
{
  "app_state": {
    "staking": {
      "params": {
        "bond_denom": "drop",                    // DEBE ser el base denom
        "historical_entries": 10000,             // Historial de delegaciones
        "max_entries": 7,                        // Máximo de entradas por delegador
        "max_validators": 100,                   // Máximo de validadores activos
        "min_commission_rate": "0.000000000000000000",  // Comisión mínima (%)
        "unbonding_time": "1814400s"             // Tiempo de unbonding (21 días)
      }
    }
  }
}
```

**Consideraciones de producción**:
- `bond_denom`: Debe coincidir exactamente con el base denom configurado
- `max_validators`: Define cuántos validadores pueden estar activos simultáneamente
- `unbonding_time`: Tiempo que tarda un stake en estar disponible después de undelegar
- `historical_entries`: Más alto = más historial pero más espacio en disco

### 2. Módulo Bank

**Configuración**:
```json
{
  "app_state": {
    "bank": {
      "params": {
        "send_enabled": [],                     // Lista vacía = todos habilitados
        "default_send_enabled": true            // Permite enviar por defecto
      },
      "denom_metadata": [ /* metadata del token aquí */ ],
      "supply": [ /* supply inicial total */ ],
      "balances": [ /* balances de cuentas */ ]
    }
  }
}
```

**Consideraciones**:
- El `supply` total debe igualar la suma de todos los `balances`
- Debes incluir el balance de la cuenta del módulo `bonded_tokens_pool` con los tokens stakeados inicialmente

### 3. Módulo Governance

**Parámetros críticos para producción**:

```json
{
  "app_state": {
    "gov": {
      "params": {
        "min_deposit": [
          {
            "denom": "drop",
            "amount": "1000000000000000000"      // 1 TEA (ajustar según necesidad)
          }
        ],
        "max_deposit_period": "172800s",        // 2 días (NO usar 30s como en dev)
        "voting_period": "172800s",             // 2 días (NO usar 30s como en dev)
        "quorum": "0.334000000000000000",       // 33.4% de participación mínima
        "threshold": "0.500000000000000000",    // 50% para aprobar
        "veto_threshold": "0.334000000000000000", // 33.4% para vetar
        "expedited_min_deposit": [
          {
            "denom": "drop",
            "amount": "5000000000000000000"      // 5 TEA para propuestas expedited
          }
        ],
        "expedited_voting_period": "86400s"     // 1 día para expedited
      }
    }
  }
}
```

**⚠️ DIFERENCIAS CRÍTICAS CON DESARROLLO**:
- En desarrollo se usan períodos de 30s para pruebas rápidas
- En producción DEBES usar períodos realistas (2 días es estándar)
- `min_deposit` debe ser suficientemente alto para evitar spam pero accesible
- Los valores de threshold afectan la gobernabilidad del protocolo

### 4. Módulo Mint

**Configuración**:
```json
{
  "app_state": {
    "mint": {
      "params": {
        "mint_denom": "drop",
        "inflation_rate_change": "0.130000000000000000",  // Cambio de inflación anual
        "inflation_max": "0.200000000000000000",           // Máximo 20% anual
        "inflation_min": "0.070000000000000000",           // Mínimo 7% anual
        "goal_bonded": "0.670000000000000000",             // 67% stakeado objetivo
        "blocks_per_year": "6311520"                       // Bloques por año (aprox)
      },
      "minter": {
        "inflation": "0.130000000000000000",
        "annual_provisions": "0"
      }
    }
  }
}
```

**Consideraciones**:
- Si no quieres inflación inicial, configura `inflation_min` y `inflation_max` a 0
- `blocks_per_year` se calcula basado en el tiempo de bloque objetivo
- La inflación recompensa a validadores y delegadores

### 5. Módulo Slashing

**Parámetros de seguridad críticos**:

```json
{
  "app_state": {
    "slashing": {
      "params": {
        "signed_blocks_window": "10000",                    // Ventana de bloques monitoreados
        "min_signed_per_window": "0.050000000000000000",   // 5% mínimo firmado
        "downtime_jail_duration": "600s",                  // 10 minutos de jail por downtime
        "slash_fraction_double_sign": "0.050000000000000000", // 5% slash por double sign
        "slash_fraction_downtime": "0.000100000000000000"  // 0.01% slash por downtime
      }
    }
  }
}
```

**⚠️ PARÁMETROS DE SEGURIDAD**:
- `slash_fraction_double_sign`: Penalización por firmar dos bloques en la misma altura
- `slash_fraction_downtime`: Penalización por estar offline
- `downtime_jail_duration`: Tiempo que un validador queda en jail
- Ajusta estos valores según tu política de seguridad

---

## Configuración de Módulos Específicos de Infinite Drive

### 1. Módulo EVM (vm)

**Configuración esencial**:

```json
{
  "app_state": {
    "evm": {
      "params": {
        "evm_denom": "drop",                    // DEBE coincidir con base denom
        "enable_create": true,                  // Permite crear contratos
        "enable_call": true,                     // Permite llamar contratos
        "chain_config": {
          "chain_id": "421018",                  // EVM Chain ID como string
          "homestead_block": "0",
          "dao_fork_support": false,
          "eip150_block": "0",
          "eip155_block": "0",
          "eip158_block": "0",
          "byzantium_block": "0",
          "constantinople_block": "0",
          "petersburg_block": "0",
          "istanbul_block": "0",
          "muir_glacier_block": "0",
          "berlin_block": "0",
          "london_block": "0",
          "arrow_glacier_block": "0",
          "gray_glacier_block": "0",
          "merge_netsplit_block": "0",
          "shanghai_time": "0",
          "cancun_time": "0"
        },
        "active_static_precompiles": [
          "0x0000000000000000000000000000000000000100",  // ECRecover
          "0x0000000000000000000000000000000000000400",  // SHA256
          "0x0000000000000000000000000000000000000800",  // Bank precompile
          "0x0000000000000000000000000000000000000801",  // Staking precompile
          "0x0000000000000000000000000000000000000802",  // Distribution precompile
          "0x0000000000000000000000000000000000000803",  // Governance precompile
          "0x0000000000000000000000000000000000000804",  // ERC20 precompile
          "0x0000000000000000000000000000000000000805",  // IBC precompile
          "0x0000000000000000000000000000000000000806",  // Slashing precompile
          "0x0000000000000000000000000000000000000807"   // Precision Bank precompile
        ]
      },
      "accounts": [],                              // Contratos preinstalados (si los hay)
      "preinstalls": []                            // Precompiles dinámicos
    }
  }
}
```

**Consideraciones**:
- `evm_denom` DEBE ser exactamente igual al `bond_denom` de staking
- Los precompiles activos definen qué funcionalidades Cosmos están disponibles desde EVM
- `chain_config` define la versión de EVM (debería ser compatible con Berlin/London)

### 2. Módulo ERC20

**Configuración**:
```json
{
  "app_state": {
    "erc20": {
      "params": {
        "enable_erc20": true,                     // Habilita conversión ERC20 <-> Cosmos
        "enable_evm_hook": true                   // Habilita hooks EVM
      },
      "token_pairs": [],                          // Pares de tokens iniciales
      "native_precompiles": [
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"  // Dirección nativa ETH
      ],
      "dynamic_precompiles": []                   // Precompiles dinámicos
    }
  }
}
```

**Consideraciones**:
- `native_precompiles` incluye la dirección especial para representar el token nativo en EVM
- `token_pairs` se pueden agregar después vía governance si es necesario

### 3. Módulo Fee Market

**Configuración**:
```json
{
  "app_state": {
    "feemarket": {
      "params": {
        "base_fee": "0",                         // Base fee inicial (0 = sin base fee)
        "learning_rate": "0.125000000000000000",  // Tasa de aprendizaje
        "max_priority_price": "0",                // Precio máximo de prioridad
        "min_base_fee": "0",                     // Base fee mínimo
        "min_gas_multiplier": "0.500000000000000000",  // Multiplicador mínimo
        "no_base_fee": true                      // Si true, no hay base fee dinámico
      },
      "block_gas": "0"
    }
  }
}
```

**Consideraciones**:
- Si `no_base_fee: true`, no habrá EIP-1559 style fee market
- Para producción, puedes querer habilitar base fee dinámico (`no_base_fee: false`)
- Esto afecta cómo se calculan las comisiones de gas

### 4. Módulo Precision Bank

Este módulo se configura automáticamente pero puede tener parámetros específicos según tu setup.

---

## Parámetros de Consenso (CometBFT/Tendermint)

### 1. Parámetros de Bloque

```json
{
  "consensus_params": {
    "block": {
      "max_bytes": "22020096",                   // ~21MB max por bloque
      "max_gas": "10000000",                     // 10M gas por bloque
      "time_iota_ms": "1000"                     // Precisión de tiempo
    }
  }
}
```

**Consideraciones de producción**:
- `max_gas`: Ajusta según capacidad de procesamiento esperada
- `max_bytes`: Más alto = más transacciones pero más carga de red
- En desarrollo se usan valores más bajos para bloques más rápidos

### 2. Evidencias

```json
{
  "consensus_params": {
    "evidence": {
      "max_age_num_blocks": "100000",           // Edad máxima en bloques
      "max_age_duration": "172800000000000",    // Edad máxima en nanosegundos
      "max_bytes": "1048576"                     // Máximo tamaño de evidencia
    }
  }
}
```

### 3. Validadores

```json
{
  "consensus_params": {
    "validator": {
      "pub_key_types": ["ed25519"]              // Tipo de clave de validación
    }
  }
}
```

---

## Configuración de Validadores Iniciales

### ⚠️ IMPORTANTE: Sin Validadores Existentes

Como estás creando una Mainnet sin validadores previos, debes:

1. **No incluir validadores en el génesis inicial**:
   - No uses `genesis gentx` para agregar transacciones de validadores al génesis
   - El génesis debe ser "limpio" sin validadores activos

2. **O crear validadores iniciales a través del proceso de lanzamiento**:
   - Los validadores iniciales deben ser creados **después** del lanzamiento del génesis
   - Usa una transacción `create-validator` en el primer bloque o vía governance

3. **Estructura esperada**:
```json
{
  "app_state": {
    "staking": {
      "validators": [],                          // Vacío inicialmente
      "delegations": [],                         // Vacío inicialmente
      "unbonding_delegations": [],
      "redelegations": []
    }
  }
}
```

**Alternativa: Génesis con Validadores Iniciales**

Si necesitas validadores desde el bloque 0:

```bash
# Para cada validador inicial:
# 1. Cada operador debe generar sus claves
infinited keys add validator --keyring-backend file

# 2. Cada operador crea su gentx
infinited genesis gentx validator \
  --amount 1000000000000000000000drop \
  --commission-rate "0.10" \
  --commission-max-rate "0.20" \
  --commission-max-change-rate "0.01" \
  --min-self-delegation "1" \
  --chain-id infinite_421018-1

# 3. Recolectar todos los gentxs
infinited genesis collect-gentxs
```

**Parámetros de validadores**:
- `commission-rate`: Comisión inicial (ej: 10%)
- `commission-max-rate`: Máximo permitido (ej: 20%)
- `commission-max-change-rate`: Máximo cambio por vez (ej: 1%)
- `min-self-delegation`: Mínimo que el validador debe auto-delegarse

---

## Configuración de Cuentas y Balances

### 1. Cuentas Iniciales

Debes definir qué cuentas tendrán balances iniciales:

```json
{
  "app_state": {
    "auth": {
      "accounts": [
        {
          "@type": "/cosmos.auth.v1beta1.BaseAccount",
          "address": "infinite1...",
          "pub_key": null,
          "account_number": "0",
          "sequence": "0"
        }
      ]
    },
    "bank": {
      "balances": [
        {
          "address": "infinite1...",
          "coins": [
            {
              "denom": "drop",
              "amount": "1000000000000000000000000"  // 1M TEA
            }
          ]
        }
      ],
      "supply": [
        {
          "denom": "drop",
          "amount": "10000000000000000000000000"     // Suma total
        }
      ]
    }
  }
}
```

**Consideraciones críticas**:
- El `supply` total DEBE igualar la suma de todos los `balances`
- Incluye la cuenta `bonded_tokens_pool` si hay tokens stakeados inicialmente
- Solo incluye cuentas que realmente necesitan fondos iniciales
- **NO uses cuentas de prueba/dummy** como en desarrollo

### 2. Distribución Inicial de Tokens

Debes decidir:
- **Cómo distribuir tokens iniciales**: Airdrops, ventas, treasury, validadores iniciales, etc.
- **Total supply inicial**: Cuántos tokens crear desde el inicio
- **Reservas para desarrollo**: Fondos para desarrollo futuro (governance control)

### 3. Cuentas de Módulos

Cuentas automáticas del sistema (no necesitas agregarlas manualmente):
- `bonded_tokens_pool`: Para tokens stakeados
- `not_bonded_tokens_pool`: Para tokens en unbonding
- `evm`: Para el módulo EVM
- `erc20`: Para el módulo ERC20
- Y otros módulos según sea necesario

---

## Seguridad y Parámetros Económicos

### 1. Parámetros de Gas

```json
{
  "app_state": {
    "evm": {
      "params": {
        // ... otros parámetros ...
      }
    }
  }
}
```

**Consideraciones**:
- Define `minimum-gas-prices` en `app.toml` de cada nodo (no en génesis)
- Los precompiles tienen costos de gas configurados internamente

### 2. Límites y Seguridad

- **Max gas por bloque**: Ya configurado en `consensus_params`
- **Tiempos de unbonding**: Ya configurado en `staking.params`
- **Slashing parameters**: Ya configurados en `slashing.params`

### 3. Inflación y Economía

- Configurada en `mint.params`
- Decide si quieres inflación desde el inicio o empezar con 0

---

## Verificación del Génesis

### Comando de Validación

```bash
infinited genesis validate-genesis --home /ruta/a/config
```

Este comando verifica:
- ✅ Consistencia de denoms
- ✅ Validación de parámetros
- ✅ Estructura JSON correcta
- ✅ Sumas de balances vs supply

### Checklist Manual

Antes de lanzar, verifica:

- [ ] Todos los denoms son consistentes (`bond_denom`, `evm_denom`, `mint_denom`)
- [ ] El `supply` total iguala la suma de `balances`
- [ ] Chain IDs (Cosmos y EVM) están correctamente configurados
- [ ] Parámetros de governance son realistas (NO copiar períodos de 30s de dev)
- [ ] Parámetros de slashing son apropiados para producción
- [ ] No hay cuentas dummy o de prueba
- [ ] Los precompiles necesarios están habilitados
- [ ] Metadata del token está completa y correcta
- [ ] Los períodos de votación son apropiados (días, no segundos)
- [ ] Validadores iniciales (si los hay) están correctamente configurados

---

## Proceso Recomendado de Creación

### Paso 1: Preparación

```bash
# 1. Inicializar estructura básica
infinited init my-moniker --chain-id infinite_421018-1

# Esto crea el génesis inicial en ~/.infinited/config/genesis.json
```

### Paso 2: Configurar Parámetros Básicos

Usa `jq` o edición manual para configurar todos los parámetros mencionados arriba.

### Paso 3: Agregar Cuentas Iniciales

```bash
# Para cada cuenta que necesita fondos:
infinited genesis add-genesis-account ADDRESS AMOUNTdrop \
  --keyring-backend file \
  --home /ruta/a/config
```

### Paso 4: Configurar Validadores (si aplica)

Si quieres validadores desde el bloque 0:
```bash
# Recolectar gentxs de validadores
infinited genesis collect-gentxs --home /ruta/a/config
```

Si NO quieres validadores iniciales:
- **NO ejecutes `collect-gentxs`**
- El génesis quedará sin validadores y deberán ser creados después

### Paso 5: Validar

```bash
infinited genesis validate-genesis --home /ruta/a/config
```

### Paso 6: Distribuir

El archivo `genesis.json` debe ser distribuido a TODOS los nodos de la red antes del lanzamiento.

### Arranque del nodo (siempre especificando ambos Chain IDs)

```bash
# Mainnet
infinited start \
  --chain-id infinite_421018-1 \
  --evm.evm-chain-id 421018

# Testnet
infinited start \
  --chain-id infinite_421018001-1 \
  --evm.evm-chain-id 421018001
```

---

## Diferencias Clave: Desarrollo vs Producción

| Aspecto | Desarrollo | Producción |
|---------|-----------|------------|
| Períodos de Governance | 30s (rápido) | 2 días (seguro) |
| Gas Prices | 0drop (gratis) | Valor realista |
| Cuentas Iniciales | Dummy/test | Reales/legítimas |
| Validadores | Scripts automáticos | Proceso manual seguro |
| Precompiles | Todos habilitados | Solo necesarios |
| Slashing | Valores bajos | Valores de producción |
| Metadata Token | Ejemplo | Real y completo |

---

## Recursos Adicionales

- [Cosmos SDK Genesis Documentation](https://docs.cosmos.network/main/building-modules/genesis)
- [CometBFT Genesis Documentation](https://docs.cometbft.com/v0.38/core/genesis)
- Guía de Producción: `guides/PRODUCTION_DEPLOYMENT.md`
- Archivo de ejemplo para desarrollo: `local_node.sh` (líneas 233-256)

---

**Nota Final**: Este documento se basa en el análisis del código fuente de Infinite Drive. Siempre verifica que estos parámetros sean apropiados para tu caso de uso específico y considera realizar auditorías de seguridad antes del lanzamiento de Mainnet.

