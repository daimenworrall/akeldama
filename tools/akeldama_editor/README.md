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

The right sidebar has three tabs: **Layers** manages the stack and layer properties,
**Painting** shows tile/object choices for the selected layer, and **Lighting**
edits level lighting. Each tab scrolls independently. Select a layer in Layers,
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
- Entities and Questlines are planned workspaces; their editors are not implemented.
  Future editors should have their own feature folder and workspace scene/script.

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
