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
concept. The backend spine is genre-agnostic and unchanged across every
pivot; only the domain layer is (re)built each time. Pre-pivot code
(`Shop.luau`, `UnitCatalog.luau`, the `BuyUnit` remote, `Cash`) is slated for
rework — see Current implementation state.

## Locked core loop

Idle-collector: **owned cards earn currency passively** → spend it to
**Summon (server-side gacha RNG)** → new cards fill the **index**; duplicates
**level up** the card you own (more income) → **completing an index page**
(a pantheon/universe theme) grants a permanent income/luck bonus →
**Prestige** later for a permanent multiplier + luck.

Three decisions are locked (2026-07-18):

1. **Mythology first; supers later.** Ship with public-domain pantheons
   (Greek/Norse/Egyptian/…) as the first index pages. The "supers" side is
   deferred — and when built, will use **original, legally-distinct**
   characters (archetype-inspired), never actual Marvel/DC IP. Roblox deletes
   games using copyrighted characters; this is a hard constraint.
2. **Idle-collector, not a battler.** Cards passively generate currency;
   there is no combat/deck system. Retention comes from the summon loop +
   index completion, not PvP.
3. **Duplicates level the card.** A repeat pull powers up the copy you own
   (higher income) rather than being wasted — this is the dupe sink, and it
   makes pulling into what you already have feel good.

**Index pages are the backbone / flex surface.** Page completion is the
sticky chase and the leaderboard hook. The **summon animation** is the
dopamine core — rare pulls need screen-filling juice.

Anti-exploit invariant (from the principle below): **gacha RNG rolls on the
server, always** — client-rolled summons get duped instantly.

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
│   ├── PlayerData.luau      profile lifecycle, Get/Set/Increment/Mutate
│   ├── Summon.luau          gacha: validate → server RNG roll → atomic apply
│   ├── Income.luau          1 Hz passive payout from CardStats.totalIncome
│   └── ProfileStore.luau    vendored dependency
├── client/               → StarterPlayerScripts.Client
│   └── Main.client.luau     HUD, summon button, index view, toasts
└── shared/                → ReplicatedStorage.Shared
    ├── Remotes.luau          typed remote references (DataChanged,
    │                         RequestData, Summon, Notify)
    ├── CardCatalog.luau      card defs (id, name, page, rarity, baseIncome)
    ├── PageCatalog.luau      index pages (16 pantheons) + completion bonuses
    ├── SummonCatalog.luau    banners: cost + weighted pool (display-only on
    │                         client; rolls are server-side)
    └── CardStats.luau        pure card math (income, level curve, page
    │                         completion) shared so client displays exactly
    │                         what the server pays
```

Server-only code stays out of anything that replicates to clients. Shared
modules (Remotes, UnitCatalog) are safe to require from both sides.

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

The backend spine survives every pivot; the card-collector domain layer
(**Milestone 1**) is now implemented on top of it (branch
`feature/buy-system`, pending Studio test + merge).

Implemented:
- Player profile load/save via ProfileStore, with session locking.
- Schema: `Coins` (starts at 250 so a fresh player can afford first
  summons), `Gems`, `Cards[cardId] = copies` (≥1 = discovered; copies drive
  level/income), `Prestige`. Old dev profiles may carry stale
  `Cash`/`Units`/`Rebirths` keys (Reconcile only adds) — harmless.
- `Summon` remote → `Summon.luau`: validate banner → check Coins → weighted
  RNG roll **on the server** → atomic deduct+grant via `Mutate` → toast
  ("NEW!" vs "leveled up!").
- Passive income: `Income.luau` 1 Hz tick pays `CardStats.totalIncome`
  (per-card `baseIncome × copies`, times the product of completed-page
  bonuses). Demo `+5/sec` loop is gone.
- Catalogs: 16 pantheon pages (Greek, Norse, Egyptian, Hindu, Celtic, Roman,
  Japanese, Chinese, Aztec, Mayan, Slavic, Yoruba, Polynesian, Persian,
  Inuit, Australian Aboriginal), 5 placeholder cards each (2C/1R/1E/1L;
  weights 70/20/8/2, base income 1/3/8/20, cost 100). Roster needs a
  cultural-sensitivity pass for living traditions before launch.
- Client: code-built HUD (Coins, income/s), summon button, scrolling index
  grouped by page with owned/??? rows, rarity colors, page completion
  ("3/5" → "✓ COMPLETE").

Not yet built:
- Summon reveal animation (the dopamine core — next milestone), prestige,
  limited-time banners (FOMO), trading, the supers pages.
- Per-player world/plot, real UI beyond the placeholder HUD.
- Any monetization (gamepasses, dev products) — design leaves room (luck,
  x2 income, premium summon currency, auto-summon).

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