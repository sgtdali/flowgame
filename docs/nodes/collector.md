# Collector

**File:** `data/block_types/sevkiyat.tres` (internal id `sevkiyat`, display name renamed to "Collector") · **Category:** Sink

## Role
The end of every trade route. Sells whatever reaches it, automatically, for gold.

## In / Out
| | Item | Notes |
|---|---|---|
| Input | Any sellable item | Generic port — no fixed recipe, accepts everything (Iron Ore, Ingots, Plates, …). |
| Output | — | Sinks have no output port. |

## How selling works
- A sale happens the instant an item arrives — there's no queue or delay.
- **Before the Automation research:** gold from sales piles up at the Collector itself ("Market: X gold") and needs the **Collect** button pressed to move it into the treasury.
- **After Automation:** sales go straight to the treasury; the Collect button and pending-gold row disappear.
- Input buffer capacity: 8 (mostly irrelevant since items sell on arrival). Output capacity: 0 (nothing leaves).

## Price
The Collector does **not** set prices — each item's `base_price` (defined on the item itself, e.g. Iron Ore) is what it sells for. Iron Ore's price can be raised independently via the **top-bar "Iron Ore" upgrade** (see below) — that's a global price upgrade, not something tied to any single Collector.

## Upgrade logic
The Collector itself is not upgradeable (no level, no button on the node). The only price lever currently in the game is the **Iron Ore sale-price upgrade** in the top bar:
- Cost: 800 gold, ×2 each purchase (800 → 1,600 → 3,200 → 6,400)
- Up to 5 purchases, each adding +100% of Iron Ore's base price (100 → 200 → 300 → 400 → 500)
- This affects Iron Ore's price everywhere it's sold, not just at one Collector.

## Upstream
Anything sellable can feed a Collector directly, or route through a **Trade Depot** first if you want the sale gated by Demand.
