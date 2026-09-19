# Iron & Ember

A Godot 4 idle/incremental factory prototype: build short routes, then let
them earn for a long time with little intervention.

## This round's playable loop

1. Build `Iron Mine → Smelting Hearth → Market Stall`.
2. Collect the gold piling up at the market roughly every 30 in-game seconds
   with **Collect**.
3. Optionally invest 150 gold in Mine speed or Market sale value.
4. In parallel, research **Electrification** (1,100 gold), then build a
   **Generator** (900 gold) and a **Power Exchange** (300 gold). Wire the
   Generator to the Exchange and sell raw power — a second income line, with
   no ore, ingots, or route required.
5. Once both branches are running, research **Electrified Rolling** (1,600
   gold) and build the **Electric Rolling Mill** (900 gold — this reuses the
   existing plate-making workshop, now needing a power line as well as
   ingots). Wire the Smelting Hearth's ingots and a Generator's power line
   into it: plate sales beat selling the same ingots and electricity apart.

Workshops run themselves once wired correctly; the Mill also needs its power
line connected, or it idles even with a full ingot buffer. There is no
worker, food, farming, or hunger mechanic in the active game.

## Power, in short

Power is a capacity, not a stockpiled good — a Generator's kW never carries
over to the next tick. Each tick, a connected production consumer (the Mill)
is served first, up to what it actually needs; whatever capacity is left
over goes to a connected Power Exchange. Power wires are a visually and
mechanically separate connection type from material wires, so the two can
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
