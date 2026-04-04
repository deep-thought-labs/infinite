# Hyperlane en Infinite Drive — operación (contexto)

Complemento de [INTEGRATION.md](INTEGRATION.md), que cubre **el código**. Aquí va orientación **operativa y de producto**: qué deja hecho el repo, qué sigue siendo trabajo **on-chain** (y algo off-chain), y por qué **Cosmos** y **EVM** tienen el **mismo peso** en el plan — son dos frentes distintos, no uno opcional colgado del otro.

## Qué ya cubre el código

En `infinited`, `x/core` y `x/warp` preparan la **pista Cosmos SDK**: módulos, estado y upgrade de stores para que Hyperlane pueda existir on-chain **cuando** se ejecuten los despliegues y la configuración de red. Eso **no** reemplaza esos despliegues ni el registro en el ecosistema Hyperlane.

## Dos pistas, dos frentes (Cosmos y EVM)

Infinite es **dual** (Cosmos + `x/vm`). En Hyperlane, **Cosmos-native** y **EVM** se tratan por separado: cada uno implica su propio despliegue, sus credenciales y, en la práctica, su presencia en registry y en la operación de relayers.

| | **Cosmos (SDK)** | **EVM (`x/vm`)** |
|---|---|---|
| **Objetivo** | Mensajes y Warp en el mundo SDK (cuentas bech32, denoms nativos). | Mensajes y activos como contratos; experiencia tipo wallet EVM y dApps. |
| **Qué queda por hacer (a grandes rasgos)** | Despliegue “core” nativo, metadata de cadena en registry, rutas Warp donde hagan falta — alineado con la [guía Cosmos](https://docs.hyperlane.xyz/docs/guides/chains/deploy-hyperlane-cosmos). | Despliegue con el [flujo EVM](https://docs.hyperlane.xyz/docs/guides/chains/deploy-hyperlane): **no** es repetir mecánicamente el mismo checklist que en Cosmos. |
| **Por qué importa** | Es la pista que este repo ya **cablea en Go**. | Es la pista para quien usa la capa **Solidity / JSON-RPC** de la misma cadena. |

Mientras no estén cubiertas las dos (si el producto quiere **las dos** experiencias), no hay que dar por cerrado que la cadena esté “enchufada” al ecosistema Hyperlane solo porque el binario compila.

## Relayers (idea general)

Un **relayer** es el agente **off-chain** que **observa** mensajes en la cadena de origen y los **entrega** en la de destino. Sin relayers que cubran tus rutas, los mensajes se **quedan atascados** aunque Mailbox e ISM ya estén desplegados.

- **Relayers públicos de Hyperlane** suelen cubrir cadenas ya integradas; cómodos al inicio o en testnet, pero **cadenas nuevas o muy custom** pueden no entrar de inmediato o ir con menos prioridad.
- **Relayer propio** (binario oficial, configuración con tus chains, RPC/gRPC en Cosmos, JSON-RPC en EVM, claves para gas en destino, rutas que quieres atender) es lo habitual cuando buscas **producción seria**, baja latencia o rutas que el operador público no cubre.
- **Combinar** ambos es lo más frecuente: rutas amplias vía red pública y **tu relayer** para Infinite Cosmos + Infinite EVM como entradas claras.

En una red dual, conviene asumir que hace falta pensar **las dos superficies** (Cosmos y EVM) en la configuración del relayer. Temas como **IGP** (gas del relayer pagado por quien envía), registry y Warp routes los detalla la documentación oficial; **validators** y endurecimiento de seguridad son un escalón aparte.

## Modelos de seguridad (ISM) — solo una noción

En destino, un **ISM** (Interchain Security Module) es quien responde, en esencia: **¿este mensaje viene legítimamente del origen?** Hyperlane permite varios **esquemas** (por ejemplo multisig, agregación de varios ISM, enrutado por origen, optimistic, default del protocolo) y combinarlos según equilibrio **velocidad / confianza**.

**No es el foco de esta carpeta** profundizar en ISM; sí ayuda saber que al cerrar **core deploy** (en **cada** pista, Cosmos y EVM por separado) se está eligiendo **cómo** se validan los mensajes, y eso afecta la confianza del bridging vía Warp. La doc de Hyperlane es la referencia para diseño fino.

## Referencias

- [Deploy Hyperlane — Cosmos SDK](https://docs.hyperlane.xyz/docs/guides/chains/deploy-hyperlane-cosmos)
- [Deploy Hyperlane — cadenas EVM](https://docs.hyperlane.xyz/docs/guides/chains/deploy-hyperlane)
- [Hyperlane — módulo Cosmos (conceptos)](https://docs.hyperlane.xyz/docs/alt-vm-implementations/cosmos-sdk)
- Código y checklist: [INTEGRATION.md](INTEGRATION.md)
- Bitácora de integración en repo: [logs/2026-04-03-hyperlane-integration.md](../../fork-maintenance/logs/2026-04-03-hyperlane-integration.md)
