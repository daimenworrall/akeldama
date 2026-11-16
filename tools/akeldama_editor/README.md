# Akeldama Editor

Run `make tools-editor` (or `make level-editor`) from the game project root.
This opens our standalone desktop application, not the Godot editor. The app is
built with Godot but has its own project, window, theme and workspace navigation.
`make editor` continues to open Godot for game development.

## Levels

- Left-drag paints grass/water terrain corners with a connected-tile preview.
- Starts fullscreen. Two-finger trackpad scrolling pans; pinch zooms at the pointer.
- Middle-drag or Space + left-drag also pan; the mouse wheel zooms.
- Spawn places the player on a fully grassy tile.
- Undo/Redo operate on strokes and spawn changes.
- New/Open and closing the application prompt before discarding unsaved changes.
- Save/Save As write `.tres` resources. Save the demo to
  `res://features/world/maps/demo.tres` and restart the game to use it.
- Red cells indicate diagonal-only transitions unsupported by this tileset.
  Connect or erase a corner before saving. Invalid spawns also prevent saving.
- New map dimensions count terrain corners. For a different map, assign its
  terrain resource to World in the game's Main.tscn.

## Tilesets and layers

The right sidebar has four tabs: **Layers** manages the stack and layer properties,
**Painting** shows tile/object choices for the selected layer, and **Lighting**
edits level lighting. **Inspect** selects placed NPCs and objects. Each tab scrolls independently. Select a layer in Layers,
then open Painting to choose its artwork; switching tabs preserves your selection.

The right panel lists layers from top to bottom (top draws last). Select a layer
before painting. Use +, Copy, Delete, ↑ and ↓ to manage the stack; rename in the
name field and press Enter. Visibility, locking and opacity are saved with the map
and included in Undo/Redo. Locked or hidden layers reject painting.

Terrain is the protected connected grass/water layer: use Grass/Water brushes.
It can be reordered, hidden and styled but cannot be copied or deleted. Terrain
collision always comes from the terrain corners, independent of visual visibility.

Add a tile layer, choose a tileset and click a tile in its palette, then paint in
the map. Erase removes tiles only from the active layer. Tilesets are discovered
recursively from `assets/tilesets/` at startup; PNG/WebP sheets must have dimensions
divisible by 64. Restart the editor after adding images so Godot imports them.
Changing sheets preserves valid atlas coordinates and removes out-of-range tiles;
Undo restores the prior sheet and tiles. The terrain atlas remains fixed to its
connected layout; ordinary tile layers support arbitrary 64px sheets.

Maps save the stack, textures, painted cells, ordering, opacity, visibility and
lock state. The game renders the same stack. Tile layers are visual only for now;
entity placement, tile collision painting and layers above actors are future work.
Existing maps receive a Terrain layer automatically when opened, without losing
terrain or spawn data.

## Objects and bridges

Click **+ Objects** in Layers, select Signpost, Vertical bridge or Horizontal bridge, and
click the map to stamp the full object. A translucent preview shows placement;
the green outline shows the walkable deck. The existing paint brushes stamp the
selected object on object layers; Erase removes the whole object under the cursor.
Object anchors snap to 64px cells while artwork keeps its original dimensions.
Place bridge ends on grass so both banks connect to the deck.

Signpost is a 64×64 wooden sign with a small solid footprint around its post base.
The player can walk behind its board or in front of it; depth sorts at the base.
It uses the existing placement tools and does not add dialogue.

Object layers support ordering, opacity, locking, visibility, duplication and undo.
Hidden object layers disable their gameplay surfaces too. Ground objects render beneath
the player; props with `depth_sorted` enabled sort alongside the player using their
`depth_anchor` in texture pixels. Their `collision` rectangle is also in texture
pixels and blocks the player's foot area without the shoreline buffer.
Bridge decks override terrain collision only within their authored
footprints. Bridge collision uses the foot area without the shoreline's 16px buffer,
so narrow decks remain usable; water beside the bridge remains blocked.

Definitions live in `features/world/objects/definitions/` and refer to artwork under
`assets/objects/`. Each definition stores the image, visual offset, walkable deck
and whether it provides a walkway. The picker discovers definition resources at
startup. An image alone does not define its gameplay behaviour: add a definition
for future object types. Placement resources store the chosen definition and cell.

## Level lighting

The sidebar's **Level lighting** controls save with each map and support Undo/Redo.
Use Ambient tint for overall brightness/color, then enable Cast ground shadows
and choose shadow color/opacity, angle and length. Zero degrees projects right;
90 degrees projects down. Existing levels default to white tint and shadows off.
The map preview shows prop shadows and tint; the game also projects the player's
current animation frame. UI remains untinted.

Object definitions opt in with `casts_shadow`, using `depth_anchor` as the ground
contact point. These are flat projected silhouettes, without light occlusion or
point-light sources. Bridges do not cast shadows by default.

Lighting data and rendering live in `features/world/lighting/`; the editor controls
live in `levels/lighting_panel.gd`. No generated artwork is required.

## Ownership

- `app/`: desktop shell, navigation, close handling, shared editor theme.
- `levels/`: level workspace controls, map canvas and editable document/history.
- `tests/`: editor document and persistence checks.
- `story/`: quest/conversation forms, content validation, history and disposable dialogue preview.
- Entities remains a planned workspace; stationary NPCs currently use object definitions.

The launcher creates relative links to the game's `assets/` and `features/`.
This keeps `res://` resource paths identical in the editor and game: editing a map
writes directly to game content, without duplicate resource definitions or copies.
Use the launcher after a fresh checkout so the links and imports are ready.
Set `GODOT_BIN` to use another Godot 4.6 executable.

The editor has no game autoloads or display settings. `tools/.gdignore` keeps it
outside the game's import scan; all game export presets also exclude `tools/*`.
The old Godot editor plugin has been removed.

## Checks

```
./scripts/run-editor.sh --headless --script res://tests/levels_smoke.gd
./scripts/run-editor.sh --headless --quit-after 3
```

Terrain collision uses straight edges from map corners, not decorative pixels,
with a 16px buffer around the player's foot area. No collision baking is needed.

## Inspect and story tools

Select **Inspect** in the sidebar or brush dropdown, then click a visible object.
The inspector shows its persistent ID (with Copy), instance name and conversation
assignment. Names commit with Enter or when focus leaves the field. Locked layers
can be inspected but not edited. IDs survive saves, renames and undo; copying an
object layer generates fresh IDs. Legacy maps receive IDs on open and must be saved.

Choose **Story** in workspace navigation. Quests contain ordered
interaction targets chosen by level/name; conversations contain entry nodes, lines,
player responses, quest-state conditions and start/complete actions. An empty response
destination ends the conversation. Nodes without responses display Close. The first
matching entry node wins. Save story validates IDs, entity targets, destinations,
conditions/actions and structurally unreachable nodes. Map and story changes have
separate Save and Undo/Redo controls; closing warns about either dirty document.
Save new placements in Levels too so their IDs exist when the game runs.

Select a conversation and use **Preview conversation** to test choices with a
simulated quest state. Preview never writes game progress. Inspector assignments
refresh from saved story content; restart the game after saving story changes.

### Demo

The demo places the professor near spawn (cell 4,2) and the noticeboard east of him
(cell 6,2). Face the professor and use **E / Enter / gamepad A**. Accept the request,
read the sign, then return and choose the report response. Arrow keys/D-pad navigate
responses; Enter/A selects; Escape/B closes dialogue. Movement is suspended while
speaking, and Escape closes dialogue without also opening Pause.

The quest status appears at the top left after acceptance. Quest progress saves
automatically to `user://quest_progress.json` and survives restarts. To replay from
scratch, remove that file from Godot's project user-data directory while the game
is closed. This first slice supports stationary NPCs, interaction objectives and
quest actions; inventory rewards, roaming NPCs and save slots
are not implemented.

### Story ownership and checks

- `features/quests/`: quest definitions, pure journal state and local persistence.
- `features/dialogue/`: conversation resources, branching session and dialogue UI.
- `features/story/`: catalog, validation, demo content and runtime coordination.
- `features/world/interaction/`: facing/range/reachability targeting.
- `levels/entity_inspector.gd`: instance inspection and conversation assignment.
- `story/`: content forms, named entity index and isolated conversation preview.

Run `tests/story_smoke.gd` and `tests/story_integration_smoke.gd` with the game's
Godot project, and `./scripts/run-editor.sh --headless --script
res://tests/story_editor_smoke.gd` for editor coverage. These use separate temporary
save files and do not overwrite player progress.

## Conversation graph

Story opens on **Conversations**. Select the professor conversation to see its
existing branches. Each card is one spoken line; gold output sockets correspond
to player responses, and blue input sockets receive the next line. Drag gold to
blue to connect or replace a destination. Right-click a connected socket to
unlink it. Unconnected responses end the conversation and display **[End]**.

Click a card to edit its line and responses in the right inspector. **Start here**
marks an entry, with optional quest-state rules. The response selector edits one
response at a time; **Quest condition / action** reveals optional quest controls.
Conditions and actions remain attached to entries/responses, rather than separate
runtime node types. Quest objectives still use the quest list editor.

Use **Add dialogue** and **Add response** to expand the flow. **Delete selected**
(or Delete on the graph) asks before removing cards; incoming responses become
conversation endings. Undo restores the cards and wires. Drag cards to rearrange,
middle-drag to pan, and use the wheel to zoom. **Fit** frames the conversation;
**Arrange** resets its layout. Card positions save with the story and support
Undo/Redo. Opening older conversations lays them out without changing gameplay.

**Preview conversation** runs the same dialogue data with simulated quest progress
and highlights the current card. Use **Save story** to persist edits. Graph
coordination, card rendering and the inspector live in separate scripts:
`conversation_form.gd`, `dialogue_graph_card.gd` and `dialogue_inspector.gd`.

Graph regression check:
`./scripts/run-editor.sh --headless --script res://tests/dialogue_graph_smoke.gd`.

## Quest prerequisites and player journal

In **Story → Quests**, select a quest and use **Requires completed quests** to
choose prerequisites by title. All checked quests must be **completed**; merely
accepting or finishing their objectives is insufficient. Missing references,
self-dependencies and cycles prevent saving. Runtime checks apply to every quest
start, including dialogue actions. Blocked offers are hidden. Existing accepted
quests are retained when loading older saves, even if content prerequisites change.

Set optional **Objective text** for each interaction target and **When objectives
are done** for the return/report instruction shown to the player. Blank objective
text falls back to the target's instance name. The conversation preview can
simulate locked/available/active/ready/completed states; simulating an unlocked
state also completes its prerequisites in the disposable preview journal.

Press **J / gamepad Y** to open the in-game quest journal. Active quests (including
those ready to report) and Completed quests have separate tabs. Select any quest
to see its description and objective checklist; Track quest chooses the one shown
on the HUD. Every active quest advances independently, whether tracked or not.
The world pauses while the journal is open; J, Escape, B or the close button returns
to play. Progress and the tracked selection save automatically, with support for
older progress files that have no tracking field.

Demo: accept the professor's notice request, then ask **Any other work I can do at
the same time?** for **Record the evacuation warning**. Both quests advance when
you read the noticeboard and can be reported separately. After completing
**Read the village notice**, **What should I do next?** offers **Confirm the
evacuation route**, which requires that first quest to be completed.

Dependencies and state live in `features/quests/`; journal panel, modal lifecycle,
and HUD tracking each have their own script under `features/quests/ui/`.
Additional checks: game `tests/quest_journal_smoke.gd` and
`tests/quest_journal_ui_smoke.gd`; editor `tests/quest_prerequisites_smoke.gd`.

### Temporary quest reset

In the in-game journal (**J / Y**), select an Active or Completed quest and choose
**Reset quest (temporary)**. Confirmation lists that quest and all quests whose
prerequisites depend on it, including indirect dependents. Confirming removes
acceptance, objective progress and completion for the entire affected chain, so
quests must be accepted again. Prerequisites and unrelated quests are retained;
tracked-quest selection is repaired and the reset saves automatically. Cancel
leaves progress unchanged. This is a temporary testing control.

Run game `tests/quest_reset_smoke.gd` for dependency cascade and persistence checks.

## Dama, types and moves

Select **Dama** in workspace navigation. Its top tabs are **Dama**, **Types** and
**Moves**; the searchable list selects the record being edited. **New** and
**Duplicate** create independent records with fresh stable IDs. Names remain
editable. **Save Dama content**, Undo and Redo operate on this catalog independently
of Levels and Story. Closing the application warns about unsaved changes in any
workspace. Deleting content is blocked while another record references it.

Species panels separate **Profile**, **Base stats**, **Evolutions** and **Moves**.
Profile assigns the original sprite sheet and up to two types, with direction/clip
preview controls. Base stats contains health, attack, defense, special attack,
special defense and speed. Evolutions define target species and minimum levels;
multiple targets create branches. Moves defines the level-up learning schedule,
including starting moves at level 1. Save rejects missing references, duplicate
entries, evolution cycles and invalid stat/level values.

Types edits damage **received** from each attacking type: 0 is immune, below 1
resists, 1 is neutral, above 1 is weak. Dual-type values multiply. The incoming
chart is the sole source of truth, so weakness and resistance lists cannot conflict.

Move rules configure type, damage category, base power, accuracy, Always hits,
maximum **mana points** (per-move uses) and priority. **Animation** assigns an
optional PNG/JSON effect and shows its clips with Replay, looping and FPS controls.
FPS 0 respects source timing. Flamethrower and Slash are configured examples.
Species stats, levels, types and move numbers are editable sample balance values.

Content lives in `features/dama/content/dama_catalog.tres`; full data semantics and
ownership are documented in `features/dama/README.md`. No battle flow is implemented
by this authoring workspace. Add new PNG/JSON pairs to the corresponding asset
folders and relaunch the tool to import them before assigning them.

## NPC teams and test battles

Select **Teams** in workspace navigation. New/Duplicate/Delete, Undo/Redo and
**Save NPC teams** operate on `features/teams/content/npc_teams.tres`. Each team
contains 1–6 Dama, with species, level, nickname and up to four explicit moves.
Automatic move sets use the latest four learned at that level. Explicit moves are
trainer overrides: they must exist, but need not be learned at that level. Save
Dama content before referencing newly created species or moves in a saved team.

In **Levels → Inspect**, select an NPC instance and assign its **NPC battle team**.
Save the level separately. Teams cannot be deleted while assigned to a saved or
currently open level; species/moves used in saved teams are protected from deletion.
Dama/Teams share content history, while each workspace keeps its own document.
Closing the editor warns about unsaved teams too.

Conversation response actions include **Battle this NPC's team** and **Restore
player party**. Battle uses the team on the interacting instance, so conversations
can be reused by several NPCs. Battle choices are hidden when no team is assigned.
Conversation preview only reports these actions; it never starts combat or writes
a player save. These actions end the conversation before opening their game flow.

The professor has a one-Dama test team and battle/heal options in each quest-state
entry. A separate player Cindlet is initialized in `user://game_save.json` on first
use; the player party is never authored in Teams. Battles show the player's Dama
lower-left and the opponent upper-right. See `features/battle/README.md` for battle
rules, controls, animation roles, save behavior and current limitations.
