# MageSlayer

M1 first-person movement and fireball prototype for a Roblox magic action roguelite. One test fireball is always available on LMB; no spell inventory, animations, progression or lobby yet.

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

## M1: Fireball (left hand only)

- **LMB:** fire a single fireball from the left side. **Hold LMB** to fire repeatedly at 0.30 s intervals.
- **Aim:** center reticle and native first-person mouse look. **RMB is reserved** for a future right-hand cast and does nothing now.
- **Visuals:** instant local muzzle flash, orange emissive projectile with a trail/embers, small impact burst; a temporary sample activation sound.
- **Physics:** fast projectile (175 studs/s), up to 145 studs, radius 0.58. The server checks the hand/spell request and cooldown, casts a sphere for hit detection, and can damage a struck Humanoid (placeholder 18 damage).
- **Architecture:** client predicts visuals for immediate feedback; the server owns collision/damage and replicates spawn/impact/expiry to all clients. Spell metadata names Fire as both school and element, and records future one-/two-hand support without exposing a second-hand mechanic.

### Required Studio checks for the fireball

1. Spawn and fire a single ball by tapping LMB; hold LMB and verify regular fire without stalling the run/bunnyhop.
2. Shoot the floor, stairs and walls: the fireball should burst on the first hit, not pass through it.
3. Test two Studio clients: the other client must see each projectile and its impact, while server damage is applied at most once.
4. Click in a menu or unfocus Studio: casting must not continue indefinitely. RMB should do nothing.
5. Confirm the old camera-pitch-drift bug has not returned.

The cast audio uses a Roblox tutorial sample sound as a temporary stand-in. VFX intensity, sound design, cooldown, damage and resource costs still require design/play-test passes. No gameplay is balanced yet.

## Validation

The GitHub workflow runs Python contract checks, official pinned Luau compiler syntax checks, MovementMath and FireballMath runtime tests, and an official Rojo place build. To run local contract checks:

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
