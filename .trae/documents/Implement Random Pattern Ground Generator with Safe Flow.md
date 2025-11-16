## Goals
- Generate tile ground with randomized yet safe patterns across the world width.
- Respect flows: Flat → Gap; Flat → Up → Gap; Flat → Gap → Down → Flat → Gap; Flat → Gap → Flat → Gap.
- Always finish with a Flat segment.
- Provide tunable parameters, seeded RNG consistency, accessibility validation and debug visualization.

## File & Structure
- Edit `scripts/terrain_generator.gd` (existing class `TerrainGenerator`).
- Add a new high‑level function `generate_world()` orchestrating the steps below.
- Break down generation into atomic helpers:
  - `begin_flat_base()` — build initial base flat across `world_width_tiles`.
  - `choose_next_pattern(rng)` — randomly pick the next pattern type.
  - `emit_flat(len)` — place a horizontal flat segment with caps as needed.
  - `emit_gap(width)` — carve a gap with proper caps and update cursor.
  - `emit_up(height, run_len)` — place 1‑tile hill up (up2→up or up→up2 according to art) respecting max height and step rules.
  - `emit_down(height, run_len)` — mirror of up, respecting safety rules.
  - `validate_transition(prev_y, next_y)` — ensures step size ≤ `max_step_height` and guarantees reachable tiles.
  - `finalize_border_and_debug()` — rebuild border lines and draw debug overlays.

## Parameters (exports)
- `flat_min_tiles`, `flat_max_tiles`: min/max width for a flat segment.
- `gap_min_tiles`, `gap_max_tiles`: min/max gap width.
- `hill_max_height`: clamp maximum vertical change allowed for up/down.
- `max_step_height`: limit per‑column vertical change (e.g., ≤ 1 tile) for accessibility.
- `rng_seed`: base seed (0 ⇒ randomized at runtime; deterministic in editor with preview seed).
- `enable_debug_visuals`: toggle debug overlays.

## Seed Consistency
- Use a single `RandomNumberGenerator` instance seeded via existing preview/runtime logic.
- Deterministic in editor when not regenerating; randomized per Regenerate click (reuse preview seed already implemented).

## Algorithm
1. Initialize cursor: `x=0`, `y=ground_y_tiles` and a `segments=[]`.
2. Build `begin_flat_base()` across `world_width_tiles` — this forms the baseline row (flat safety surface).
3. Reset cursor to start and iterate until `x >= world_width_tiles`:
   - Decide next pattern via `choose_next_pattern(rng)` among:
     - A: Flat → Gap
     - B: Flat → Up → Gap
     - C: Flat → Gap → Down → Flat → Gap
     - D: Flat → Gap → Flat → Gap
   - For each pattern:
     - Emit a flat segment `emit_flat(rng.randi_range(flat_min_tiles, flat_max_tiles))` (validation clamps to remaining width).
     - If “Up” in pattern, compute `height = min(1, hill_max_height)` and call `emit_up(height, 2)` ensuring `validate_transition` on each column; then call `emit_gap(rng.randi_range(gap_min_tiles, gap_max_tiles))`.
     - If “Down” in pattern, place `emit_gap(...)` first, then `emit_down(1, 2)`; follow with another `emit_flat(...)` and `emit_gap(...)`.
     - If “Flat after Gap” only, call `emit_gap(...)` then another `emit_flat(...)` then `emit_gap(...)`.
   - After each sub‑step, stop if remaining width ≤ 0.
4. Ensure last segment is a flat safety area: if the final columns are not flat, append `emit_flat(remaining)`.
5. Emit `generation_progress` periodically so UI stays responsive.
6. Call `finalize_border_and_debug()` to rebuild border lines and draw optional debug helpers.

## Accessibility Validation
- `validate_transition(prev_y, next_y)` with invariants:
  - `abs(next_y - prev_y) ≤ max_step_height` (default 1 tile).
  - `next_y` within `[hill_y_min, hill_y_max]` bounds.
- Clamp/dampen transitions that would violate constraints; fallback to `emit_flat(1)` if no safe placement possible.

## Debug Visualization
- When `enable_debug_visuals`:
  - Draw segment markers with a `Line2D` or colored `Sprite2D` for each pattern block: flat (green), gap (red line), up (blue arrow), down (yellow arrow).
  - Optionally place small labels (“FLAT”, “GAP”, “UP”, “DOWN”) above segments.

## Integration
- Replace current looping builder in `generate()` by calling `generate_world()`.
- Preserve existing tileset creation and caps logic; reuse `_surface_y_by_x` to build border.
- Keep editor/runtime seed behavior unmodified (already implemented).

## Validation Plan
- Editor: Toggle `Regenerate` multiple times; confirm patterns vary while ending with a flat.
- Runtime: Verify player can traverse transitions (no >1‑tile vertical jumps) and gaps are properly formed.
- Adjust parameters live to test min/max widths and max hill height.
