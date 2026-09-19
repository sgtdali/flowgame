# Iron & Ember — three-stage industrial opening

## Goal

The opening of the game is an idle/incremental loop, not a routing puzzle:
"a few small investments earlier bought me a new production capability, and
now I earn noticeably more." Two independent income lines open first — iron
and electricity — and combining them is the first strong power spike.

## Active scope

| Stage | Player action | Lasting result |
|---|---|---|
| 1. Iron | Mine → Smelting Hearth → Market Stall | Ingot sales, manually collected |
| 1b. Small investments | Mine speed (Market Stall is no longer upgradeable — see "Market sale upgrade" below) | Now directly proportional to sustainable income — see "Smelting Hearth redesign" below |
| 2. Electrification | 1,100 gold research + 900 gold Generator + 300 gold Power Exchange | A second income line, independent of the iron route — sell raw power directly |
| 3. Electrified Rolling | 1,600 gold research + 900 gold Electric Rolling Mill (reuses the existing Iron Forge workshop and Iron Plate item) | Ingots + a power line together beat selling either input alone |

### Stage 1: Iron

Mine → Smelting Hearth → Market Stall, early manual collection, later
automatic. Mine upgrades remain an optional, non-forced investment; Market
Stall has none (see the content contract below).

### Smelting Hearth redesign — no pace of its own

The Hearth used to have its own fixed processing duration (a "capacity"),
which meant its throughput hit a hard ceiling that the Mine could exceed
even at level 1 — Paket C's first measurement pass proved mine upgrades were
doing almost nothing as a result (see the old finding in git history / the
previous revision of this section). Fixed per user instruction: the Hearth
no longer has a duration at all (`r_kulce.tres` `duration_ticks = 0`).
Instead it needs **6 ore** to accumulate in its input before it converts
them to **1 ingot**, and that conversion happens the instant the sixth ore
arrives — there is no separate timer competing with delivery speed. This
means the Hearth's output rate is now a pure function of how fast ore
reaches it: `ingot/min = ore/min ÷ 6`, with no independent ceiling. Every
Mine upgrade now translates directly into more ingots — re-measured in
Paket C below.

This also changes what the node's "Rate" stat shows for the Hearth: since it
has no intrinsic pace (`duration_ticks_at_level` is 0), it displays "—"
rather than a number — showing a ceiling would be dishonest here, there
isn't one to show.

### Stage 2: Electrification (new)

`Generator → Power Exchange`, gated by the **Electrification** research
(1,100 gold, no prerequisite — reachable independently of the iron branch's
own research, though its 1,100 gold naturally tends to come from iron sales
early on).

- **Generator**: 900 gold, produces a constant power *capacity* every tick
  (40 kW at level 1, +15 kW per upgrade level up to level 4). It does not
  consume ore or ingots — this is the point: a second, self-contained income
  line. Capacity is never stockpiled; whatever isn't drawn a given tick is
  simply not sold that tick, exactly like an idle mine wastes no ore but also
  banks none in advance.
- **Power Exchange**: 300 gold, a Market-Stall-twin for electricity. Wire a
  Generator to it and it sells whatever power arrives, batched into 100-kW
  units at 4 gold each (reuses the Market Stall's `accrued`/`collect`
  accounting exactly — no parallel bookkeeping).
- At level 1, running a Generator flat-out into a Power Exchange yields
  roughly 960 gold/min — matching the post-Forge iron income, so the second
  branch feels like a real payoff, not a filler mechanic.

### Stage 3: Electrified Rolling (repurposed, not duplicated)

Per the brief, this reuses the **existing** Iron Forge workshop and Iron
Plate item rather than adding a parallel "rolling mill" — the project
already has an unrelated "Drawbench" workshop with that name for a later
plate→rod step, so a second one would have collided both in name and in
function.

- The Iron Forge (`pres.tres`, now displayed as **Electric Rolling Mill**)
  keeps its ingot → plate recipe and 900 gold build cost, but now also draws
  **24 kW** from a connected Generator to run at full speed. Underpowered, it
  slows proportionally (energy accumulates instead of raw ticks — see
  `FactorySim._run_powered_producer`); at zero power it does not advance at
  all. Out of ingots, it does not run regardless of power — power alone
  never substitutes for the material input.
- Its research (`presleme.tres`, now **"Electrified Rolling"**) now
  `requires` **Electrification** — the player must have already opened the
  power branch before this unlock is even offered, so the mandated
  iron → electricity → combined-mill order can't be skipped. Cost stays at
  1,600 gold, matching the previous Iron Forging balance point.
- The old armor/weapon production chain that used to sit downstream of the
  Iron Forge (Drawbench, Rivet Press, Assembly Press, Quality Inspector,
  Storehouse, Salvage Hearth, Deep Iron Mine, Research Lab, and their ten
  research nodes) has been **removed** rather than re-gated — it was
  medieval-flavored leftover content outside this round's three-stage scope,
  not something the brief asked to preserve. Their block/item ids are listed
  in `BlockCatalog.REMOVED_TYPE_IDS` so old saves referencing them still load
  cleanly (the stations are silently dropped, same as the old farm-era ids).
- **Automation** is its own research now (1,200 gold, requires Electrified
  Rolling) rather than a side effect of Electrified Rolling — discovering it
  sets the single factory-wide `auto_collect` flag, so every Sevkiyat station
  (Market Stall, Power Exchange) stops needing manual collection at once, not
  just the Mill's own output.

### Power sharing (new)

A dedicated, deterministic power system, separate from the material-flow
graph:

- Power connections are a **distinct port type** (`PORT_TYPE_POWER`) in the
  flow canvas — Godot's own `GraphEdit` connection-type check keeps power
  and material wires from ever being cross-wired by accident.
- Each tick, a Generator's capacity is handed out in a fixed, explainable
  order: connected **production** consumers (the Electric Rolling Mill) are
  served first, up to what they actually want that tick (nothing if they
  have no ingots queued); whatever capacity remains goes to connected **sale**
  consumers (the Power Exchange), split evenly if more than one is wired.
  A consumer draws from exactly one Generator — no double-counted capacity.
- No manual ratios or priority menus in this pass, matching the brief. The
  player can always disconnect the Mill's power line to fall back to selling
  100% of a Generator's output directly.

## Paket C — measured three-stage progression (roadmap.md §5)

`tools/iron_progression_test.gd` was rewritten against the current content:
real `FactorySim`/`ProgressionState`, the actual Electrification →
Electrified Rolling → Automation prerequisite chain, real power wiring (the
Mill and every Generator are actually connected, not assumed), and the
Automation research gate instead of flipping `auto_collect` directly. It was
**actually run** (`godot --headless --path . --script
res://tools/iron_progression_test.gd`, Godot 4.6.1) — this is measured data,
not a hand calculation.

Five routes, same 1,000 gold start, same fixed iron opening, 30-game-second
collection interval, 40-game-minute stall ceiling. All five reach the full
Electrification → Electrified Rolling → Automation sequence (none stalled).
"Sürdürülebilir" is gold/min measured over 4 game-minutes after Automation.

**Re-measured twice since the original pass**: once after the Smelting
Hearth redesign (6 ore → 1 ingot, no timer, `input_capacity` 8→6), and once
more after capping the Generator at `max_instances = 1`. Numbers below are
current; earlier revisions of this table (still in git history) are
superseded. The "Generator duplication" route is kept in the table on
purpose, now as a **negative control** proving the cap works — it can no
longer build a second Generator, so it degrades to exactly the "Accumulate"
numbers.

| Route | Total spent | Reaches Automation | 4× real time | Mine/Exchange upgrades / Generators | Sustainable income |
|---|---:|---:|---:|---|---:|
| Accumulate (no investment) | 6,650 | 23:30 | 5:52 | 0 / 0 / 1 | 1,184 gold/min |
| Mine-focused (3 upgrades) | 7,700 | 22:30 | 5:37 | 3 / 0 / 1 | 1,336 gold/min |
| Power Exchange-focused (3 upgrades) | 8,050 | 23:30 | 5:52 | 0 / 3 / 1 | 1,616 gold/min |
| Mixed (mine + exchange) | 9,100 | 22:30 | 5:37 | 3 / 3 / 1 | **1,738 gold/min** |
| Generator duplication (now capped — cannot build a 2nd) | 6,650 | 23:30 | 5:52 | 0 / 0 / 1 | 1,184 gold/min (= Accumulate) |

### Findings

1. **Fixed: Mine upgrades now matter.** "Mine-focused" beats "Accumulate" on
   both speed (22:30 vs 23:30 to Automation) and sustainable income (1,336
   vs 1,184 gold/min) — three mine upgrades costing 1,050 gold are now a
   genuinely good trade, because the Hearth has no independent ceiling to
   hide behind any more.
2. **Expected pacing shift, not a bug.** Reaching Automation went from
   ~7:30–10:30 game-minutes (old duration-based Hearth) to ~22:30–25:00 —
   roughly 3× longer — because level-1 ingot output dropped from ~42.9/min
   to 10/min (60 ore/min ÷ 6). Direct consequence of "6 ore per ingot, tied
   to mining speed" as specified. Still open if the pacing itself needs
   further tuning (ore/ingot prices, the 6:1 ratio) — not touched here.
3. **Fixed: Generator capped at 1, duplication no longer possible.** Before
   the cap, 3 Generator+Exchange pairs beat every other route by ~2×
   (11,750 spent → 3,104 gold/min). With `max_instances = 1`, that route
   degrades to exactly the Accumulate numbers, confirmed by measurement
   (same 6,650 spent, same 23:30, same 1,184 gold/min — not approximately
   equal, *identical*, since it's now mechanically the same route). **Mixed
   is now the best measured strategy** (1,738 gold/min) — a player who
   wants to maximize income now has a real reason to invest in both the
   Mine and the Power Exchange, and no reason to try to spam Generators
   instead of engaging with the Mill/upgrade systems.

Full per-route event timelines (first collection, each research purchase,
each construction, first small investment) are printed by the tool itself,
not duplicated here — see the "OZET TABLO" and per-route sections in its
stdout.

## Paket A — current behavior contract (roadmap.md §3)

Raw values pulled directly from the `.tres`/`.gd` source of truth as of this
pass, plus the ambiguities `roadmap.md` flagged, resolved or explicitly left
open. This section is the single comparison table Paket A's exit condition
asks for.

### Starting state

- Start money: **1,000 gold** (`GameConfig.START_MONEY`).
- Simulation rate: **10 ticks/second** (`GameConfig.TICKS_PER_SECOND`) — 1
  tick = 0.1 s. Every "per tick" number below is on this clock.
- Buildable from the start (`unlocked_at_start = true`): Iron Mine, Smelting
  Hearth, Market Stall, Crossroads.

### Content table

| Workshop | Build cost | Recipe | Duration | Cap on count | Upgradeable | Power |
|---|---:|---|---:|---|---|---|
| Iron Mine | 250 | — → 1 Ore | 10 ticks | 1 (`max_instances`) | Yes, base 150g ×2/lvl, +15 ore/min per level, max lvl 4 | — |
| Smelting Hearth | 400 | 6 Ore → 1 Ingot | 0 ticks (instant on 6th ore — no pace of its own, see "Smelting Hearth redesign") | none | No | — |
| Generator | 900 | — (power only) | — | 1 (`max_instances`, see "Generator instance cap") | Yes, base 300g ×2/lvl, +15 kW per level, max lvl 4 | produces 40 kW (lvl 1) |
| Power Exchange | 300 | — (power only) | — | none | Yes, base 200g ×2/lvl, +20% sale value per level, max lvl 4 | consumes, sells in 100-kW batches |
| Electric Rolling Mill | 900 | 1 Ingot → 1 Plate | 10 ticks | none | No | needs 24 kW/tick while active |
| Market Stall | 0 | — (sells anything) | — | none | **No — see "Market sale upgrade" below** | — |
| Crossroads | 350 | — (splits one route into two) | — | none | No | — |

Item prices: Iron Ore 2g, Iron Ingot 10g, Iron Plate 32g, Electricity 4g per
100-kW-tick batch.

### The three researches

| Research | Requires | Cost | Unlocks | Cumulative cost from scratch |
|---|---|---:|---|---:|
| Electrification | none | 1,100 | Generator + Power Exchange | 1,100 + 900 + 300 = **2,300** |
| Electrified Rolling | Electrification | 1,600 | Electric Rolling Mill | 2,300 + 1,600 + 900 = **4,800** |
| Automation | Electrified Rolling | 1,200 | (no new workshop — sets `auto_collect`) | 4,800 + 1,200 = **6,000** |

A research being **purchased** (`ProgressionState.unlocked[id] = true`) and a
workshop **actually producing** are deliberately different events: buying
Electrification only makes the Generator and Power Exchange buildable in the
palette. The player still has to spend their build cost, place them, and
wire power before either earns anything. `iron_progression_test.gd`
conflating these two events (see the "not yet verified" note) is exactly the
bug Paket C exists to fix; any test or UI code added later must keep
"unlocked" and "wired and running" as separate checks, not infer one from
the other.

### Collection, automation, and sale-rate semantics

- Every Sevkiyat-category station (Market Stall, Power Exchange) sells on
  contact: `sold_counts` and the node's `Rate` stat both update the instant a
  sale happens, whether or not anyone has clicked Collect.
- Before Automation: sale proceeds sit in that station's own `accrued` and
  are **not spendable** until `collect()` moves them to the treasury
  (`FactorySim.revenue`). Clicking Collect never changes the sale rate — it
  only moves already-earned gold into the spendable balance.
- After Automation (`auto_collect = true`): this is a single **factory-wide**
  flag, not per-station. The instant it flips, every Sevkiyat station's
  future sales go straight to `revenue`, and any gold already sitting in
  `accrued` anywhere is swept once (`collect_all()`) so it isn't stranded.
  There is no way to automate only the Market and not the Power Exchange, or
  vice versa, in the current model.

### Market sale upgrade — resolved

`roadmap.md` flagged a mismatch between README's old "invest in Market sale
value" narrative and `sevkiyat.tres` not actually being upgradeable.
Resolved this pass, by explicit instruction: **Market Stall's upgrade was
removed on purpose** (no `upgradeable`, no `sale_value_bonus_per_level` in
`sevkiyat.tres`). This was not a silent revert — it's this round's decision.
The old README/DESIGN prose describing it as a live investment option is
stale and should not be treated as current behavior. Power Exchange keeps
its own, separate upgrade (`+20% sale value/level`) — the asymmetry between
the two Sevkiyat-category stations is intentional, not an oversight.

### Power unit — defined

- **Capacity**: an integer "power unit" a Generator makes available every
  tick (`power_output_at_level`), labeled "kW" in the UI as flavor, not a
  real physical unit. It is never stockpiled — unclaimed capacity in a tick
  is simply not delivered that tick, full stop, not banked for later
  (`FactorySim._phase_power` rebuilds `_delivered_power` from zero every
  tick).
- **Delivered energy equivalent** (Mill): the Mill needs
  `power_required_per_tick` (24) every tick it's actively running; over one
  item's `duration_ticks_at_level` (10 at level 1) that's 240 energy units
  total. At full power this completes in exactly 10 ticks — the same pace as
  if power didn't exist — because delivered power is capped at exactly what
  the Mill asked for (see `_phase_power`'s `mini(remaining, request)`), so
  above-100% power never speeds it up further.
- **Sale fraction** (Power Exchange): power is not sold per-unit; it
  accumulates in `energy_ticks` and converts to one discrete sale every
  `power_sale_batch` (100) units, each batch worth the Electricity item's
  `base_price` (4 gold, × the Exchange's own level multiplier). So the
  effective price is "4 gold per 100 kW-ticks delivered," not "4 gold per
  kW."

### Power sharing order for multiple consumers — documented

`FactorySim._phase_power()` processes each Generator's connected consumers
in **ascending station id order**, in two passes:

1. **Production consumers** (Mill-type) go first, each taking up to its full
   request (24) from whatever capacity is still left when its turn comes —
   this is **priority by id, not a fair split**. The lowest-id Mill always
   gets served first and takes its full request off the top; a second Mill
   sharing the same Generator gets whatever's left, which can be a *partial*
   amount (genuine proportional slowdown, e.g. 16 of 24 needed) or nothing at
   all if the first Mill already exhausted the capacity. There is no
   rotation between ticks — the same Mill always wins if nothing changes.
2. Whatever capacity remains after every production consumer is served is
   split **evenly** across connected sale consumers (Power Exchanges),
   remainder going to the lowest ids first.

This asymmetry (winner-take-all for production, even split for sale) is
intentional and matches the "simple, explainable, no priority menus" brief —
but it is a real behavior a player with two Mills would notice, and is not
currently surfaced anywhere in the UI beyond each node's own delivered/kW
stat. Recorded here so Paket B's test list and any future UI work start from
the same rule instead of two different guesses.

### Generator instance cap — resolved

`jenerator.tres` now has `max_instances = 1`, matching the Iron Mine. This
was a direct user decision after Paket C's measurement showed uncapped
duplication (3 Generator+Exchange pairs) beating every other strategy by
roughly 2× for comparable cost/time — see "Findings" under Paket C, and the
re-measurement below confirming the fix. A player who tries to build a
second Generator now gets the same "capped, upgrade the existing one
instead" message the Mine already gives (`GameController._on_add_requested`,
generic on `max_instances`, no new code needed).

## Save migration

Save v6 adds the power system (Generator/Power Exchange connections, the
Mill's energy accumulator) on top of v5's iron-route migration. Older v5 (and
v3–v4) saves load fine with no power stations or power links — the new
fields default to empty/zero and nothing is lost. Removed farm-era AND
removed armor/weapon-chain station types are both silently dropped the same
way (see `BlockCatalog.REMOVED_TYPE_IDS`).

## Not yet verified

Tracking `roadmap.md`'s package list — see there for the authoritative
sequencing. **Paket A, B, and C are done and were actually run** (Godot
4.6.1, `godot --headless`), not just reasoned through:

- Paket B: `sim_test.gd`, 35/35 checks passed (one bug found and fixed along
  the way — see roadmap.md §4).
- Paket C: `iron_progression_test.gd`, all 5 routes reached Automation; see
  the measured table and two open findings above.

Still open:

- **Paket D** (balance tuning) — now unblocked, with Paket C's measurements
  to work from instead of guesses. The Generator-cap decision and the
  Smelting Hearth throughput-ceiling problem are the concrete starting
  points.
- Whether 24 kW / 40 kW reads as a legible "the Mill is eating most of my
  power" moment in the actual flow-canvas UI, versus just being two numbers
  in a stats grid, is unplayed (Paket E/F territory) — none of this pass's
  testing was visual/interactive, only headless simulation.
