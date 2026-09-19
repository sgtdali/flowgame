# Trade Network

**File:** `data/block_types/trade_network.tres` · **Recipe:** `r_talep.tres` · **Category:** Source

## Role
The demand-side counterpart to a Mine — instead of gathering a material, it generates **Demand**, a control signal that a Trade Depot needs before it will sell anything. It plays no other role and produces nothing sellable on its own.

## In / Out
| | Item | Notes |
|---|---|---|
| Input | — | Sources have no input port. |
| Output | **Demand** | Never sellable (`base_price = 0`) — feeding it straight to a Collector earns nothing. It only means something once it reaches a Trade Depot's Demand port. |

## Rate & capacity
- Level 1: **8 Demand/sec**
- Output buffer capacity: 8
- Free to build, capped at **1 instance**

## Upgrade logic
- Cost: **80 gold** for the first upgrade, ×2 every level after (80 → 160 → 320 → 640 → …)
- Max level: 10
- Rate doubles every **2 levels**, same formula and whole-number snapping as the Iron Mine

## Downstream
Trade Network → **Trade Depot**'s Demand port (second input). See `trade_depot.md` for how Demand actually gates a sale.
