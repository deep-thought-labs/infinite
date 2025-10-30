# Comparación Mainnet vs Testnet - Configuraciones Genesis

Este documento compara las configuraciones entre `mainnet.yaml` y `testnet.yaml` para asegurar que cada red tenga los valores apropiados para su contexto.

---

## Resumen de Diferencias Clave

| Aspecto | Mainnet | Testnet | Justificación |
|---------|---------|---------|---------------|
| **Chain ID (Cosmos)** | `infinite_421018-1` | `infinite_421018001-1` | Mismo origen agregando 001 |
| **Chain ID (EVM)** | `421018` | `421018001` | Variante derivada del mainnet agregando 001 |
| **Governance Periods** | 2 días | 1 hora | Mainnet: seguridad, Testnet: velocidad |
| **Unbonding Time** | 21 días | 1 día | Mainnet: seguridad, Testnet: agilidad |
| **Jail Duration** | 10 minutos | 1 minuto | Mainnet: penalización real, Testnet: rápida recuperación |
| **Min Deposit** | 1 TEA | 0.1 TEA | Mainnet: anti-spam, Testnet: fácil testing |
| **Gas Prices** | Realistas | Casi gratis | Mainnet: incentivos, Testnet: sin barreras |

---

## Análisis Detallado por Sección

### 1. Chain Identification

#### Mainnet
```yaml
chain:
  cosmos_chain_id: "infinite_421018-1"  # ID único para mainnet
  evm_chain_id: "421018"                # EVM Chain ID para mainnet
  bech32_prefix: "infinite"             # Prefijo Bech32 estándar
```

#### Testnet
```yaml
chain:
  cosmos_chain_id: "infinite_421018001-1" # ID derivado del mainnet agregando 001
  evm_chain_id: "421018001"               # EVM Chain ID derivado del mainnet agregando 001
  bech32_prefix: "infinitetest"           # Prefijo diferenciado para testnet
```

**✅ Correcto**: IDs únicos para evitar conflictos entre redes.

---

### 2. Denominations

#### Mainnet
```yaml
denom:
  base: "drop"      # Denominación base (18 decimales)
  display: "TEA"    # Denominación de display
  decimals: 18      # Precisión estándar (compatible con Ethereum)
```

#### Testnet
```yaml
denom:
  base: "drop"        # Denominación base igual (compatibilidad técnica)
  display: "TEA-test"  # Denominación de display diferenciada para testnet
  decimals: 18
```

**✅ Correcto**: Misma base para compatibilidad, display diferenciado para evitar confusión.

---

### 3. Token Metadata

#### Mainnet
```yaml
token_metadata:
  name: "Improbability"
  symbol: "TEA"
  description: "Improbability (TEA) powers the Infinite Improbability Drive. Runs on tea. Properly prepared. Native to Infinite. Don't panic."
```

#### Testnet
```yaml
token_metadata:
  name: "Improbability test"
  symbol: "TEA-test"
  description: "Improbability (TEA) powers the Infinite Improbability Drive. Runs on tea. Properly prepared. Native to Infinite. Don't panic. (testnet)"
```

**✅ Correcto**: Testnet claramente identificado (display y símbolo diferenciados).

---

### 4. Staking Configuration

#### Mainnet
```yaml
staking:
  bond_denom: "drop"
  max_validators: 100                    # Límite estándar para mainnet
  historical_entries: 10000              # Historial completo
  max_entries: 7                         # Límite estándar de delegaciones
  min_commission_rate: "0.000000000000000000"  # Sin comisión mínima
  unbonding_time: "1814400s"             # 21 días (seguridad)
```

#### Testnet
```yaml
staking:
  bond_denom: "drop"
  max_validators: 100                    # Mismo límite (consistencia)
  historical_entries: 10000              # Mismo historial (consistencia)
  max_entries: 7                         # Mismo límite (consistencia)
  min_commission_rate: "0.000000000000000000"  # Sin comisión mínima
  unbonding_time: "86400s"               # 1 día (agilidad para testing)
```

**✅ Correcto**: Mainnet con unbonding más largo para seguridad, testnet más rápido para testing.

---

### 5. Governance Configuration

#### Mainnet (Valores de Producción)
```yaml
governance:
  min_deposit:
    denom: "drop"
    amount: "1000000000000000000"        # 1 TEA (anti-spam)
  max_deposit_period: "172800s"          # 2 días (tiempo para revisión)
  voting_period: "172800s"               # 2 días (tiempo para participación)
  quorum: "0.334000000000000000"         # 33.4% (estándar Cosmos)
  threshold: "0.500000000000000000"      # 50% (mayoría simple)
  veto_threshold: "0.334000000000000000" # 33.4% (poder de veto)
  expedited_min_deposit:
    denom: "drop"
    amount: "5000000000000000000"        # 5 TEA (propuestas urgentes)
  expedited_voting_period: "86400s"      # 1 día (propuestas urgentes)
```

#### Testnet (Valores de Testing)
```yaml
governance:
  min_deposit:
    denom: "drop"
    amount: "100000000000000000"         # 0.1 TEA (fácil testing)
  max_deposit_period: "3600s"            # 1 hora (testing rápido)
  voting_period: "3600s"                 # 1 hora (testing rápido)
  quorum: "0.334000000000000000"         # 33.4% (mismo estándar)
  threshold: "0.500000000000000000"      # 50% (mismo estándar)
  veto_threshold: "0.334000000000000000" # 33.4% (mismo estándar)
  expedited_min_deposit:
    denom: "drop"
    amount: "500000000000000000"         # 0.5 TEA (testing fácil)
  expedited_voting_period: "1800s"       # 30 minutos (testing rápido)
```

**✅ Correcto**: 
- Mainnet: Períodos largos para seguridad y participación
- Testnet: Períodos cortos para testing rápido
- Depósitos menores en testnet para facilitar testing

---

### 6. Mint Configuration (Inflación)

#### Ambas redes (idénticas - inflación moderada)
```yaml
mint:
  mint_denom: "drop"
  inflation_rate_change: "0.130000000000000000"  # 13% cambio anual
  inflation_max: "0.200000000000000000"          # 20% máximo anual
  inflation_min: "0.070000000000000000"          # 7% mínimo anual
  goal_bonded: "0.670000000000000000"            # 67% objetivo de staking
  blocks_per_year: "6311520"                     # ~6.3M bloques/año
```

**✅ Correcto**: Inflación moderada que incentiva staking sin ser excesiva.

**Análisis de inflación**:
- **7-20% anual**: Rango saludable para incentivar validadores
- **67% objetivo**: Incentiva staking sin ser excesivo
- **13% cambio**: Ajuste gradual basado en staking ratio

---

### 7. Slashing Configuration

#### Mainnet (Penalizaciones Reales)
```yaml
slashing:
  signed_blocks_window: "10000"                  # 10,000 bloques de ventana
  min_signed_per_window: "0.050000000000000000"  # 5% mínimo de firma
  downtime_jail_duration: "600s"                 # 10 minutos de jail
  slash_fraction_double_sign: "0.050000000000000000"  # 5% slash por double sign
  slash_fraction_downtime: "0.000100000000000000"     # 0.01% slash por downtime
```

#### Testnet (Penalizaciones Suaves)
```yaml
slashing:
  signed_blocks_window: "10000"                  # Misma ventana (consistencia)
  min_signed_per_window: "0.050000000000000000"  # Mismo mínimo (consistencia)
  downtime_jail_duration: "60s"                  # 1 minuto de jail (recuperación rápida)
  slash_fraction_double_sign: "0.050000000000000000"  # Mismo slash (consistencia)
  slash_fraction_downtime: "0.000100000000000000"     # Mismo slash (consistencia)
```

**✅ Correcto**: 
- Mainnet: Jail de 10 minutos (penalización real)
- Testnet: Jail de 1 minuto (recuperación rápida para testing)
- Slash fractions idénticas (consistencia en penalizaciones)

---

### 8. EVM Configuration

#### Mainnet
```yaml
evm:
  evm_denom: "drop"
  chain_id: "421018"                    # EVM Chain ID para mainnet
  active_static_precompiles: [...]      # Precompiles estándar
```

#### Testnet
```yaml
evm:
  evm_denom: "drop"
  chain_id: "421018001"                 # EVM Chain ID para testnet (derivado del mainnet)
  active_static_precompiles: [...]      # Mismos precompiles (consistencia)
```

**✅ Correcto**: Chain IDs diferentes, precompiles idénticos.

---

### 9. ERC20 Configuration

#### Ambas redes (idénticas)
```yaml
erc20:
  token_pairs: []                       # Vacío por defecto (configurar según necesidad)
  native_precompiles: []                # Vacío por defecto (configurar según necesidad)
  enable_erc20: true                    # ERC20 habilitado
  permissionless_registration: true     # Registro sin permisos
```

**✅ Correcto**: Configuración base idéntica, personalizable según necesidad.

---

### 10. FeeMarket Configuration

#### Ambas redes (idénticas)
```yaml
feemarket:
  no_base_fee: true                     # Sin base fee (gas price = 0)
  base_fee: "0"                         # Base fee = 0
  min_gas_price: "0"                    # Gas price mínimo = 0
  min_gas_multiplier: "0.500000000000000000"  # Multiplicador estándar
```

**⚠️ RECOMENDACIÓN**: Para mainnet, considerar habilitar base fee:

```yaml
# Para mainnet (recomendado):
feemarket:
  no_base_fee: false                    # Habilitar base fee
  base_fee: "1000000000"                # 1e9 drop (0.000000001 TEA) base fee
  min_gas_price: "1000000000"           # 1e9 drop (0.000000001 TEA) gas price mínimo
  min_gas_multiplier: "0.500000000000000000"
```

---

### 11. Consensus Parameters

#### Ambas redes (idénticas)
```yaml
consensus:
  block:
    max_bytes: "22020096"               # ~21MB (límite estándar)
    max_gas: "10000000"                 # 10M gas (límite estándar)
    time_iota_ms: "1000"                # 1 segundo entre bloques
  evidence:
    max_age_num_blocks: "100000"        # 100K bloques de evidencia
    max_age_duration: "172800000000000" # 2 días en nanosegundos
    max_bytes: "1048576"                # 1MB máximo de evidencia
```

**✅ Correcto**: Parámetros de consenso idénticos (consistencia de red).

---

## Recomendaciones de Mejora

### 1. FeeMarket para Mainnet
```yaml
# En mainnet.yaml, cambiar:
feemarket:
  no_base_fee: false                    # Habilitar base fee
  base_fee: "1000000000"                # 1e9 drop (0.000000001 TEA) - incentivo para validadores
  min_gas_price: "1000000000"           # 1e9 drop (0.000000001 TEA) mínimo
  min_gas_multiplier: "0.500000000000000000"
```

### 2. Gas Prices en app.toml
Para mainnet, configurar en `app.toml`:
```toml
minimum-gas-prices = "1000000000drop"  # 1e9 drop (0.000000001 TEA)
```

Para testnet:
```toml
minimum-gas-prices = "0drop"           # Gratis
```

### 3. Validación de Configuraciones
Agregar validación en el script para verificar:
- Períodos de governance apropiados
- Gas prices apropiados para cada red
- Inflación configurada correctamente

---

## Checklist de Validación

### Mainnet
- [ ] Períodos de governance largos (2 días)
- [ ] Unbonding time largo (21 días)
- [ ] Depósitos mínimos altos (anti-spam)
- [ ] Gas prices realistas (incentivos)
- [ ] Jail duration apropiada (10 min)

### Testnet
- [ ] Períodos de governance cortos (1 hora)
- [ ] Unbonding time corto (1 día)
- [ ] Depósitos mínimos bajos (fácil testing)
- [ ] Gas prices bajos (sin barreras)
- [ ] Jail duration corta (1 min)

### Ambas
- [ ] Inflación configurada (7-20%)
- [ ] Chain IDs únicos
- [ ] Denominaciones consistentes
- [ ] Precompiles habilitados
- [ ] Parámetros de consenso idénticos

---

## Conclusión

Las configuraciones están bien diferenciadas entre mainnet y testnet, con valores apropiados para cada contexto:

- **Mainnet**: Valores conservadores, seguros, con incentivos económicos reales
- **Testnet**: Valores ágiles, fáciles de probar, con barreras mínimas

La única mejora recomendada es habilitar base fee en mainnet para incentivar validadores con gas fees reales.
