# MageSlayer

M0 first-person movement prototype for a Roblox magic action roguelite. No combat, spells, progression or lobby yet.

## Play in Roblox Studio

1. Download/clone this repository and install [Rojo 7](https://rojo.space/docs/v7/getting-started/installation/).
2. From this repository directory, run `rojo build -o MageSlayer.rbxlx`.
3. Open the generated `MageSlayer.rbxlx` in Roblox Studio and press **Play**. The server creates the temporary greybox automatically.
4. For iterative development, use `rojo serve` with the Rojo Studio plugin.

Rojo files map to `ReplicatedStorage`, `StarterPlayerScripts`, and `ServerScriptService`. The server script creates a floor, spawn, stepped obstacles, a turning corridor and jump islands. Test the generated place to avoid a pre-existing Baseplate covering the jump gaps.

## Controls and tuning

| Action | Input | Behaviour |
| --- | --- | --- |
| Move / run | WASD / left stick / touch joystick | Starts at **20 studs/s** without holding Shift |
| Build momentum | Keep running on the ground | Smooth charge to **25 studs/s** in **2 s** |
| Stop / reverse | Release or turn back | Immediate input response; run charge decays or takes a reversal penalty |
| Look | Mouse / right stick / touch | Native Roblox first-person camera; FOV **80 → 83** with speed |
| Jump | Space / gamepad jump / touch jump | Single **8-stud** jump, horizontal speed and run charge retained |
| Forgiveness | Jump near a ledge or landing | **100 ms coyote time** and **120 ms input buffer** |

The default Roblox character controller handles movement, collision, and input. The camera uses native first-person aiming with subtle head bob and a short landing dip; turn off `EnableHeadBob` in `src/shared/MovementConfig.luau` if necessary. Tune all numeric values in that module.

**Not in M0:** slide, dash, double jump, wall jump, flight, stamina, movement skills, magic, VFX and production animation.

## Validation

The GitHub workflow runs Python project-contract checks, a pinned official Luau compiler syntax pass and an official Rojo place build. To run local contract checks:

```sh
python -m unittest discover -s tests -v
```

### Required manual Studio acceptance

- **Run:** from idle, press forward; compare 0 s / 1 s / 2 s speeds; release and rapidly reverse. No stuck movement or runaway acceleration.
- **Jump:** run and jump without losing horizontal velocity; test low and high steps and the gap islands.
- **Forgiveness:** walk just off a ledge then jump within ~100 ms; press jump immediately before landing (~120 ms); verify no mid-air double jump.
- **Camera:** aim rapidly, jump and land repeatedly; ensure no aim lag, FOV popping, severe shaking or nausea.
- **Lifecycle and devices:** die/respawn, enter a second run, and test keyboard/mouse, gamepad, touch (or device emulation).

**Limitations:** Roblox Studio physics/feel and multi-device acceptance cannot be certified by headless tests; must be checked manually. Runtime values are intentionally provisional until that play-test. Competitive server-side speed validation should be added before PvP; M0 is not an anti-cheat layer.
