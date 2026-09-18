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

## Expansion pass 1 — real poses for the airborne arc and damage states

Date: 2026-09-18. Engine: Godot 4.7.1 (macOS).

**Observable weakness chosen.** Five of the nine states were not animation. `jump`
was four whole-image tilts of the crouch drawing, `fall` four tilts of a walk
drawing, `hurt` four tilts of a standing drawing, `death` eight rotations of a
standing drawing toward prone, and `dash` four translations of one burst drawing.
Only idle, walk and run showed different limb positions.

**What changed.** The supplied sheet's unused rows were classified visually
(`source_art/cuts`, rows 0–6; row 7 is items and effects, not character art).
Row 1 holds genuine airborne and touch-down poses and row 6 holds recoil, topple,
downed and kneeling poses. Fifteen crops were adopted into
`assets/sprites/source_fox/` with SHA256 provenance; fourteen are in use. The
active source pose count rose from 13 to 27.

`fox_r06_c03` and `fox_r06_c06` were rejected: each crop contains two overlapping
characters, so neither can be used as a single-character frame. The `names.json`
row labels proved unreliable, as the handoff warned — the row labelled `jump`
(row 2) actually holds crouch, ladder and crate-pushing poses, and one of its
entries is a crate prop with no character in it.

| State | Before | After |
| --- | --- | --- |
| jump | 4 tilts of the crouch drawing | 4 drawn poses: launch, rise, reach, hang |
| apex | absent | 2 drawn poses, looping, selected by vertical speed |
| fall | 4 tilts of a walk drawing | 4 frames from 3 drawn airborne poses |
| land | crouch, crouch, walk, stand | 4 frames: impact, recover, crouch, stand |
| hurt | 4 tilts of a standing drawing | 4 drawn poses: hit, topple, dazed, kneel |
| death | 8 rotations of a standing drawing | 4 frames from 3 drawn poses, settling prone |
| dash | 4 translations of one drawing | unchanged; the sheet has no second dash pose |

Counts: 9 states / 44 playback frames / 13 source poses → 10 states / 42 playback
frames / 27 source poses. Playback frames fell by two while drawn poses slightly
more than doubled; the old count included eight rotated death stills.

**Controller.** `scripts/player.gd` gained `APEX_SPEED` (90 px/s) and selects
ascent, apex and descent by vertical speed instead of a sign flip. The rising
test still runs before the floor test, so the take-off pose appears on the frame
the impulse is applied. No physics constant changed.

**Defect found and fixed during the pass.** The landing impact frame floated six
pixels above the shared floor line, so the character popped upward on contact
before dropping. Cause: that crop carries baked pale dust, which
`clean_matte_edge` strips as exterior matte, lifting the silhouette after the
anchor had been measured. The anchor is now measured post-cleaning. Grounded
feet spread: `land` 7 px → 1 px; every grounded state is now within 2 px.

**Anchoring note.** An automatic feet anchor was calibrated against the thirteen
hand-tuned anchors. Vertical placement predicts well (1.14 px spread), but
horizontal placement does not (3.6 px spread): the artist shifted the anchor
toward the direction of travel on leaning poses, and trailing tails and dust
pollute any bottom-band centroid. Horizontal anchors therefore remain reviewed
values, not generated ones.

**Validation.** `./tests/run_checks.sh` exits 0 with integration 101/101 and
character 38/38, up from 31 — seven assertions were added, not relaxed: the
grounded floor line, a minimum count of distinct atlas cells, apex presence and
looping, a non-looping ascent, immediate take-off pose, and apex-before-descent
ordering. The `>= 3 distinct poses` rule became `>= min(3, frame_count)` so a
two-frame apex is judged on every frame being distinct. The physical traversal is
unchanged at x=5993, 45 embers, both checkpoints, 13 jumps, 4 dashes, 19.08 s,
confirming the animation work did not disturb movement.

**Remaining limitations.** Dash is still one drawing. There is no start-run,
stop/skid, turnaround or victory state; `fox_r01_c09` (a braking skid) was
adopted and hashed but is not yet wired to a state, because skid needs new
controller logic and its own transition tests. Run is still a three-pose
ping-pong, so foot sliding at speed is unchanged. Hurt and death share their
first frame. Several adopted crops carry baked motion lines, stars or debris that
now render as part of the sprite alongside `burst.gd` effects.
