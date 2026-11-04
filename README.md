# MageSlayer

M0.1 first-person movement prototype for a Roblox magic action roguelite. No combat, spells, progression or lobby yet.

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
| Build momentum | Keep running on the ground | Smooth charge to **30 studs/s** in **2 s** |
| Stop / reverse | Release or turn back | Immediate input response; run charge decays or takes a reversal penalty |
| Look | Mouse / right stick / touch | Native Roblox first-person camera; FOV **80 → 90** with speed (+2.2° pulse on jump) |
| Jump / bunnyhop | Space / gamepad jump / touch jump | Single **8-stud** jump; takeoff adds run charge and a small horizontal speed boost |
| Chain jumps | Hold Space or gamepad jump, or time repeated taps | Auto-hop on landing for keyboard/gamepad, quick consecutive hops stack a bonus up to **36 studs/s** |
| Forgiveness | Jump near a ledge or landing | **100 ms coyote time** and **120 ms input buffer** |

The default Roblox character controller handles movement, collision, and input. The camera uses native first-person aiming with speed-dependent wide FOV (80→90°, with brief +2.2° jump pulse), a tiny non-rotating strafe sway, head bob and a short landing dip; this approximates fisheye without a custom lens shader. Camera effects use an absolute Humanoid.CameraOffset and never change the aim orientation. Turn off `EnableHeadBob` in `src/shared/MovementConfig.luau` if necessary. Tune all numeric values in that module.

**Not in M0.1:** slide, dash, double jump, wall jump, flight, stamina, movement skills, magic, VFX and production animation.

## Validation

The GitHub workflow runs Python project-contract checks, the pinned official Luau compiler and MovementMath runtime tests, and an official Rojo place build. To run local contract checks:

```sh
python -m unittest discover -s tests -v
```

### Required manual Studio acceptance

- **Run:** from idle, press forward; compare 0 s / 1 s / 2 s speeds (20/25/30), release and rapidly reverse. No stuck movement or runaway acceleration.
- **Bunnyhop:** run and jump without losing horizontal velocity; hold Space to chain successive landings; speed should rise from 30 toward 36 and drop after stopping; jumping on the spot must not generate the bonus.
- **Jump:** test low and high steps and the gap islands; confirm the only available jump is the normal single jump.
- **Forgiveness:** walk just off a ledge then jump within ~100 ms; press jump immediately before landing (~120 ms); verify no mid-air double jump.
- **Camera:** aim rapidly, jump and land repeatedly; ensure no aim lag, FOV popping, severe shaking or nausea.
- **Lifecycle and devices:** die/respawn, enter a second run, and test keyboard/mouse, gamepad, touch (or device emulation).

**Limitations:** Roblox Studio physics/feel and multi-device acceptance cannot be certified by headless tests; must be checked manually. Runtime values are intentionally provisional until that play-test. Touch jump supports taps and the 120 ms buffer; hold-to-auto-hop is implemented for keyboard/gamepad, and needs further device testing. Competitive server-side speed validation should be added before PvP; M0 is not an anti-cheat layer.
