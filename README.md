# Iron & Ember

A Godot 4 idle/incremental factory prototype: build short routes, then let
them earn for a long time with little intervention.

## This round's playable loop

1. Build `Iron Mine → Smelting Hearth → Market Stall`.
2. Collect the gold piling up at the market roughly every 30 in-game seconds
   with **Collect**.
3. Optionally invest 150 gold in Mine speed or Market sale value.
4. In parallel, research **Electrification** (free), then build a
   **Generator** (900 gold) and a **Power Exchange** (300 gold). Wire the
   Generator to the Exchange, a **Trade Network** to its Demand port, then
   its Electricity output to a **Collector**. Every 1 kW plus 1 Demand makes
   one Electricity; gold waits at the Collector.
5. Once both branches are running, research **Electrified Rolling** (1,000
   gold) and build the **Electric Rolling Mill** (900 gold — this reuses the
   existing plate-making workshop, now needing a power line as well as
   ingots). Wire the Smelting Hearth's ingots and a Generator's power line
   into it: plate sales beat selling the same ingots and electricity apart.

Workshops run themselves once wired correctly; the Mill also needs its power
line connected, or it idles even with a full ingot buffer. There is no
worker, food, farming, or hunger mechanic in the active game.

## Power, in short

Power is a capacity, not a stockpiled good — a Generator's kW never carries
over to the next tick. Its direct power branches split capacity evenly: two
branches get half each; three get thirds, with any remainder going to the
lowest-id branch. Iron Mine and Trade Network material outputs use the same
round-robin split across their connected branches. Power wires are a visually
and mechanically separate connection type from material wires, so the two can
never be cross-wired by accident.

## Verification

```powershell
godot --headless --path . --script res://tools/sim_test.gd
godot --headless --path . --script res://tools/iron_progression_test.gd
```

The first command checks production, collection, and save/load correctness.
The second measures four small-investment routes through the iron branch's
opening from the same start. Neither was extended to cover Electrification
or the Electric Rolling Mill this round — see DESIGN.md's "Not yet verified"
section.
