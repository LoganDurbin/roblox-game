# Project Context for Claude Code

This file is auto-read at the start of each Claude Code session in this repo.
It captures decisions and conventions from planning discussions so they don't
need to be re-explained. Keep it updated as the project evolves — treat it as
living documentation, not a one-time snapshot.

## What this is

A Roblox **Gods & Supers Card Collection** game — a gacha/idle card
collector. You summon cards, level them with duplicates, and fill a themed
**index** whose pages are mythological pantheons (Greek, Norse, Egyptian, …)
and — later — original superhero universes. Early production. Logan is the
sole developer/scripter; a small friend group fills modeling, UI, and QA
roles (mostly TBD — see Open Questions).

**Direction pivoted 2026-07-18** (again) from the short-lived Brainrot Merge
concept, then refined 2026-07-19 into the **physical pack economy** (see
Locked core loop). The backend spine is genre-agnostic and unchanged across
every pivot; only the domain layer is (re)built each time.

## Locked core loop (pack economy, locked 2026-07-19)

The game is **physical-first** (tycoon-ish): each player has a plot with a
conveyor belt, an open placement square, and a physical index book. The HUD
is only menu buttons (Index / Inventory / Shop / Items) + purchasable boosts.
The economy below is fully specified; the physical world lands in M4 (until
then a flat test UI drives the same server systems).

1. **Belt sells page packs.** A personal conveyor spawns a pack offer every
   2 s (per player, server-rolled): a uniform pantheon page + a rolled
   **modifier**. Offers ride the belt 15 s (**7.5 visible**, locked) then
   expire. Unaffordable high-modifier packs drifting past are intentional
   monetization pressure (planned Robux instant-buy dev product).
2. **Modifiers ("mutations")** — godly ladder, rolled at belt spawn, out of
   10000: Mortal 1× (9000), Blessed 2× (600), Hallowed 5× (250), Divine 10×
   (100), Ascendant 20× (40), Celestial 50× (9), Primordial 75× (1).
   `MutationLuck` multiplies non-Mortal weights. Same flat pack price —
   modifiers are a jackpot roll. Higher tiers take longer to open (15 s →
   20 min ladder): the wait is part of the chase, and timer-skips sell later.
3. **Buy → Inventory → Place → Open.** Bought packs go to a near-infinite
   inventory; placing (limit 4, upgradeable in M3) starts the open timer
   (absolute `os.time`, so it counts down offline). Opening **rolls the card
   server-side** from the pack's page with **fixed in-page odds** (per card:
   Common w20, Rare w6, Epic w3, Legendary w1 → each C ≈20%, R ≈6%, E ≈3%,
   L ≈1%). No stat ever changes in-pack odds — Luck/MutationLuck only shape
   what appears on the belt.
4. **Dupes level the card; modifier is best-wins.** A repeat card raises
   copies (more income). The pack's modifier overwrites the card's stored
   one only if strictly better; equal/worse never downgrades.
5. **Income is per-card and manually claimed.** Each unlocked card accrues
   `baseIncome × copies × modifierMult × completionMult` Coins/sec into its
   own pool, capped at 1 h of storage (upgradeable in M3); accrual is lazy
   (`lastClaimAt`), which handles offline for free. Claiming (tap the card,
   or paid Auto-Collect in M3) banks `rate × min(elapsed, cap)`.
6. **Completing a 3×3 index page** (exactly 9 cards: 4C/2R/2E/1L, locked)
   multiplies ALL rates by that page's bonus → **Prestige** later.

Upgrade system (M3): Luck, cash mult, placement limit, mutation luck,
storage cap — Coins and Robux, scaling costs. Robux ladder: x2→x4→x6 income.

Long-standing locked decisions (2026-07-18): **mythology first, supers later
as original legally-distinct characters** (never Marvel/DC IP — Roblox
deletes those games); **idle-collector, not a battler**; **index pages are
the backbone/flex surface** and the pack-open reveal is the dopamine core.

Anti-exploit invariant (from the principle below): **every roll (belt page,
modifier, in-pack card) happens on the server, always.**

## Non-negotiable architecture principle

**The server is authoritative. The client only requests and displays; it
never decides.** Every piece of state that matters (currency, inventory,
ownership) lives on the server and is validated there. This genre gets
exploited constantly (duping, auto-farming), so this isn't optional — treat
any client-originated value as untrusted input, always.

## Toolchain

- **Rokit** — toolchain manager, pins tool versions in `rokit.toml` so the
  whole team runs identical versions. Installed: Rojo, Wally, StyLua, Selene.
- **Rojo v7** — filesystem → Studio sync. `emitLegacyScripts: false` (modern
  `RunContext` scripts, not legacy LocalScripts).
- **Wally** — package manager, currently unused for real dependencies (see
  ProfileStore note below). `wally.toml` exists with empty dependency tables.
- **Git** — source of truth is `src/`. The `.rbxl` place file is a build
  artifact, never committed. `Packages/` and `ServerPackages/` are
  Wally-generated and gitignored.

## Key decision: ProfileStore is vendored, not Wally-installed

ProfileStore (successor to ProfileService, by loleris/MadStudioRoblox) isn't
reliably published to the Wally registry under the official author. Rather
than trust a third-party mirror for the data-persistence layer, the single
ModuleScript is committed directly at `src/server/ProfileStore.luau`. Revisit
this if/when an official Wally release exists.

## Project structure

```
src/
├── server/              → ServerScriptService.Server
│   ├── Main.server.luau     entry point, wires up services
│   ├── PlayerData.luau      profile lifecycle, Get/Set/Increment/Mutate,
│   │                        schema migration (old numeric Cards → entries)
│   ├── Conveyor.luau        belt: per-player pack-offer spawner (server
│   │                        rolls page + modifier), expiry, buy validation
│   ├── Packs.luau           pack lifecycle: place (limit, timer) and open
│   │                        (server rolls the card, best-wins modifier)
│   ├── Claim.luau           income claims: ClaimCard / ClaimAll bank
│   │                        rate × min(elapsed, cap), reset accrual clock
│   └── ProfileStore.luau    vendored dependency
├── client/               → StarterPlayerScripts.Client
│   └── Main.client.luau     flat M2 test UI: belt strip, inventory/placed
│                            lists, claimable index, toasts (replaced by the
│                            physical world in M4)
└── shared/                → ReplicatedStorage.Shared
    ├── Remotes.luau          typed remote references (DataChanged,
    │                         RequestData, OfferSpawned, OfferRemoved,
    │                         BuyOffer, PlacePack, OpenPack, ClaimCard,
    │                         ClaimAll, Notify)
    ├── CardCatalog.luau      card defs (id, name, page, rarity, baseIncome)
    ├── PageCatalog.luau      index pages (16 pantheons) + completion bonuses
    ├── ModifierCatalog.luau  mutation ladder: mult, spawn weight, open time,
    │                         color (Mortal → Primordial)
    ├── PackConfig.luau       pack price, fixed in-pack rarity weights,
    │                         storage cap, placement limit
    ├── ConveyorConfig.luau   belt timing: spawn interval, travel time
    └── CardStats.luau        pure card math (rates, pending accrual, page
                              completion) shared so client displays exactly
                              what the server pays
```

Server-only code stays out of anything that replicates to clients. Shared
modules (Remotes, catalogs, CardStats) are safe to require from both sides.

## Conventions

- `--!strict` at the top of every module.
- File naming: `*.server.luau` → Script, `*.client.luau` → LocalScript-style,
  plain `*.luau` → ModuleScript. Avoid `init.server.luau` in folders that
  need sibling modules (e.g. `server/` holds `Main.server.luau` + peers, not
  `init.server.luau`).
- Data mutations go through `PlayerData.Mutate(player, fn)`. **`fn` must
  never yield** — the read/validate/write has to stay atomic, or rapid
  duplicate requests (e.g. spamming a buy button) can both pass validation
  before either applies, allowing overspend.
- New feature = new branch (`feature/...`), merge back to `main` once tested.
  Logan wants a standing reminder for this at the start/end of any function
  or feature worth isolating.
- Server replicates full `Data` table on every change via `DataChanged`
  RemoteEvent (`PlayerData.replicate`). Acceptable at current scale; revisit
  with per-key diffing if the schema grows or mutates very frequently.
- No rate-limiting on remotes yet (e.g. `BuyUnit` can be spammed cheaply but
  harmlessly since every call is validated). Flagged for later, not urgent.

## Current implementation state

M1 (card core) merged to `main` via PR #1. **M2 — the pack economy — is
implemented on branch `feature/pack-economy`** (pending Studio test + PR).

Milestone map: M2 economy core (this branch) → M3 upgrades + monetization
(Auto-Collect, Robux x2/x4/x6, upgrade ladder, timer skips) → M4 physical
world (plot, real belt, Tool-based pack placement, physical index book) →
M5 juice (pack-open reveal, modifier VFX, sounds).

Implemented (M2):
- Player profile load/save via ProfileStore, with session locking. In-code
  migration normalizes M1 profiles (`Cards[id] = number` → entry table).
- Schema: `Coins` (250 start), `Gems`, `Cards[id] = {copies, modifier,
  lastClaimAt}`, `Packs[uid] = {page, modifier, state, openReadyAt}` (string
  uids from persisted `NextPackUid` — DataStore-safe), `Prestige`, `Luck`
  (reserved, M3), `MutationLuck`.
- **Belt** (`Conveyor.luau`): per-player pack offers every 2 s — uniform
  page + modifier roll (MutationLuck × non-Mortal weights); 15 s expiry;
  `BuyOffer` validates existence/expiry/Coins then atomically stores the
  pack in inventory.
- **Pack lifecycle** (`Packs.luau`): `PlacePack` enforces the placement
  limit (4) and stamps `openReadyAt = now + modifier.openTime`; `OpenPack`
  enforces the timer, rolls the card (fixed in-page rarity weights), then
  atomically: consumes the pack, banks pending income at the OLD rate
  (so rate increases are never retroactive), bumps copies, applies
  best-wins modifier.
- **Claims** (`Claim.luau`): `ClaimCard`/`ClaimAll` bank
  `rate × min(elapsed, 1 h cap)` and reset `lastClaimAt`. No auto-credit
  tick anymore — `Income.luau` is deleted; accrual is lazy via `CardStats`.
- Catalogs: 16 pantheon pages × 9 cards (4C/2R/2E/1L, base income 1/3/8/20);
  modifier ladder in `ModifierCatalog.luau`. Roster still needs a
  cultural-sensitivity pass for living traditions before launch.
- Client (flat M2 test UI, replaced in M4): belt strip of modifier-colored
  pack offers, inventory list with Place, placed list with live countdowns +
  Open, claimable per-card index rows (tap = claim), Collect All, Coins +
  total rate HUD, toasts.

Not yet built:
- M3: upgrade ladder (Luck, cash, placement limit, mutation luck, storage
  cap), Auto-Collect, Robux income ladder, timer skips, the Robux
  instant-buy of an on-belt offer (needs offer-reserve during the purchase
  prompt), premium pack tiers.
- M4: per-player plot, physical belt/packs/index book, Tool-based placement,
  menu shell (Index/Inventory/Shop/Items buttons).
- M5: reveal juice. Also later: prestige, events, trading, supers pages.

Tooling note: `selene.toml` (`std = "roblox"`) exists, but selene 0.31.0
fails to generate its Roblox std here (its API-dump URL times out — the
mirror repo moved). Not a code issue; retry later or bump selene.

## Open design questions (blocking full production, not blocking dev work)

Core loop and the three decisions above are now **locked** (see Locked core
loop). Still open, and not blocking Milestone 1: currency naming/theming,
rarity tiers & summon odds, the duplicate level curve, the full page/pantheon
list & card roster, prestige thresholds/curve, and monetization specifics.
Full list lives in the project's role-breakdown doc
(`Roblox_Project_Breakdown.docx` if present in the repo/shared drive).

## Team

- Logan — developer/scripter (all code).
- Modeler, UI/UX, QA — not yet assigned.