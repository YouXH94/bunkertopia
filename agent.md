
## Project
This is a Godot 4.x 2D pixel-art zombie apocalypse survival game prototype.

## Core direction
Build a hard survival vertical slice about a scientist surviving in a bunker, defending a base at night, scavenging a ruined city by day, and researching a cure.

## Engineering rules
- Use GDScript.
- Keep systems modular.
- Do not place all game logic in one Main.gd.
- Prefer Resources or data dictionaries for gameplay definitions.
- Use signals/EventBus for cross-system communication.
- Keep scenes small and composable.
- Maintain a runnable main scene at all times.

## Visual rules
- 2D oblique pixel-art style.
- Dark, dirty, low-saturation post-apocalyptic mood.
- Prioritize readability.
- If final art is unavailable, create consistent placeholder pixel art.
- Organize generated art under assets/art/.

## Done means
- The Godot project opens.
- The main scene runs.
- Player can move and interact.
- Base, city, night defense, research UI, resource UI, and event popups exist.
- README explains controls and current limitations.