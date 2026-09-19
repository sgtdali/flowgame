# Trade Depot

**File:** `data/block_types/trade_depot.tres` · **Category:** Buffer (demand-gated, no pace of its own)

## Role
Holds one sellable good and waits for a matching Trade Network to "approve" the sale via Demand. This is the only place in the game where a *generic* good — Iron Ore, Ingots, Plates, anything sellable — can be gated by something other than a fixed recipe.

## In / Out
| Port | Item | Amount |
|---|---|---|
| Input: **Goods** | Any sellable item except Demand itself | 1 |
| Input: **Demand** | Demand (from a Trade Network) | 100 |
| Output | Same item that came in on Goods | 1 |

## How the gate actually works
1. Demand **cannot** enter the Demand port until at least one Good is already sitting in the Goods port. It won't pre-bank.
2. The moment a Good arrives, Demand starts accumulating (0 → 100), at whatever rate the connected Trade Network delivers it.
3. At exactly 100 Demand, the Good is sold through (Demand is consumed, the Good moves to Output) and the counter resets to 0 for the next Good.

This means the progress bar always climbs the full 0→100 range at the Trade Network's speed — it's never front-loaded or instant.

## Rate & capacity
- No pace of its own — throughput is `min(goods arrival rate, demand rate ÷ 100)`.
- Goods input buffer capacity: 20 (several goods can queue; only one is "being sold" at a time)
- Output buffer capacity: 8
- Free to build, unlimited instances

## Upgrade logic
Not upgradeable. Speed it up by upgrading the Trade Network feeding it, or by feeding it a faster-arriving good.

## Downstream
Trade Depot → **Collector** (sells for gold, same as any other good reaching a Collector).
