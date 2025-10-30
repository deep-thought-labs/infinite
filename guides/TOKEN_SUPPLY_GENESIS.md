# Token Supply en el Genesis - ¿De dónde vienen los tokens?

## La Pregunta Clave

> **¿De dónde salen los tokens que se asignan a las cuentas en el Genesis?**

---

## Respuesta: Los tokens se "crean de la nada" en el Genesis

### ✅ **Los tokens NO vienen de ningún lugar previo**

En el Genesis, los tokens se crean **ex nihilo** (de la nada). No hay un "banco central" previo ni una fuente externa.

### Cómo funciona:

1. **`infinited init`** crea un Genesis **vacío** (sin supply, sin balances)
2. **`infinited genesis add-genesis-account`** agrega cuentas con tokens
3. **El comando automáticamente actualiza el `supply` total**

---

## Ejemplo Práctico

### Paso 1: Genesis inicial (vacío)
```json
{
  "app_state": {
    "bank": {
      "supply": [],           // ← Vacío
      "balances": []          // ← Vacío
    }
  }
}
```

### Paso 2: Agregar cuenta con tokens
```bash
infinited genesis add-genesis-account validator-1 1000000000000000000000drop
```

### Paso 3: Genesis actualizado automáticamente
```json
{
  "app_state": {
    "bank": {
      "supply": [
        {
          "denom": "drop",
          "amount": "1000000000000000000000"  // ← Creado automáticamente
        }
      ],
      "balances": [
        {
          "address": "infinite1...",
          "coins": [
            {
              "denom": "drop",
              "amount": "1000000000000000000000"  // ← Asignado a la cuenta
            }
          ]
        }
      ]
    }
  }
}
```

---

## ¿Cómo funciona internamente?

### 1. `add-genesis-account` hace dos cosas:

1. **Agrega la cuenta** a `app_state.auth.accounts`
2. **Agrega el balance** a `app_state.bank.balances`
3. **Actualiza el supply** en `app_state.bank.supply`

### 2. El supply se calcula automáticamente:

```go
// Pseudocódigo de lo que hace add-genesis-account
func addGenesisAccount(address, amount) {
    // 1. Agregar cuenta
    genesis.Auth.Accounts = append(genesis.Auth.Accounts, newAccount(address))
    
    // 2. Agregar balance
    genesis.Bank.Balances = append(genesis.Bank.Balances, Balance{
        Address: address,
        Coins:   []Coin{{Denom: "drop", Amount: amount}}
    })
    
    // 3. Actualizar supply total
    genesis.Bank.Supply = calculateTotalSupply(genesis.Bank.Balances)
}
```

---

## Reglas del Supply

### ✅ **Regla Fundamental**: `supply = suma de todos los balances`

```json
{
  "supply": [
    {"denom": "drop", "amount": "5000000000000000000000"}  // Total
  ],
  "balances": [
    {"address": "addr1", "coins": [{"denom": "drop", "amount": "2000000000000000000000"}]},
    {"address": "addr2", "coins": [{"denom": "drop", "amount": "3000000000000000000000"}]}
  ]
}
// 2000 + 3000 = 5000 ✓
```

### ❌ **Error común**: Supply ≠ suma de balances
Si esto ocurre, `infinited genesis validate-genesis` fallará.

---

## Proceso Completo para Validadores

### 1. Crear cuenta del validador
```bash
infinited keys add validator-1 --keyring-backend file
```

### 2. Agregar cuenta con fondos (crea tokens de la nada)
```bash
infinited genesis add-genesis-account validator-1 1000000000000000000000drop
# ↑ Esto crea 1000 TEA de la nada y los asigna a validator-1
```

### 3. Crear gentx (usa los tokens existentes)
```bash
infinited genesis gentx validator-1 1000000000000000000000drop \
  --chain-id infinite_421018-1
# ↑ Esto usa los 1000 TEA que ya tiene validator-1 para staking
```

### 4. Recolectar gentxs
```bash
infinited genesis collect-gentxs
# ↑ Esto agrega el validador al Genesis usando los tokens ya asignados
```

---

## ¿Cuántos tokens crear inicialmente?

### Para Mainnet (ejemplo):

```bash
# Cuenta principal del equipo (para operaciones)
infinited genesis add-genesis-account team-wallet 10000000000000000000000000drop  # 10M TEA

# Validador 1
infinited genesis add-genesis-account validator-1 1000000000000000000000000drop   # 1M TEA

# Validador 2  
infinited genesis add-genesis-account validator-2 1000000000000000000000000drop   # 1M TEA

# Validador 3
infinited genesis add-genesis-account validator-3 1000000000000000000000000drop   # 1M TEA

# Total supply: 13M TEA
```

### Para Testnet (ejemplo):

```bash
# Cuentas de prueba (más generosas)
infinited genesis add-genesis-account test-account-1 100000000000000000000000000drop  # 100M TEA
infinited genesis add-genesis-account test-account-2 100000000000000000000000000drop  # 100M TEA
infinited genesis add-genesis-account validator-1 10000000000000000000000000drop     # 10M TEA
```

---

## Consideraciones Importantes

### 1. **No hay inflación inicial**
- Los tokens se crean una sola vez en el Genesis
- Después, solo hay inflación si está configurada en el módulo `mint`

### 2. **Distribución inicial**
- Decide cuidadosamente quién recibe cuántos tokens
- Los tokens del Genesis son los únicos que existirán inicialmente

### 3. **Validadores necesitan tokens para staking**
- Un validador debe tener tokens para hacer `gentx`
- Los tokens se "queman" (van al módulo de staking) durante el `gentx`

### 4. **Supply total debe ser realista**
- No crees demasiados tokens (inflación futura)
- No crees muy pocos (liquidez insuficiente)

---

## Comandos Útiles

### Ver supply actual:
```bash
jq '.app_state.bank.supply' genesis.json
```

### Ver balances:
```bash
jq '.app_state.bank.balances' genesis.json
```

### Verificar que supply = suma de balances:
```bash
# Sumar todos los balances
jq '[.app_state.bank.balances[].coins[] | select(.denom=="drop") | .amount | tonumber] | add' genesis.json

# Comparar con supply
jq '.app_state.bank.supply[] | select(.denom=="drop") | .amount | tonumber' genesis.json
```

### Contar cuentas:
```bash
jq '.app_state.bank.balances | length' genesis.json
```

---

## Resumen

| Pregunta | Respuesta |
|----------|-----------|
| **¿De dónde vienen los tokens?** | Se crean de la nada en el Genesis |
| **¿Quién los crea?** | El comando `add-genesis-account` |
| **¿Cuándo se crean?** | Cuando ejecutas `add-genesis-account` |
| **¿Hay límite?** | No, pero debes ser responsable con la cantidad |
| **¿Se pueden crear después?** | Solo vía inflación (módulo mint) o nuevos módulos |

**Conclusión**: Los tokens del Genesis son la "moneda inicial" de tu blockchain. Se crean cuando los asignas a cuentas, y esa es la única forma de tener tokens desde el bloque 0.
