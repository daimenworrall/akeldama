# Internal Level Editor

Run `make level-editor`, then select **Level Editor** in Godot's top workspace tabs.
The plugin is enabled in project settings. It is never referenced by gameplay and
`addons/level_editor/*` is excluded from every game export preset.

- Paint grass/water at terrain corners; connected tiles preview automatically.
- Middle-drag to pan, scroll to zoom. New map dimensions count terrain corners.
- Select Spawn and click a fully grassy tile.
- Undo/Redo operate on paint strokes and spawn changes.
- Open/Save/Save As use `.tres` terrain resources. New/Open prompt before discarding changes.
- Red cells indicate diagonal-only transitions missing from this tileset. Connect
  or erase a corner before saving. Invalid spawn locations also prevent saving.
- Save the demo to `features/world/maps/demo.tres` to update the running demo.
  Stop and restart the game after saving; maps are not hot-reloaded into play.
- For another map, assign the terrain resource to World in Main.tscn. World supplies it
  to TileGrid and Player and applies the spawn before the player initializes.

Runtime map data, rendering and movement remain in `features/world` and
`features/player`; authoring code remains in this excluded plugin folder.

## Terrain collision

Collision uses straight edges derived from the map's grass/water corners, with
straight diagonal cuts at corners. It does not follow decorative shoreline pixels.
The foot area has an extra 16px buffer. No collision baking is needed when artwork
changes. Movement uses small substeps and cancels blocked components for bank sliding.
