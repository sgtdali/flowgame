# Iron Mine

**File:** `data/block_types/maden_ocagi.tres` · **Recipe:** `r_ham_cevher.tres` · **Category:** Source

## Role
The start of the iron route. Extracts Raw Ore from the ground, continuously, with no input of its own.

## In / Out
| | Item | Notes |
|---|---|---|
| Input | — | Sources have no input port. |
| Output | **Raw Ore** | Unrefined — not sellable, and not accepted by the Smelting Hearth. Must pass through a **Mine Extractor** first. |

## Rate & capacity
- Level 1: **8 Raw Ore/sec**
- Output buffer capacity: 8 (fills up and the mine stops if nothing downstream is draining it)
- Free to build, but capped at **1 instance**

## Upgrade logic
- Cost: **80 gold** for the first upgrade, ×2 every level after (80 → 160 → 320 → 640 → …)
- Max level: 10
- Rate doubles every **2 levels** (level 1 → 3 → 5 → 7 → 9 each double the previous)
- The engine always snaps the resulting rate to a whole number — you'll never see a fractional rate like "8.4/sec"

## Downstream
Iron Mine → **Mine Extractor** (Raw Ore in, Iron Ore out) → Smelting Hearth / Trade Depot.
