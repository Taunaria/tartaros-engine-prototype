# Implementation Status

## Implemented

- Playable `Game.tscn` root with player, level loading, camera follow, HUD, death screen, and victory screen.
- Warrior player with direct movement, wall collision, melee attack, HP, weapon switching, and restart loop.
- Three simple weapons:
  - Knueppel
  - Schwert
  - Axt
- Three enemy variants:
  - Zombie
  - Skelett
  - Abyss boss with a simple slam attack
- Six fixed handcrafted levels with:
  - 32x32 size
  - exactly one chest each
  - fixed enemy placement
  - linear progression
- Simple reward flow:
  - chest rewards
  - small enemy drops
  - healing pickups
- Blocky placeholder visuals drawn directly in Godot without external asset dependency.

## Deliberately Not Implemented

- No engine extraction.
- No framework or package system.
- No procedural level generator.
- No inventory UI or equipment screen.
- No crafting, merchant, quest, dialog, or class selection.
- No magic, skill tree, durability, or stat bloat.
- No multiplayer, save system, or advanced physics.
- No ranged skeleton variant yet.
- No image-generated art integrated yet, because placeholder visuals were enough to unblock the playable slice.

## Later Extraction Opportunities

- Level loading and tile/block rendering could later move into a reusable world module.
- HP / damage / reward helpers could later become a tiny shared gameplay library.
- Weapon definitions and enemy definitions could later be moved into reusable data resources.
- UI state handling for `playing`, `dead`, and `victory` could later be generalized if more game modes appear.

## Validation

- Parsed and instantiated with headless Godot via `scripts/dev/validate_project.sh` (wraps `godot --headless --quiet --no-header --log-file /tmp/tartarus-godot.log --path . --script res://scripts/dev/validate_project.gd --check-only`).
- The local Godot Mono build still prints `.NET: Assemblies not found`, but the GDScript prototype scene loads and the validation script exits successfully.
