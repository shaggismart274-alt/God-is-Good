# Simple STX Vesting (Clarity + Clarinet)

A **portable, minimal vesting contract** for STX. Initialize a beneficiary, start height, duration, and total vesting amount. Anyone can fund the contract. The beneficiary can claim vested STX at any time; vesting is **linear** over the specified duration.

## Features
- Single-file Clarity contract
- Linear vesting by block height
- "Fund then claim" flow; uses native STX (no extra token traits)
- Small, easy-to-read code with read-only getters

## Requirements
- [Clarinet](https://github.com/hirosystems/clarinet) installed

## Quick Start

```bash
# 1) install deps
clarinet --version

# 2) run tests
clarinet test

# 3) deploy locally
clarinet console
```

From the Clarinet console you can call functions directly.

## Contract Interface

```clojure
;; Admin
(init (beneficiary principal) (start uint) (duration uint) (total uint)) -> (response bool uint)
(fund (amount uint)) -> (response bool uint)

;; User
(claim) -> (response uint uint)        ;; ok => amount claimed (in microSTX)

;; Views
(get-state) -> { beneficiary: (optional principal), start: uint, duration: uint, total: uint, claimed: uint, initialized: bool }
(get-available) -> uint
```

- **Units**: amounts are in **microSTX** (1 STX = 1,000,000 microSTX).
- **`init`**: callable by the **contract owner** once; sets parameters.
- **`fund`**: moves STX from the caller into the contract.
- **`claim`**: pays the beneficiary their currently-available vested amount; returns the amount claimed.

## Example Flow (Local)

1. **Deploy** the contract.
2. **Initialize** (owner only):
   ```
   (contract-call? .vesting init 'SP...-beneficiary u<start> u<duration> u<total>)
   ```
3. **Fund** the contract with the total amount (any account can do this):
   ```
   (contract-call? .vesting fund u<total>)
   ```
4. **Advance blocks** (in tests) or wait on mainnet/testnet.
5. **Beneficiary claims** vested funds:
   ```
   (contract-call? .vesting claim)
   ```

## Notes
- You can call `get-available` any time to see how much is currently withdrawable.
- If funding is less than `total`, claims will fail once the contract runs out of STX.
- To keep it portable and tiny, this version doesn't include cliffs or revocation; feel free to extend it.

## Project Structure
```
contracts/
  vesting.clar

tests/
  vesting_test.ts

README.md
```

## License
MIT
