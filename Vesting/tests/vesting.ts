// Clarinet tests for the simple STX vesting contract
// Run: clarinet test

import { Clarinet, Tx, Chain, Account, types } from "clarinet";

const MICRO = 1_000_000; // 1 STX = 1_000_000 microSTX

Clarinet.test({
  name: "init + fund + mid-claim + final-claim",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const alice = accounts.get("wallet_1")!; // beneficiary

    const total = 100 * MICRO; // 100 STX total vesting
    const startOffset = 2;     // start in +2 blocks (for determinism)
    const duration = 10;       // linear vest across 10 blocks

    // 1) init by owner
    let block = chain.mineBlock([
      Tx.contractCall("vesting", "init", [
        types.principal(alice.address),
        types.uint(chain.blockHeight + startOffset),
        types.uint(duration),
        types.uint(total)
      ], deployer.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // 2) fund the contract with the full amount
    block = chain.mineBlock([
      Tx.contractCall("vesting", "fund", [types.uint(total)], deployer.address),
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // 3) advance to halfway through vesting and claim
    chain.mineEmptyBlock(startOffset + Math.floor(duration / 2));

    block = chain.mineBlock([
      Tx.contractCall("vesting", "claim", [], alice.address),
    ]);
    // Half should be available now
    const half = total / 2;
    block.receipts[0].result.expectOk().expectUint(half);

    // 4) move to the end and claim remainder
    chain.mineEmptyBlock(duration);
    block = chain.mineBlock([
      Tx.contractCall("vesting", "claim", [], alice.address),
    ]);
    // Total claimed should now be == total
    const state = chain.callReadOnlyFn("vesting", "get-state", [], deployer.address);
    state.result.expectOk();

    // The available amount after second claim should be 0
    const avail = chain.callReadOnlyFn("vesting", "get-available", [], deployer.address);
    avail.result.expectUint(0);
  }
});
