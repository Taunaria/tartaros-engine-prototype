# Block Render Test

## Purpose

This scene is the first isolated step away from the flat top-down tile look.

It tests:
- pseudo-isometric grid placement
- cube-like block rendering with three visible faces
- shared texture atlas regions per tile type
- depth sorting by grid position
- entity markers using the same grid-to-screen mapping

## Files

- `scenes/visual/BlockRenderTest.tscn`
- `scenes/visual/BlockTile.tscn`
- `scripts/visual/block_render_test.gd`
- `scripts/visual/block_tile.gd`
- `scripts/visual/block_face_atlas.gd`
- `scripts/visual/entity_marker.gd`

## Current Scope

- Only a 10x10 test grid is migrated.
- Materials currently included:
  - grass
  - stone
  - wood
- Existing prototype levels are not migrated yet.
- Existing gameplay collision and level logic are intentionally unchanged for now.

## Verification

- Load test scene in Godot to inspect the live composition.
- Exported reference image:
  - `tmp/block_render_test_export.png`

## Next Step

If this visual direction is accepted, the next migration step should be:

1. Replace the flat floor rendering inside Level 1 with `BlockTile` instances.
2. Keep current gameplay logic and collisions unchanged.
3. Move player, enemies, chest, and exit placement onto the same isometric screen conversion.
4. Only then migrate the remaining levels.
