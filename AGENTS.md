# Project Instructions for Codex

This project is a modular Godot 4 game written primarily in GDScript. Its visual direction is a crisp, 2D, tile-based creature-catching RPG inspired by the readability of Pokémon HeartGold/SoulSilver. Maintainability and clear ownership matter more than minimising file count.

## Non-negotiable architecture rules

1. **One responsibility per file.** A script or scene should have one clear purpose. Do not build catch-all scripts that manage gameplay, input, rendering, UI, persistence, and networking together.
2. **Prefer cohesive small files over large multi-purpose files.** Creating an extra script, scene, resource, or directory is encouraged when it creates a meaningful boundary. Never cram unrelated code into one file merely to reduce file count.
3. **Split by feature and responsibility.** Keep a feature's scripts, scenes, and resources together when practical. Separate reusable systems from feature-specific behaviour.
4. **Keep Godot scenes composable.** Use child scenes for reusable visual/interactive elements. Keep scene scripts focused on coordinating their own nodes, not implementing unrelated game rules.
5. **Separate domain logic from presentation.** Creature stats, battle calculations, encounter rules, inventory operations, and similar mechanics should not depend on UI nodes or animation details. UI consumes state and raises intentions; systems own decisions.
6. **Use explicit interfaces and communication.** Prefer typed GDScript, signals for events, and narrow method calls. Avoid fragile deep node paths, dynamic string-based method calls, and hidden cross-feature dependencies.
7. **Keep global state minimal.** Use autoloads only for genuinely application-wide concerns (for example, display settings, save coordination, or scene transitions). Do not turn an autoload into a universal game manager.
8. **Prefer data-driven content.** Define creature species, moves, items, encounter tables, and other content as dedicated Resources or data files rather than giant match statements or hard-coded arrays in controllers.
9. **No speculative abstractions.** Extract shared modules when a responsibility is clear, not solely to introduce layers. A small, focused script can remain standalone.

## File size and refactoring guardrails

- Aim for most GDScript files to stay below **200 lines**. This is a guideline, not a reason to fragment tightly coupled logic arbitrarily.
- When a file approaches **250 lines**, reassess whether it has multiple responsibilities and split it if it does.
- Do not create or significantly expand a script beyond **400 lines** without a specific, documented justification in the final response. Prefer extracting coherent modules first.
- Functions should normally do one thing. If a function becomes long or handles several phases, split it into named helpers or move the responsibility to an appropriate collaborator.
- When modifying an existing large file, avoid adding more unrelated responsibilities. Refactor the touched area incrementally when safe and within scope.
- Do not manipulate these limits with terse, unreadable formatting or unnecessary one-line expressions.

## Godot-specific conventions

- Use **Godot 4** APIs and typed GDScript where useful. Prefer `class_name` only for types intended for broad reuse; avoid global class-name pollution.
- Keep `_ready`, `_process`, `_physics_process`, and `_input` concise; delegate substantive work to small methods or components.
- Use signals for decoupled events such as `health_changed`, `creature_selected`, and `display_mode_changed`. Connect/disconnect them at sensible lifecycle boundaries.
- Favour exported dependencies, local scene references, or explicit setup over traversing distant scene-tree paths.
- Separate `Resource` definitions (data), game-rule services (logic), `Node` controllers (coordination), and `Control` scenes (UI).
- Keep display/window settings in a dedicated display service; do not mix resolution switching with player movement, camera behaviour, or game options UI.
- Preserve pixel-art fundamentals: 32x32 world grid, 640x360 baseline viewport, nearest filtering, intentional camera movement and integer scaling where practical. Do not quietly change these conventions.
- Design player and UI input so keyboard and gamepad can coexist. Do not hardwire gameplay logic to a single input device.

## Suggested organisation (adapt to the project)

```text
res://
  core/                 # Cross-cutting services, shared utilities and transitions
    display/
    save/
  features/
    player/             # Player scene, movement, interaction
    world/              # Maps, terrain, encounters
    creatures/          # Creature data, instances, progression
    battle/             # Rules, turn flow, presentation in separate files
    inventory/          # Item models, operations, UI
  ui/                   # Shared UI widgets, menus, themes
  assets/               # Art, audio, fonts
  tests/                # Automated tests when available
```

The structure is an example, not a mandate to create unused directories. Place new code alongside the closest owning feature. Avoid generic dumping grounds such as `utils.gd`, `helpers.gd`, or `game_manager.gd` containing unrelated functions.

## Workflow for every coding request

1. **Inspect before editing.** Read relevant existing scripts/scenes and follow established naming and folder conventions. Check `project.godot` and any nested `AGENTS.md` instructions where applicable.
2. **State the intended boundaries.** For changes involving multiple responsibilities, briefly identify which scripts/scenes/resources will own each responsibility before implementing.
3. **Make the smallest coherent change.** Add focused files when appropriate; do not rewrite unrelated systems or create a sprawling framework.
4. **Maintain contracts.** Update callers, signals, resource types, and scene references together. Avoid circular dependencies and implicit singleton coupling.
5. **Verify.** Run available Godot import/parse checks, tests, or other relevant commands when feasible. Report clearly what was and was not validated.
6. **Summarise the architecture.** In the final handoff, list meaningful files added/changed and explain their responsibilities. Call out any oversized files that remain and why.

## Explicit anti-patterns to avoid

- A single `player.gd` handling movement, inventory, dialogue, combat, saving, and menus.
- A giant `battle.gd` combining damage formulas, turn scheduling, animations, audio, and combat UI.
- A single UI script controlling every screen and modal.
- Massive dictionaries of game content embedded in gameplay scripts.
- Autoloads that become mutable global registries for every feature.
- Copy-pasted systems in different scenes instead of a deliberately shared component.
- Splitting code into meaningless one-method wrappers just to satisfy a line count.

**If a request would naturally produce a monolithic implementation, proactively design and implement a small collection of cohesive files instead. This instruction applies even when the user asks for a feature in the singular.**

## Game art and PixelLab

Use the connected PixelLab MCP tools automatically whenever a task requires
creating or modifying pixel art assets. I do not need to explicitly mention
PixelLab in each request.

- Treat requests such as "add a building", "make the ground grass", or
  "add a walking animation" as instructions to generate any missing assets
  with PixelLab and integrate them into the game.
- Inspect existing assets first. Reuse suitable assets and generate only
  what is missing.
- Match the project's established art style, palette, perspective, tile
  size, sprite scale, and animation conventions. Use existing artwork as
  a reference where supported.
- Choose the appropriate PixelLab tools for characters, animations,
  objects, terrain, or tilesets.
- Download generated assets into the appropriate project folders and
  configure their import settings, scenes, tilemaps, and animations as
  needed. Complete the integration rather than only providing downloads.
- Preserve crisp pixel art using nearest-neighbour filtering and the
  project's existing scaling conventions.
- Proceed with routine generations without asking for confirmation.
  Start with the smallest useful generation and avoid unnecessary variants
  or repeated retries.
- If PixelLab is unavailable or a generation fails, explain the issue.
  Do not silently replace the requested art with placeholder graphics.