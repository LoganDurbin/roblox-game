# Gods & Supers — Card Collection Game

A Roblox card-collector. You collect cards of gods and mythological figures
(Greek, Norse, Egyptian, and more — superheroes come later), fill out a
themed **index book**, and earn money that lets you collect even more. This
README is the plain-English snapshot of where the project is — no coding
knowledge needed. (The technical details for developers live in `CLAUDE.md`.)

## The idea in one minute

- A **conveyor belt** slides card **packs** past you. Each pack belongs to a
  mythology (a "Greek Pack," a "Norse Pack," etc.).
- You **buy a pack**, **place it down**, and it takes some **time to open**.
  When it opens, you get a **random card** from that mythology.
- Every card you own **earns money over time**. You **collect** that money and
  spend it on more packs.
- Better mythologies cost more but pay more — so you **climb a ladder**,
  starting with cheap Greek packs and working your way up.
- Cards come in rarities (Common → Legendary), and packs can roll a special
  **mutation** (Blessed, Divine, Primordial…) that makes a card worth a lot
  more money.
- Filling a whole mythology's page in your index gives a permanent bonus.

## What works right now

The **full money loop is playable** (in a plain, temporary test menu — the
pretty version comes later):

- Packs slide across a belt, priced by mythology and mutation.
- Buy → place → wait the timer → open → get a card.
- Cards earn money; you collect it and buy more.
- Duplicate cards level up (earn more). A better mutation upgrades a card.
- The index tracks which cards you've found and which pages are complete.
- Everything saves between play sessions.

## What's being built next

1. **The real world.** Right now everything is menus and buttons. Next we
   build the **actual 3D space**: your own plot with a physical conveyor
   belt, a place to set down packs, and a physical index book you walk up to.
   **This is where models and environment art are needed.**
2. **Upgrades & purchases.** Luck (better packs appear), auto-collect,
   money-doubling boosts, and other upgrades.
3. **Polish.** Pack-opening animations, sound, and effects — the exciting
   "what did I get?!" moment.

## Team

- **Logan** — all the code/scripting.
- **Modeling, UI/UX, QA** — open roles. The 3D-world step above is the first
  place modeling and environment work plugs in.

---

## For developers: running it

Build the place file, then start syncing with Roblox Studio:

```bash
rojo build -o "game.rbxlx"
rojo serve
```

Open `game.rbxlx` in Studio and connect the Rojo plugin. Source of truth is
everything under `src/`. See `CLAUDE.md` for architecture and conventions.
