## Target
- Eliminate “typed as Variant” warnings (treated as errors) in `scripts/terrain_generator.gd` by adding explicit type annotations.

## Changes
- Replace `:=` with explicit type annotations for numeric and object variables:
  - `var h: int = 1080`
  - `var t: SceneTree = get_tree()`
  - `var tile_px: int = int(tile_size * tile_scale)`
  - `var baseline: int = (target_baseline_px if target_baseline_px > 0 else h - tile_px)`
  - `var w: int = min(gap_w, world_width_tiles - x)`
- Optionally annotate atlas sources to avoid Variant inference:
  - `var grass_src: TileSetAtlasSource = TileSetAtlasSource.new()`
  - same for `dirt_src`, `left_src`, `right_src`, `up_src`, `down_src`, `up2_src`, `down2_src`.
- Keep existing ints/bools: `x: int`, `y: int`, `gap_w: int`, `dir_up: bool` unchanged.

## Scope
- Only update `scripts/terrain_generator.gd`. No behavior changes.

## Validation
- Run a regenerate in editor; parser should load without Variant warnings.
- Confirm gameplay generation still works and produces the intended pattern.
