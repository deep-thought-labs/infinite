# Infinite Bank — integración técnica

## Alcance (Part A)

Módulo **`github.com/cosmos/evm/x/bank`** (nombre on-chain **`infinitebank`**) que registra **`MsgSetDenomMetadata`**: autoridad fija = cuenta del módulo **x/gov**; delega en el **keeper estándar** del SDK `x/bank` (`SetDenomMetaData`).

## Proto

- **`proto/cosmos/evm/bank/v1/tx.proto`** — paquete **`cosmos.evm.bank.v1`**, `go_package` **`github.com/cosmos/evm/x/bank/types`** (convención del repo y script `scripts/generate_protos.sh`).
- Código gogo generado: **`x/bank/types/tx.pb.go`** (`make proto-gen` / `buf generate` con plugins gocosmos).
- API pulsar (autocli / reflexión): **`api/cosmos/evm/bank/v1/*.go`** (`buf generate` con `buf.gen.pulsar.yaml`).

> Si el documento de diseño hablaba de `infinite.bank.v1`, en este repositorio el equivalente alineado con **buf** y **cosmos/evm** es **`cosmos.evm.bank.v1`**. El nombre de módulo Cosmos sigue siendo **`infinitebank`** para no colisionar con **`bank`** del SDK.

## Código

| Pieza | Ruta |
|--------|------|
| Tipos, codec, genesis vacío JSON | `x/bank/types/` |
| Msg server | `x/bank/keeper/msg_server.go` |
| `AppModule` | `x/bank/module.go` |
| Registro en la app | `infinited/app.go` — `sdkbank.NewAppModule` (SDK) + `bank.NewAppModule` (extensión); orden genesis / begin / end incluye `evmbanktypes.ModuleName` |

## Verificación local (desarrolladores del módulo)

```bash
make proto-gen   # o buf generate con imagen/proto-builder del Makefile
go mod tidy
cd infinited && go build -o /dev/null ./cmd/infinited
go test ./x/bank/... -count=1
```

---

## Cómo usar

Orientado a **operadores** e **integradores** que envían propuestas en una red en vivo o de pruebas.

### Qué hace

Tras aprobarse una propuesta de gobernanza que lo contiene, **`MsgSetDenomMetadata`** escribe metadatos de denominación en el estado de **`x/bank`** del SDK (misma semántica que el keeper estándar: `SetDenomMetaData`). Sirve para fijar o actualizar **nombre, símbolo, unidades (exponentes)** y campos opcionales (`uri`, `uri_hash`) de un `denom` ya existente en cadena.

### Restricciones

- **No** es una transacción que firme un usuario normal con su clave: el mensaje debe ir dentro de una **propuesta de gov** y el campo **`authority`** tiene que ser **exactamente** la cuenta del módulo **`gov`** (si no, el handler responde `ErrInvalidSigner`).
- El **`metadata`** debe cumplir la validación del SDK (`Metadata.Validate()`): por ejemplo, primera unidad = `base` con exponente `0`, orden creciente de exponentes, `display` presente en `denom_units`, `name` y `symbol` no vacíos, etc.

### Tipo protobuf (para `proposal.json`)

- **Type URL del mensaje:** `/cosmos.evm.bank.v1.MsgSetDenomMetadata`  
  (comprobado en tests: `sdk.MsgTypeURL(&MsgSetDenomMetadata{})` en `x/bank/types/typeurl_test.go`.)

### Dirección de `authority`

Obtén la cuenta del módulo gov **en la red que uses** (depende del prefijo Bech32, p. ej. `infinite` en Infinite Drive):

```bash
infinited q auth module-account gov --node <RPC>
```

Usa la dirección devuelta tal cual en el JSON del mensaje.

### Ejemplo de `proposal.json` (gov v1)

Sustituye `<GOV_MODULE_ADDRESS>`, el `deposit` (denom y cantidad mínima según `gov` de tu red) y ajusta `metadata` a un denom real de esa cadena.

```json
{
  "messages": [
    {
      "@type": "/cosmos.evm.bank.v1.MsgSetDenomMetadata",
      "authority": "<GOV_MODULE_ADDRESS>",
      "metadata": {
        "description": "Ejemplo de metadatos vía gobernanza",
        "denom_units": [
          { "denom": "drop", "exponent": 0, "aliases": [] },
          { "denom": "Improbability", "exponent": 18, "aliases": [] }
        ],
        "base": "drop",
        "display": "Improbability",
        "name": "Improbability",
        "symbol": "42",
        "uri": "",
        "uri_hash": ""
      }
    }
  ],
  "metadata": "https://ejemplo.invalid/propuesta-42",
  "deposit": "1000000000000000000drop",
  "title": "Actualizar metadata del denom",
  "summary": "Propuesta que ejecuta MsgSetDenomMetadata tras el voto."
}
```

### CLI: enviar propuesta, votar y comprobar

Desde la raíz del repo, con `infinited` compilado y apuntando al nodo y `chain-id` correctos:

```bash
# 1) Enviar la propuesta (firma el depósito quien tenga fondos)
infinited tx gov submit-proposal path/al/proposal.json \
  --from <tu_clave> \
  --chain-id <CHAIN_ID> \
  --gas auto --gas-adjustment 1.3 \
  --fees <cantidad><denom_fee>

# 2) Votar (tras abrirse la votación)
infinited tx gov vote <proposal_id> yes --from <tu_clave> --chain-id <CHAIN_ID> ...

# 3) Tras ejecutarse el mensaje, consultar metadatos en bank
infinited q bank denom-metadata <base_denom> --node <RPC>
# o listar todos:
infinited q bank denoms-metadata --node <RPC>
```

La ayuda integrada describe el formato del JSON:

```bash
infinited tx gov submit-proposal --help
```

### Simulación sin broadcast

Para validar gas y codificación sin enviar la tx:

```bash
infinited tx gov submit-proposal proposal.json --from <clave> --chain-id <CHAIN_ID> --dry-run
```

---

## Cómo probar

### Tests automáticos (rápidos)

En la raíz del repositorio `github.com/cosmos/evm`:

```bash
go test ./x/bank/... -count=1
```

Incluye al menos la comprobación del **type URL** del mensaje (`typeurl_test.go`).

### Compilación del binario

```bash
cd infinited && go build -o ./build/infinited ./cmd/infinited
```

(o los objetivos `make` que use tu flujo, p. ej. `make build-from-infinited` si aplica).

### Cadena local o de pruebas

Para un flujo **extremo a extremo** (propuesta → voto → ejecución → query), usa la misma guía que para el resto del binario: [docs/guides/development/TESTING.md](../../guides/development/TESTING.md), redes locales (`local_node.sh` / configuración de testnet del proyecto) y parámetros de **gov** acortados solo en entornos de desarrollo.

Pasos típicos:

1. Levantar nodo(s) con `infinited` que incluyan el módulo `infinitebank`.
2. Asegurar saldo y permisos para **deposit** de gov.
3. Enviar `proposal.json` como arriba, votar y verificar con `infinited q bank denom-metadata`.

### Regeneración de protos

Si cambias `proto/cosmos/evm/bank/v1/tx.proto`, vuelve a generar y a pasar tests/build:

```bash
make proto-gen
go test ./x/bank/... -count=1
cd infinited && go build ./cmd/infinited
```

---

## Notas para merges upstream

Revisar `infinited/app.go` (orden de módulos, imports `sdkbank` vs `bank`), `x/bank/**` y regeneración de protos.
