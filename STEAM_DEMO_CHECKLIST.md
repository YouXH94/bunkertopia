# Steam Demo Checklist

## Build Package

- [ ] Windows demo export preset exists and exports successfully.
- [ ] Build folder contains the `.exe` and `.pck`.
- [ ] Build launches outside the Godot editor.
- [ ] App icon appears correctly.
- [ ] No editor-only files are required at runtime.

## Main Menu And Exit

- [ ] Game boots to the Bunkertopia main menu.
- [ ] `New Game` starts the opening event and tutorial.
- [ ] `Continue Game` loads the single-slot save when present.
- [ ] `Settings` exposes fullscreen, resolution, and volume controls.
- [ ] `Quit` exits from main menu and pause menu.
- [ ] `Esc` opens pause and can resume.

## Controls And UX

- [ ] Keyboard controls work: WASD/arrow movement, `E`, `Space`, `R`, `B`, `Esc`.
- [ ] Mouse click can trigger emergency attack.
- [ ] Interaction prompts only appear in range.
- [ ] Low resource, base damage, and infection warnings are visible.
- [ ] UI has no debug-only shortcut text.
- [ ] UI panels close reliably.

## Gameplay Loop

- [ ] Opening event explains the goal.
- [ ] Player can reach the city and crash site.
- [ ] Scavenging changes resources and infection risk.
- [ ] Farm, animal pen, generator, turret, lab, containers, storage/base panel, gate, and walls are visible and usable.
- [ ] Build Mode opens with `B` and allows free placement on the grid.
- [ ] Placement preview turns green/red based on occupancy, boundaries, resources, and path sealing.
- [ ] Player can place, repair, and demolish defenses.
- [ ] Power Overlay shows powered/offline facilities.
- [ ] Threat Overlay shows expected horde directions and route pressure.
- [ ] Crafting UI can produce processed items at required facilities.
- [ ] Skills UI shows engineering/agriculture/husbandry/biology levels and book learning.
- [ ] Night horde starts from the base interaction.
- [ ] Turrets, wire, traps, lights, generators, and batteries interact with power/ammo/fuel limits.
- [ ] Zombies path dynamically around placed defenses and attack barriers if paths are blocked.
- [ ] Multiple zombie archetypes appear by day/threat budget.
- [ ] Dawn report appears and returns to base or completes the demo.
- [ ] Dawn report includes buildings destroyed, farm/animal losses, ammo waste, power state, and strategy hint.
- [ ] Demo completion triggers after cure milestone or surviving Night 3.
- [ ] Failure triggers on death/body collapse, base destruction, infection, or critical resource starvation.

## Collision

- [ ] Player cannot walk through walls, bunker, lab, animal pen, crash plane, city ruins, rubble, containers, gate, generator, farm plots, or turret.
- [ ] Zombies cannot pass through intact wall segments.
- [ ] Destroyed wall segments stop blocking zombies.
- [ ] Player remains inside world bounds in base, city, and night scenes.

## Art And Audio

- [ ] No visible pure-color placeholder art remains in gameplay.
- [ ] Scientist, walker zombie, runner zombie, brute zombie, bunker, plane, ruins, farm, animal pen, wall, gate, turret, generator, lab, containers, resources, UI icons, menu background, and Steam art exist.
- [ ] Button, pickup, door, gun, turret, zombie, alarm, generator, research, failure, damage, and ambience sounds are present.
- [ ] Audio buses are active for UI, SFX, and Ambience.

## Steam Store Assets

- [ ] Header Capsule `920x430`.
- [ ] Small Capsule `462x174`.
- [ ] Main Capsule `1232x706`.
- [ ] Vertical Capsule `748x896`.
- [ ] Library Capsule `600x900`.
- [ ] Library Hero `3840x1240`, no text.
- [ ] Library Logo `1280x720`, transparent background.
- [ ] Library Header `920x430`.
- [ ] At least five 16:9 gameplay screenshots are captured from the playable demo.
- [ ] Store capsules include only game artwork and the game name.
- [ ] No review quotes, discounts, awards, watermarks, or unrelated logos appear.

## Known Release Risks

- [ ] Balance pass for first-time players.
- [ ] Manual review of Steam art legibility at small sizes.
- [ ] Manual Windows build smoke test on a clean machine.
- [ ] Final public screenshots still need to be captured after visual QA.
