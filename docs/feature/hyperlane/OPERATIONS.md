# Hyperlane on Infinite Drive — operations (context)

Companion to [INTEGRATION.md](INTEGRATION.md), which covers **the code**. This page is **operational / product** context: what the repository already provides, what remains **on-chain** (and some off-chain), and why **Cosmos** and **EVM** carry **equal weight** in the plan — they are two separate fronts, not an optional add-on to the other.

## What the code already covers

In `infinited`, `x/core` and `x/warp` set up the **Cosmos SDK track**: modules, state, and store upgrades so Hyperlane can exist on-chain **once** deployments and network configuration are done. That **does not** replace those deployments or registration in the Hyperlane ecosystem.

## Two tracks, two fronts (Cosmos and EVM)

Infinite is **dual** (Cosmos + `x/vm`). In Hyperlane, **Cosmos-native** and **EVM** are handled **separately**: each implies its own deployment, credentials, and — in practice — presence in the registry and in relayer operations.

| | **Cosmos (SDK)** | **EVM (`x/vm`)** |
|---|---|---|
| **Goal** | Messages and Warp in the SDK world (bech32 accounts, native denoms). | Messages and assets as contracts; EVM-wallet-style UX and dApps. |
| **Roughly what is still to do** | Native “core” deployment, chain metadata in the registry, Warp routes as needed — aligned with the [Cosmos guide](https://docs.hyperlane.xyz/docs/guides/chains/deploy-hyperlane-cosmos). | Deployment via the [EVM flow](https://docs.hyperlane.xyz/docs/guides/chains/deploy-hyperlane): **not** a mechanical copy of the Cosmos checklist. |
| **Why it matters** | This is the track **wired in Go** in this repo. | This is the track for the chain’s **Solidity / JSON-RPC** layer. |

Until both are covered (if the product wants **both** experiences), do not treat the chain as fully “plugged into” Hyperlane just because the binary builds.

## Relayers (overview)

A **relayer** is the **off-chain** agent that **observes** messages on the source chain and **delivers** them on the destination. Without relayers covering your routes, messages **stall** even if Mailbox and ISM are deployed.

- **Hyperlane’s public relayers** often cover chains that are already integrated; handy early on or on testnet, but **new or highly custom** chains may not be included immediately or may get lower priority.
- **Running your own relayer** (official binary, config for your chains, RPC/gRPC on Cosmos, JSON-RPC on EVM, keys for gas on destination, routes you care about) is the usual path for **serious production**, lower latency, or routes public operators do not cover.
- **Combining** both is common: broad routes via the public network and **your relayer** with explicit entries for Infinite Cosmos + Infinite EVM.

On a dual network, assume you must account for **both surfaces** (Cosmos and EVM) in relayer configuration. **IGP** (sender pays relayer gas), registry, and Warp routes are spelled out in the official documentation; **validators** and stronger security hardening are a separate step up.

## Security models (ISM) — orientation only

On the destination, an **ISM** (Interchain Security Module) essentially answers: **did this message legitimately come from the source?** Hyperlane supports several **schemes** (e.g. multisig, aggregation of ISMs, routing by origin, optimistic, protocol default) and combinations trading off **speed vs. trust**.

**This folder does not deep-dive ISMs**; it helps to know that **core deploy** (on **each** track — Cosmos and EVM separately) chooses **how** messages are validated, which affects trust in Warp bridging. Hyperlane’s docs are the place for detailed design.

## References

- [Deploy Hyperlane — Cosmos SDK](https://docs.hyperlane.xyz/docs/guides/chains/deploy-hyperlane-cosmos)
- [Deploy Hyperlane — EVM chains](https://docs.hyperlane.xyz/docs/guides/chains/deploy-hyperlane)
- [Hyperlane — Cosmos module (concepts)](https://docs.hyperlane.xyz/docs/alt-vm-implementations/cosmos-sdk)
- Code and checklist: [INTEGRATION.md](INTEGRATION.md)
- Repository integration log: [logs/2026-04-03-hyperlane-integration.md](../../fork-maintenance/logs/2026-04-03-hyperlane-integration.md)
