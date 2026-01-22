# Stacks Message Board (sBTC)

A Clarity dApp that lets users post short messages to the Stacks blockchain for a configurable sBTC fee (default: 1 satoshi). The contract tracks messages (content, author, burn block height, Stacks block time), enforces sBTC payment with post-conditions, rate-limits posts per principal, verifies the sBTC contract hash, and allows the deployer to withdraw collected sBTC. A small React + Stacks Connect frontend is included for testnet.

## Repo layout
- `contracts/message-board-v2.clar` — Clarity contract charging a configurable sBTC fee (default 1) to post and emitting an event for each message.
- `tests/message-board.test.ts` — Vitest + Clarinet simnet tests for posting and owner withdrawals.
- `deployments/default.*.yaml` — Clarinet deployment plans (simnet/testnet) including sBTC requirement contracts.
- `settings/*.toml` — Devnet/testnet configuration and funded accounts for local work.
- `frontend/` — Vite + React demo UI that connects a Stacks wallet and calls the contract on testnet.

## Prerequisites
- Node 18+ and npm
- Clarinet `>=3.9.0`
- (Frontend) modern browser with Hiro Wallet / Leather or compatible Stacks wallet

## Install
```bash
# install root tools (tests, Clarinet helpers)
npm install

# install frontend deps
cd frontend && npm install
```

## Smart contract
Key entrypoints in `message-board-v2.clar`:
- `add-message (content)` — Charges the configured sBTC fee via post-condition; stores message with author, `burn-block-height`, and `stacks-block-time`; emits an event; returns message id.
- `set-message-fee (fee)` — Deployer-only: set the sBTC fee (in satoshis) required to post. Must be `> 0`.
- `set-min-post-interval (blocks)` — Deployer-only: set the minimum burn-block interval between posts per principal (default is `1`, preventing multiple posts in the same burn block).
- `withdraw-funds` — Deployer-only withdrawal of accumulated sBTC to the contract owner.
- `get-message` / `get-message-author` — Read a message or just its author by id.
- `get-message-count-at-block (block)` — Historical message count at a given Stacks block using `at-block`.
- `get-message-fee` / `get-min-post-interval` / `can-post-now (who)` — Read-only helpers for UI and monitoring.
- `get-token-hash-status` — Read-only helper to compare the expected vs current sBTC contract hash.

The contract depends on the sBTC token/registry/deposit requirement contracts (addresses provided in `deployments/default.testnet-plan.yaml`).

## Clarity 4 features used
- `restrict-assets?` protects external calls while charging the configured sBTC fee.
- `stacks-block-time` recorded alongside `burn-block-height` for richer timestamps.
- `contract-hash?` to pin and verify the sBTC token contract code.
- `to-ascii?` to emit human-readable principals in events.

## Tests
```bash
npm test                # run Vitest against Clarinet simnet
npm run test:watch      # re-run on contract/test changes
```
Tests cover posting a message (including event shape and id) and owner withdrawals of the collected sBTC.

## Local dev with Clarinet
Common commands:
```bash
clarinet check             # type check contracts
clarinet console           # interactive REPL
clarinet integrate         # run integration scripts if added
```
Devnet accounts, sBTC balances, and other node settings live in `settings/Devnet.toml`.

## Deployment
- Testnet plan: `deployments/default.testnet-plan.yaml` publishes the sBTC requirement contracts then `message-board` (Clarity v4).
- Update addresses/principals as needed before broadcasting.

## Frontend (testnet demo)
```bash
cd frontend
npm run dev
```
What it does:
- Connects a Stacks wallet via `@stacks/connect` and shows the BNS name (or address) for the connected account.
- Calls `add-message` with a post-condition requiring the caller to pay the current message fee.
- Includes a helper to query `get-message-count-at-block` via Hiro API (supply `x-api-key`).

Frontend contract configuration lives inline in `src/App.tsx`; update the contract address/name and the Hiro API key placeholder before using in production.

## Notes & Gotchas
- Posting requires the configured sBTC fee (default 1 satoshi); users must hold the token on the target network.
- `withdraw-funds` is restricted to the contract deployer (`CONTRACT_OWNER`).
- When changing epochs or Clarity versions, align `Clarinet.toml` and deployment plans.


