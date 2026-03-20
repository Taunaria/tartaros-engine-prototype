# Isometric Migration

## What Changed

- The playable level path no longer relies on the flat `_draw()` top-down tile rendering.
- Levels now instantiate visible block tiles through `BlockTile.tscn`.
- The game still keeps simple 2D collision and movement logic in logical grid space.
- Rendering is projected into pseudo-isometric space through `IsoMapper`.

## New Render Path

- `scripts/core/iso.gd`
  - logical grid / world to screen conversion
  - render offset helper
  - level render origin helper
- `scripts/visual/block_tile.gd`
  - 3-face cube tile node
- `scripts/levels/level.gd`
  - builds block tiles for the full level
- player, enemies, chest, exit, and pickups
  - keep logical positions for collisions
  - draw at projected screen positions

## Intentional Non-Changes

- No 3D physics.
- No real 3D scene.
- No generic renderer framework.
- No data pipeline rewrite.

## Remaining Follow-Up

- Tune per-biome material variety beyond the current `grass`, `stone`, and `wood` starter set.
- Improve character visuals so they feel more native to the cube world than the current placeholder silhouettes.
- If needed, remap movement inputs to more directly match the projected view. This was not changed in this migration.
