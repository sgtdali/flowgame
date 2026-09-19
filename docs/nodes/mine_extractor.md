# Mine Extractor

**File:** `data/block_types/mine_extractor.tres` · **Recipe:** `r_cevher.tres` · **Category:** Process (no pace of its own)

## Role
Refines raw ore into usable Iron Ore. Works like the Smelting Hearth: no fixed processing time — it converts the instant enough Raw Ore has arrived.

## In / Out
| | Item | Amount |
|---|---|---|
| Input | Raw Ore | 100 per conversion |
| Output | **Iron Ore** | 1 per conversion |

## Rate & capacity
- No pace of its own (`duration_ticks = 0`) — its output speed is a direct function of how fast Raw Ore reaches it.
  - Example: an 8/sec Iron Mine feeding it gives 8 ÷ 100 = **0.08 Iron Ore/sec**.
- Input buffer capacity: 100 (exactly one batch's worth)
- Output buffer capacity: 8
- Free to build, unlimited instances

## Upgrade logic
Not upgradeable. Its only lever is upstream — upgrade the Iron Mine feeding it to raise its effective throughput.

## Progress bar
Fills as Raw Ore accumulates toward the 100 needed for the next Iron Ore (this is the same "input fill" mechanic the Smelting Hearth uses).

## Downstream
Its Iron Ore output can go to either:
- **Smelting Hearth** (needs 60 Iron Ore → Ingot), or
- **Trade Depot** directly (sell raw Iron Ore without smelting it).
