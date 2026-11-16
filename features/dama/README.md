# Dama content

`content/dama_catalog.tres` is the shared species/type/move catalog used by the
editor and available to the game. It contains editable example balance data for
Cindlet → Seraphlare (level 16) → Seraphort (level 36), eight types and six moves,
including Flamethrower and Slash. These values are starting points, not final balance.

## Ownership

- `data/`: typed Resource schemas and cross-reference/numeric validation.
- `rules/type_matchups.gd`: defensive multipliers, including dual types.
- `rules/species_progression.gd`: level-evolution eligibility and learned-move queries.
- `presentation/sheet_frames.gd`: sprite/effect metadata reading and SpriteFrames creation.
- `tools/akeldama_editor/dama/`: catalog history, navigation and focused editing panels.
- `tools/akeldama_editor/ui/content_fields.gd`: widgets shared with the Story editor.

There is no Dama autoload. Game systems load the catalog and query it explicitly.
Species definitions are templates, not owned creatures. Current HP, equipped moves
and remaining move MP belong to `features/creatures/`; turn and damage rules live
in `features/battle/`. The authoring resources remain independent of battle UI.

## Content semantics

IDs are stable within each content category. The tool generates IDs for new records
and keeps them read-only; changing a display name does not change references.

Species have one or two distinct types and six base stats: health, attack, defense,
special attack, special defense and speed. Evolutions refer to target species IDs
and minimum levels. Multiple evolution rules express branching lines. Learnset
entries refer to move IDs and learning levels; level 1 means a starting move.
Progression queries do not automatically evolve or equip moves. Evolution eligibility
uses `level >= minimum`; learnset queries return distinct moves in ascending level
order and do not impose an equipped-slot limit.

Each type stores incoming damage multipliers keyed by the attacking type ID.
Missing entries mean 1×. Values below 1 resist, values above 1 are weak and 0 is
immune. Dual-type defense multiplies both values (e.g. 0.5×0.5=0.25). There is one
authoritative chart; attack effectiveness is derived, not stored separately.

Moves define type, physical/special/status category, base power, percentage accuracy,
Always hits, maximum mana points and priority. MP is a per-move usage limit, not a
shared mana pool. Power is a future damage-calculation input, not fixed HP damage.
Status moves have zero power; damaging moves have positive power. Always hits
bypasses accuracy. Category data alone does not implement a status effect.

## Artwork

The tool discovers PNG/JSON pairs under `assets/characters/dama/` and
`assets/animations/`. Actual filenames take precedence over image names embedded
inside JSON, so the supplied renamed flamethrower sheet is supported.

Character metadata supplies cell dimensions, rotation directions and animation
rows. All three supplied species use their original 76/84/88px cells. Character
row clips use stable `row_<row>_<direction>` keys; rotation clips use `idle_<direction>`.
Effects use untrimmed, unrotated Aseprite-style frame arrays and forward/reverse
frame tags. Both supplied effects are supported: Flamethrower has 10 frames at
83ms each; Slash has 8 frames at 63ms each. Source metadata and image files are
not rewritten. Unsupported/malformed metadata prevents saving an assigned asset.

FPS 0 uses JSON frame durations, or 12 FPS for untimed character rows. A positive
FPS override makes the selected sheet's frames uniform at that rate. Looping is
editable; effects default to single playback in the examples. Previews use nearest
filtering and integer sprite zoom. Animation selection/playback settings are visual
bindings and do not affect move power or accuracy.

## Checks

Game: `Godot --headless --path . --script res://tests/dama_content_smoke.gd`

Editor: `./scripts/run-editor.sh --headless --script res://tests/dama_editor_smoke.gd`

Tests cover references, evolution cycles/levels, learning, matchups/immunity, both
metadata formats/timings, editing/history, duplication, guarded deletion, asset
assignment, roundtrip persistence, search and unsaved-close handling. Test saves
use separate `user://` paths and do not overwrite authored content.
