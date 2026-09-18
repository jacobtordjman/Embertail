# Supplied fox artwork integration

The runtime character now uses all 13 PNGs supplied by the user. Source copies in `assets/sprites/source_fox/` are unchanged; `provenance.json` records their original paths and SHA256 checksums.

## Three refinement passes

1. **Import and alignment:** replaced the procedural approximation with supplied art, aligned different crops to a common feet/body anchor, and generated a 160px-cell atlas. Fixed an importer type-inference error during Godot validation. Remaining issue: pale matte fringes and incomplete action sets.
2. **Visual and movement-state refinement:** cleaned only exterior neutral fringes in generated frames; added separate upright walk and leaning run selection, preserved the tuned collider/controller, and updated menu portraits. Inspected rendered gameplay and the nine-state animation review. Missing jump/fall/hurt/death drawings remain derived poses.
3. **Regression and delivery:** expanded character coverage to 31 checks, corrected fast-test audio cleanup, refreshed screenshots and videos, and rebuilt the distributable pack. Final suite: 101 integration + 31 character assertions; input-only completion with 45 embers, both checkpoints and all three lives.

## Animation design and limits

Nine states contain 44 playback frames: idle 8; walk/run/jump/fall/dash/hurt/land 4 each; death 8. This count includes repeats and transformed poses, not 44 separately drawn images. Idle, walk, run and dash use supplied art; jump/fall/hurt/death derive from translations and rotations; landing sequences supplied crouch/standing poses. A dedicated airborne and damage animation set is the next visual improvement. The short run cycle also benefits from more unique stride poses.

The sprite renders at 0.75 scale; its canvas anchor is (100,145). The capsule remains radius 11, height 44. Prior acceleration, jump buffering, coyote time, variable jump height and dash tuning remain intact; this pass improves the visual feedback for walking versus running without altering the tested level route.

## Main changed files

- `tools/import_player_sprites.gd`, `tools/generate_player.py`: reproducible import and fallback.
- `assets/sprites/source_fox/`, `player.png`, `player_frames.tres`: originals, atlas and animations.
- `scripts/player.gd`, `scenes/player.tscn`: anchoring, scale and walk/run animation selection.
- `scripts/menu_art.gd`: supplied-art portrait crop.
- `tests/character.gd`, `tools/review_character.gd`: regressions and rendered review.

Run `python3 tools/generate_player.py --review`, then `./tests/run_checks.sh` from the project root. Python and the already-installed Godot 4 suffice. See [interactive comparison](../review.html), [animation video](../animation-review.mp4), and [full traversal](../gameplay-review.mp4).
