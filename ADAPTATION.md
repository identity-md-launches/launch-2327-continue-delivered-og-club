# OG Club Clubs launch adaptation

This assignment adds OGClubClubs to the delivered raffle repository at
`fabe4c1d998206e1b1bdf9bdf0f03fb6773a7707`. Every pre-existing Solidity source is
preserved byte for byte, including furniture, staking, farm vault, raffle,
MockOG and both libraries. Build configuration and dependencies are unchanged;
no packages, submodules, network dependencies or new production libraries were
added. No deployment, broadcast, signing or factory call was performed.

The supplied factory and ownership checks and pinned security references were
read. OGClubClubs has one nonpayable constructor with six static arguments,
explicit ownership and royalty beneficiary, no dependency calls during
construction, no linking requirements, and no proxy or upgrade mechanism.
The new deployed runtime is 12,680 bytes, below the 24,576-byte limit. Tests
apply the protected check's reachable-opcode rule to its runtime.

## Changes and reasons

| File | Change and requirement |
| --- | --- |
| `src/OGClubClubs.sol` | Added the requested ERC-721 rooms with enumeration, ERC-2981 royalties, ERC-4906 notifications, ERC-1155 receiving, Ownable2Step and ReentrancyGuard. Constructor parameters fix token, vault, price and furniture forever, reject zero values and make no dependency calls. |
| `src/OGClubClubs.sol` | Added paid minting to the payer or a recipient, starting at ID 1 and with no cap. Transfers go directly to the specified burn sink and vault, odd-price dust goes to the vault, and both recipients' final balance increases must be exact. The payer's debit is also checked to reject extra sender fees. Receiver/payment failure reverts the entire mint. A predicted self-vault is rejected so no payment can be retained by clubs. |
| `src/OGClubClubs.sol` | Added bounded 10x10 placement validation, reserved door tiles, rotations, overlap checks, ordered pieces, occupancy views and per-ID footprint locks. Authorization follows the brief's `from` rule and the existing furniture transfer approvals. The receiver rejects wrong assets, amounts, malformed data and batch-hook calls. There is no furniture outflow, approval, relocation or removal function. |
| `src/OGClubClubs.sol` | Added owner sale control, unused-footprint configuration, URI-prefix configuration and permanent freeze, and royalties initially 500 bps with a 1000-bps cap. Ownership gives no free mint, club seizure, burn or withdrawal. Metadata changes and freeze notify the full token range; successful placements notify their club. |
| `script/DeployClubs.s.sol` | Added Sepolia/local and mainnet/local preparation scripts. Sepolia creates the existing MockOG, furniture and farm vault with clubs priced at 100_000e18, configures JSON footprints, then opens the sale. Mainnet uses the six specified environment inputs and existing dependencies, configures footprints and leaves the sale closed. All owners are explicit. Both print addresses and ABI constructor arguments. They read no private keys and never temporarily own applications. |
| `script/club-footprints.json` | Added the JSON catalogue input as an explicit empty array. No furniture IDs or dimensions were supplied; owner-settable footprints are the brief's supported configuration mechanism. Populate with real catalogue rows `[id,w,h]`. Parser checks row shape, unsigned values, dimension bounds and duplicate IDs before deployment. File contents enter the scripts through `FOOTPRINTS_JSON`, avoiding any change to protected Foundry filesystem permissions. |
| `launch.json` | Preserved the five original deployments and appended OGClubClubs with backward references to MockOG, farm vault and furniture, price 100000000000000000000000, and `$owner` for owner and royalty receiver. The explicit task asks for this manifest, overriding the quoted background that deferred it. Notes distinguish constructor-only deployment from optional owner operations and the Sepolia script, and retain the original raffle handoff constraints. |
| `README.md` | Added club economics, placement ABI and authorization, renderer views, permanent custody, metadata/royalty powers, scripts, catalogue configuration, factory handoff, known library behavior and the current fuzz seed. Existing raffle documentation remains, with independent draw monitoring and first-grant order identified as required. |
| `test/helpers/ClubsTestBase.sol` | Added shared fixtures using the real unchanged furniture, farm vault and MockOG, with an odd club price. No external accounts, RPC or credentials are needed. |
| `test/OGClubClubs.t.sol` | Added mint/split, events, sequential IDs, safe delivery, approvals/balances, taxed/false/no-return tokens, recipient over/under-credit, cross-leg balance mutation, receiver/token reentrancy, enumeration and admin tests. Includes all zero constructor arguments, royalty bounds, URI freeze, ownership handover and absence of privileged mint/seizure/burn/withdraw paths. Fuzzes price and mint count for conservation. |
| `test/ClubsPlacement.t.sol` | Added real furniture placement and event/view tests, all four rotations, dimensions, both approval mechanisms, revoked permissions, club transfers, failed placement atomicity, malformed data, wrong asset/amount, batches, missing clubs, per-ID locks and permanent custody. Exercises all 98 usable cells and separately checks the 100-piece guard with test-only synthetic storage. |
| `test/ClubsInvariant.t.sol` | Added an independent cell-by-cell layout oracle for random placement sequences and stateful handlers for purchases, transfers, placements and sale changes. Checks accepted geometry, rejected-state preservation, payment conservation, zero protocol OG custody, and per-ID furniture custody matching every recorded piece. |
| `test/ClubsDeployment.t.sol` | Added script tests, JSON validation, chain guards, price/owner/dependency/royalty checks, absent-dependency constructor tests, CREATE2 factory deployment and runtime size/opcode checks. Confirms Sepolia opens, mainnet stays closed and club scripts do not consume the furniture bootstrap grant. |
| `test/ImportedAudit.t.sol` | Added permanent reproductions of all three existing-behavior audit observations, plus a regression proving the new clubs contract works without the raffle's roles. Existing application behavior is preserved as expressly required. |
| `test/test_launch.py` | Extended the original manifest check to the sixth application and its exact constructor values. Retains ABI/static argument, dependency ordering and owner checks. |
| `ADAPTATION.md` | Replaced the previous assignment's historical notes with this assignment's changes, evidence and limits. |

## Imported audit disposition

No reported observation was dismissed as unreproduced. The three observations
about existing contracts reproduced; the missing-clubs observation matched the
initial source inventory and is resolved by this delivery. The explicit request
to keep every existing contract exactly as it is governs the disposition of the
first three findings: their trust/operational assumptions remain, with tests and
handoff documentation, rather than changing their economics or protocol.

| Audit ID | Reproduction and resolution |
| --- | --- |
| `2fa7888ddf6ea684bc1feb4619a3326b1a6a6d1f1bf685ea7ef4703a625ae701` | `test_Audit2fa7888_RaffleNeedsFirstGrantsWrongTargetConsumesBootstrap` reproduces NotSpender before owner setup, immediate bootstrap consumption by the wrong first recipient, the seven-day wait in both permission systems and successful activation at maturity. Existing constructors cannot grant roles to a later raffle address. The README and manifest retain first grant to the confirmed raffle, verification of both roles, and the launch-blocking order. No predicted-address initializer or changes to existing contracts are introduced. Clubs need neither role, and their scripts leave the bootstrap unused. |
| `1ecd3a75141b202739f6db632edd18ca37dc402ce11df26279835bcfbcd6ca37` | `test_Audit1ecd3a7_AnyoneCanMintTestnetStakeAndBuyClubs` confirms arbitrary 1e30 MockOG mint/stake/points and purchase of a club with freely minted tokens. This is the explicitly requested Sepolia mock, not production currency. Its code remains unchanged. The manifest is labeled Sepolia-only; the mainnet club script creates no mock and takes the actual OG token, furniture and vault as inputs. |
| `07e7433c587c3a0d935567b6ddf30b135eac7385e5ce4dcfb4d625b25efa167b` | `test_Audit07e7433_TargetExpiresAndCanBeReplacedButDrawnSeedIsFinal` confirms retarget rejection at target+256, loss of the first target at +257, a fresh target and seed, and finality once drawn. This is existing documented raffle behavior, retained under the preservation requirement. The runbook requires independent monitoring and drawing inside the live window; it does not claim monitoring removes validator influence or censorship risk. |
| `9dcac5013e4c34d8b21a8f314ea66323744cbcfebe8c03bacad038ff3774a923` | OGClubClubs was absent from the initial sources and manifest. It is now implemented, tested and appended to the manifest. `test_Audit9dcac50_ClubsNowWorkWithoutRaffleBootstrapRoles` proves a paid club mint while both legacy bootstrap flags remain unset. Tests additionally cover furniture-level operators, exact recipient balances, malformed data, batch rejection and farm vault revenue. |

## Deliberate boundaries and launch handoff

- The constructor always starts with a closed sale, empty URI and no footprints,
  as requested. A constructor-only factory cannot additionally run the Sepolia
  script's owner actions. The manifest makes this explicit: the owner configures
  real footprints and metadata and opens the sale when ready. The script's
  ordinary owner calls are not an initializer or factory privilege.
- OWNER is the script broadcaster for configuration. A contract owner such as a
  Safe must execute those calls through its own authorization flow after the
  constructor deployment. No script impersonation can authorize real on-chain
  transactions from a Safe.
- Two permanently reserved door tiles leave only 98 usable cells. A valid room
  cannot reach 100 pieces; the explicit 100-piece cap is defensive. The cap test
  uses a storage cheat solely to exercise that otherwise unreachable branch.
- OpenZeppelin 5.0.2 routes singleton ERC-1155 batches to the single receiver
  hook. The receiver cannot identify the original transfer entry point. A
  singleton with valid data is recorded as one permanent placement; direct
  batch-hook calls, empty batches and multi-item batches revert. This behavior
  is tested and documented without modifying the protected dependency or the
  unchanged furniture contract.
- Permanent metadata freeze means the URI prefix, not the layout or content at
  a mutable URL. Placements remain possible and emit MetadataUpdate. An unused
  footprint can still be configured; a used footprint can never change.
- Zero OG custody is an invariant of mint/placement/transfer/admin operations,
  not a claim that ERC-20 donations can be prevented. Unsolicited tokens have no
  recovery path. Furniture custody is exact with the real immutable furniture
  contract; malicious replacement token behavior is not assumed trustworthy.
- MockOG remains testnet-only. Mainnet inputs are intentionally operator-provided
  environment parameters, not invented deployment addresses. No deployment key,
  actual production token address or unpublished furniture catalogue is needed
  to build, test or constructor-deploy the application.

## Validation

The original tree passed 119 tests with the assignment's seed before changes.
All new deterministic, fuzz and stateful tests use the existing configuration;
no via-IR switch or reduced fuzz/invariant settings were introduced. The club
stateful suite executes 128 runs at depth 64, with 8,192 handler calls and no
unexpected reverts. The layout fuzz test checks 48 attempted placements per case
against the independent grid, including rejected-state preservation.

Final build, complete test, formatting and manifest results are recorded below.
No Slither, Mythril, live-chain simulation or explorer verification is claimed.
The supplied protected harness itself requires launch-service environment inputs;
local tests reproduce its constructor, owner and runtime properties without
reading or inventing those service inputs.

| Final check | Result |
| --- | --- |
| `forge build` | Passed with the project's existing configuration. |
| `FOUNDRY_FUZZ_SEED=0xf236bdc08e156b1d158e98af99b4b7c3d0e8797c8771799ec73b9c326a3f8fff forge test` | 165 passed, 0 failed, 0 skipped across 25 suites; includes all original tests. |
| `forge fmt --check` | Passed. Only the newly added Solidity files were formatted. |
| `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s test -p 'test_*.py' -v` | All 6 tests passed, including the six-contract manifest/ABI check. |
| SHA-256 comparison against the initial source/config snapshot | Every pre-existing Solidity source and `foundry.toml` unchanged. |

Forge's lint output includes existing-project warnings and two notices on the
new contract: the vault zero check is performed through `_nonzero` (all six
zero constructor arguments are tested), and ClubMinted follows `_safeMint`'s
receiver call (both mint entry points are guarded and callback rollback is
tested). These are reviewed notices, not compiler or test failures.
