# Project Context for Claude Code

This file is auto-read at the start of each Claude Code session in this repo.
It captures decisions and conventions from planning discussions so they don't
need to be re-explained. Keep it updated as the project evolves — treat it as
living documentation, not a one-time snapshot.

## What this is

A Roblox "brainrot"-style collector/grinder game (in the vein of Steal a
Brainrot, Mine a Baddie, Anime Card Collection). Early production. Logan is
the sole developer/scripter; a small friend group fills modeling, UI, and QA
roles (mostly TBD — see Open Questions).

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
│   ├── Shop.luau            buy-request validation
│   └── ProfileStore.luau    vendored dependency
├── client/               → StarterPlayerScripts.Client
│   └── Main.client.luau     HUD, shop buttons, toast notifications
└── shared/                → ReplicatedStorage.Shared
    ├── Remotes.luau          typed remote references (DataChanged,
    │                         RequestData, BuyUnit, Notify)
    └── UnitCatalog.luau      unit definitions (id, name, price, income, rarity)
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

Working end-to-end and tested in Studio:
- Player profile load/save via ProfileStore, with session locking.
- Cash replicates to client, rendered in a code-built HUD.
- Demo passive-income loop in `Main.server.luau` (+5 Cash/sec to all
  players) — **placeholder, delete once real generators exist.**
- Buy system: client fires `BuyUnit` with a unit id → server validates the
  unit exists and is affordable → deducts Cash, grants unit, replicates,
  sends pass/fail toast via `Notify`.

Not yet built:
- Passive income *from owned units* (the `income` field in `UnitCatalog` is
  defined but unused — currently only the demo loop grants Cash).
- Gacha/roll system.
- Rebirth/prestige.
- Steal/PvP mechanic (design status: undecided, see Open Questions).
- Persistent world/map, real UI beyond the placeholder HUD.
- Any monetization (gamepasses, developer products).

## Open design questions (blocking full production, not blocking dev work)

The core loop, theme, collectible roster, world structure, and monetization
plan are not yet locked. Full list lives in the project's role-breakdown doc
(`Roblox_Project_Breakdown.docx` if present in the repo/shared drive).
Architecture and tooling don't depend on these answers, so backend work can
continue in parallel with design decisions.

## Team

- Logan — developer/scripter (all code).
- Modeler, UI/UX, QA — not yet assigned.