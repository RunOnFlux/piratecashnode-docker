# piratecashnode-docker — HA PirateCash Masternode for Flux

A 2-instance, self-healing PirateCash masternode image for the Flux marketplace.
Reuses the shared Flux HA masternode template verbatim; only `coin.env` differs.

## Verified against source (piratecash/piratecash, Dash v21 base)
| value | setting | source |
|---|---|---|
| daemon / cli | `piratecashd` / `piratecash-cli` | configure.ac:22/24 |
| datadir | `/root/.piratecore` (**not** `.piratecash`) | util/system.cpp:857 |
| conf | `piratecash.conf` | util/system.cpp:96 |
| MN port | **63636** | chainparams.cpp:308 (CMainParams nDefaultPort) |
| BLS key | **`masternodeblsprivkey`** (Dash original, NOT smartnode) | init.cpp:785 |
| collateral | 10,000 PIRATE | rpc/evo.cpp:372 |
| model | DIP3/ProTx — `protx update_service` → ProUpServTx | rpc/evo.cpp:937 |

## Gotchas
- **Use plain `protx update_service`** — v21 also has `_evo`/`_hpmn` forms; the HA
  node is a Regular masternode (the autoheal uses the plain form).
- `protx info` exposes `.state.service` (dmnstate.cpp:39) and `.state.PoSeBanHeight`
  (dmnstate.cpp:45) — same keys the controller reads.

## Behaviour (same as the template)
- v8, `instances: 2`, `staticip: true`; each instance keeps its own chain; only the
  leader holds the registration; a survivor takes over via ProUpServTx on leader death.
- `node_initialize.sh` writes `externalip=<FLUX_NODE_HOST_IP>:63636` every boot.
- `mn-autoheal.sh` — leader election + self-heal + PoSe-ban revive.

## User inputs
`KEY` (operator BLS priv), `PROTXHASH`, plus a small PIRATE fee balance sent once to
the fee-source address printed on startup.

## Deploy order
1. Build & push `runonflux/piratecashnode:latest`.
2. Add `piratemn.marketplace.json` as the `PirateCashMN` entry in fluxstats.
3. User registers the masternode (10,000 PIRATE collateral) from their wallet.

## Not yet validated
Built + unit-tested (stubbed cli). Real `docker build` + testnet `protx update_service`
dry-run still pending. Binary asset URL verified against the release; base-image glibc
compatibility assumed.
