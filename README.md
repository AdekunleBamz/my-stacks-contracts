# Stacks Message Board (sBTC)

A simple Clarity dApp that lets users post short messages to the Stacks blockchain for a 1-satoshi sBTC fee. The contract tracks messages (content, author, burn block height), allows the deployer to withdraw collected sBTC, and exposes read-only helpers. A small React + Stacks Connect frontend is included for testnet.

## Repo layout
- `contracts/message-board.clar` — Clarity contract charging 1 sBTC to post and emitting an event for each message.
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
Key entrypoints in `message-board.clar`:
- `add-message (content)` — Charges 1 satoshi of sBTC via post-condition; stores message with author and `burn-block-height`; emits an event; returns message id.
- `withdraw-funds` — Deployer-only withdrawal of accumulated sBTC to the contract owner.
- `get-message` / `get-message-author` — Read a message or just its author by id.
- `get-message-count-at-block (block)` — Historical message count at a given Stacks block using `at-block`.

The contract depends on the sBTC token/registry/deposit requirement contracts (addresses provided in `deployments/default.testnet-plan.yaml`).

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
- Calls `add-message` with a post-condition requiring the caller to pay 1 sBTC to the contract.
- Includes a helper to query `get-message-count-at-block` via Hiro API (supply `x-api-key`).

Frontend contract configuration lives inline in `src/App.tsx`; update the contract address/name and the Hiro API key placeholder before using in production.

## Notes & Gotchas
- Posting requires 1 satoshi of sBTC; users must hold the token on the target network.
- `withdraw-funds` is restricted to the contract deployer (`CONTRACT_OWNER`).
- When changing epochs or Clarity versions, align `Clarinet.toml` and deployment plans.

## Suggested GitHub “About” text
- Short: “Message board dApp on Stacks that charges 1 sat of sBTC per post, with tests and a React demo.”
- Longer: “Clarity-powered message board for Stacks: pay 1 sat sBTC to post, withdrawable by the owner, with Clarinet tests, deployment plans, and a Vite/React testnet UI.”

