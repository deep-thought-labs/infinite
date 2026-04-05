# Documentación técnica (`docs/`)

| Carpeta | Contenido |
|---------|-----------|
| [**guides/**](guides/README.md) | Índice de guías (desarrollo, tests, despliegue, configuración, infraestructura, referencia). Incluye [checklist de integridad del proyecto](guides/testing/PROJECT_INTEGRITY_CHECKLIST.md). |
| [**fork-maintenance/**](fork-maintenance/README.md) | Divergencia frente a upstream, playbook de merge, verificación, plantillas y bitácoras. |
| [**migrations/**](migrations/) | Guías por salto de versión del stack cosmos/evm (`v0.*_to_v0.*.md`); plan de software-upgrade del fork: [infinite_v0.1.10_to_v0.1.12.md](migrations/infinite_v0.1.10_to_v0.1.12.md). |
| [**feature/hyperlane/**](feature/hyperlane/README.md) | Hyperlane: [README](feature/hyperlane/README.md), [INTEGRATION.md](feature/hyperlane/INTEGRATION.md) (código), [OPERATIONS.md](feature/hyperlane/OPERATIONS.md) (on-chain/registry/EVM); bitácora [fork-maintenance/logs/2026-04-03-hyperlane-integration.md](fork-maintenance/logs/2026-04-03-hyperlane-integration.md); [UPSTREAM_DIVERGENCE_RECORD.md](fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork). |
| [**feature/infinite-bank/**](feature/infinite-bank/README.md) | English docs: module **`infinitebank`** (`github.com/cosmos/evm/x/bank`), governance **`MsgSetDenomMetadata`** for SDK **x/bank** metadata. [README](feature/infinite-bank/README.md), [INTEGRATION](feature/infinite-bank/INTEGRATION.md); [log](fork-maintenance/logs/2026-04-04-infinite-bank.md); [UPSTREAM_DIVERGENCE_RECORD](fork-maintenance/UPSTREAM_DIVERGENCE_RECORD.md#extensiones-de-producto-fork). |
