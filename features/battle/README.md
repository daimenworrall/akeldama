# Test battles

Talk to the professor and select **Let's have a test battle.** His placed NPC
instance references `professor_test` in `features/teams/content/npc_teams.tres`.
This authored team contains one level-18 Cindlet. NPC battle state is created fresh
from the team; HP and MP never mutate the authored resources.

The player's first party is created separately on the first battle/healing request:
one level-20 Cindlet, equipped with its latest four learned moves. Its stable
instance ID, species, level, nickname, equipped moves, current HP and remaining
per-move mana points live in `user://game_save.json`. Player parties are not an
editor team definition. Existing saves are loaded instead of reseeding the party.
Malformed saves and missing content are reported without overwriting the file.
Quest progress continues using its existing separate file.

## Flow and controls

Choose moves with keyboard/gamepad focus or the mouse. Each turn selects an enemy
move with MP remaining. Priority acts first, then speed, then a random tie break.
MP is spent on attempted moves, including misses. Ember reuses the supplied
Flamethrower effect so the starting party can test both fire and Slash effects. HP, accuracy, type effectiveness,
same-type bonus, and physical/special attacking and defending stats affect damage.
Fainted actors cannot attack. The next healthy party member enters automatically;
the battle ends when either party is exhausted. No-MP creatures can use Struggle.
Withdraw (or Escape/B) ends the battle; Return restores overworld control. Input is
locked during an action animation. The overworld stays paused until returning.

HP and MP persist after each completed turn and on withdrawal. Select **Please
restore my Dama** in the professor's conversation to heal and refill the saved
party. Victory does not grant XP/rewards yet. Manual switching, capture, inventory
use, status effects, critical hits and automatic evolution are future work. Status
moves currently animate but have no gameplay effect.

The initial stat formula is `floor(2 * base * level / 100) + level + 10` for HP and
`floor(2 * base * level / 100) + 5` otherwise. Damaging moves use the level/power/
attack/defense formula in `rules/battle_damage.gd`, a 1.5 same-type bonus, the authored
type chart and 0.85–1.0 random variance. There are no IVs, EVs or natures in this slice.

## Presentation

The player is lower-left facing north-east; the opponent is upper-right facing
south-west. Character metadata names `physical` and `special` select the casting
animation; status moves also use `special`. Stable row-based clip keys are retained
for existing editor bindings. If a role is absent for the required direction, the
actor uses its directional idle pose rather than inventing a mismatched action.

Cindlet has both role/direction pairs and is used for the test teams. Seraphort also
has both pairs. The current Seraphlare metadata has no south-west `special` row;
that facing uses idle until its source metadata is corrected. Original images and
user-authored animation names are not rewritten. Configured move effects play from
the original sheet with their frame timings. Nearest filtering and integer actor
scales preserve pixel edges.

## Ownership

- `features/teams/data/`: authored NPC team resources and validation.
- `features/creatures/`: mutable owned creatures and level-scaled stats.
- `core/save/player_save.gd`: versioned player-party serialization.
- `rules/`: UI-independent turn plans, action resolution and damage.
- `battle_controller.gd`: lifecycle, turn presentation sequencing and persistence.
- `presentation/`: stage composition, directional animation, move effects, HP cards
  and move/result controls.
- `features/story/`: dispatches dialogue actions against the interacting NPC instance.

Checks: game `tests/battle_rules_smoke.gd`, `tests/battle_integration_smoke.gd`;
editor `tests/teams_smoke.gd`. Tests use temporary party save files, not player data.
