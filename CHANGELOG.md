# Changelog

## 0.1.0 - Steam Demo Candidate Pass

- Added main menu, continue game, settings, pause, save, failure, and demo completion screens.
- Added one-slot save/load through `SaveManager`.
- Reset the demo to a Day 1 public试玩 flow with explicit win and fail conditions.
- Added collision for visible base and city objects, containers, walls, ruins, the plane, gate, farm, animal pen, generator, lab, turret, and map bounds.
- Added interaction cooldowns, prompts, state feedback, farm/animal/generator/turret/crash-site interactions, and city scavenging feedback.
- Converted night walls into real physics blockers and made zombies collide with intact defenses.
- Added player emergency attack/fire behavior for night defense.
- Added polished HUD resource chips, status bars, warning colors, and objective text.
- Added runtime `AudioManager`, UI/SFX/Ambience buses, and generated WAV feedback.
- Regenerated unified dirty low-saturation pixel art and UI icons.
- Added Steam store source art and required capsule/library image outputs under `assets/steam_store/`.
- Added Windows demo export preset and Steam demo checklist documentation.
- Refactored night defense into an open grid-based base defense loop.
- Added free-placement build mode with occupancy checks, path-seal prevention, repair/demolish tools, power overlay, and threat overlay.
- Added building data for barricades, scrap walls, gates, electric wire, spike traps, flame traps, basic/shotgun turrets, spotlights, generators, batteries, power poles, workbenches, furnaces, farms, animal pens, and lab stations.
- Added dynamic multi-direction wave generation based on footprint, noise, smell, light, day, and tech pressure.
- Added expanded zombie data with building damage, target priorities, armor, fire weakness, pierce weakness, rewards, and spawn weights.
- Added item inventory, crafting recipes, facility requirements, city power decay, power reports, and skill growth.
- Added preview-matched AI source-sheet art pass for the core demo: scientist and zombie tile animation sheets, generated object cutouts, source/cutout folders, manifest-driven `ArtRegistry`, and runtime texture swaps for base, city, night defense, HUD, turrets, walls, and buildable defense objects.
- Added reusable art pipeline tools for ComfyUI health/submission, chroma-key cutout, atlas packing, AI-sheet extraction, and manifest validation.
- Migrated base, city, and night defense terrain to editable Godot `TileMapLayer` nodes using a shared `bunkertopia_tileset.tres`, so map layers and tile collisions can be configured manually in the editor.
- Added generated map objects, buildings, defense pieces, production facilities, wreckage, and city props as paintable TileSet sources, plus empty paint layers for manual scene editing.
- Rewired `BaseHub` to use a single editor-created `TileMap` node with the shared complete TileSet and named internal layers for manual map painting.
- Added a bunker/lab interior art kit with entrance, lab floor variants, wall panels, supercomputer, animated screen frames, bed, tables, locker, shelf, and chair assets.
