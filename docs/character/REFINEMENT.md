> Historical record of the earlier procedural character. The current game uses the [supplied sprites integration](supplied/README.md); current validation is 132 assertions plus a full-level traversal. Controller improvements below remain applicable.

# Character refinement — 2026-09-17

This update changes the player art, animations and control feel. The level, enemies' patrol behavior, collectibles, menus, progression and audio assets retain their existing design. A small enemy-contact change was necessary to preserve reliable stomps with the faster descent and rounded player collider. The menu portrait now consumes the same animation resource as the player.

## Visual comparison

The original 64px sprite overemphasized the head and ears, shortened the legs, and simplified the reference's robe and face. The new 128px source art has a broad seven-tail fan, a narrower three-quarter fox face, amber eyes, longer articulated legs, distinct paws, cream kimono sleeves and folds, burgundy lapels/cuffs, a layered sash, and an embroidered apron. Orange/rust/gold shading separates the tails.

This is an independently drawn pixel interpretation of the supplied image, not a copied bitmap. The character was generated locally with Python's standard library. No software, models, plugins, assets, or paid services were installed or purchased.

- [Interactive animation and before/after review](review.html)
- [Enlarged idle artwork](idle-detail.png)
- [Eight-state motion study](animation-review.mp4)
- [Rendered in-level playthrough](gameplay-review.mp4)
- [Animation contact sheet](animation-review.png)

The interactive review works locally in a browser. Non-looping actions repeat in the review tools for inspection; they play once in the game.

## Animation

There are **64 authored frames across eight states**: idle 12, run 12, jump 6, fall 8, dash 6, hurt 4, death 10, and landing 6. The same head, outfit patterns, palette, and limb lengths are used for every pose. The generator checks that its leg targets are reachable without stretching.

Idle combines breathing, a blink, and staggered tail sway. Running uses a twelve-frame stride with planted/swing phases, opposing arm motion, a forward lean, and faster playback matched to movement speed. Jump and fall have different limb postures. Dash has a reaching pose and a recovery; hurt has recoil; death settles into a side fall. Landing has authored compression/recovery and never locks out jumping or movement. Slight runtime spring motion is limited to a few percent, preserving the new proportions. The SpriteFrames resource also previews correctly in Godot's player scene.

## Movement differences

| Behavior | Previous | Refined |
| --- | --- | --- |
| Walk / run maximum | 225 / 335 px/s | Unchanged |
| Ground acceleration | 1700 px/s² | 2100 px/s² |
| Direction reversal | Ordinary acceleration | 3200 px/s² dedicated turning |
| Ground braking | 2100 px/s² | 2500 px/s² |
| Jump impulse | 530 px/s | 565 px/s |
| Gravity | 1350 px/s² in both directions | 1450 rising / 1900 falling; gentle held-jump apex |
| Measured held jump | 108.6 px | 115.7 px |
| Measured two-frame tap | 36.8 px | 41.4 px |
| Coyote / jump buffer | 120 / 140 ms | Preserved |
| Dash | 570 px/s, 180 ms, 700 ms recharge | 600 px/s, 180 ms, 650 ms recharge |
| Collider | 22 × 44 rectangle | Same-size rounded capsule |

A full run now develops in ten physics frames and stops in about 19.7 px after release. The dash retains its initial direction and returns directly to ordinary movement speed rather than sliding while its attack protection has ended. It still permits only one airborne use until landing.

Jump release now records intent while buffering: pressing and releasing before touchdown produces a short hop (measured 23px), rather than an unwanted full jump. Jump release no longer cuts an enemy bounce. Jump buffering can execute immediately on the landing step, and landing recovery yields to player input.

Enemy contacts use the swept foot position as well as downward velocity. This prevents a clean top hit from becoming side damage when an Area2D overlap is delivered after a fast movement step. Tests cover ordinary and terminal-speed descents.

## Build–test–refine passes

1. **Art/controller rebuild:** compared the supplied reference with the original sheet, separated the character generator from world generation, authored the eight-state rig and SpriteFrames resource, tuned the controller and capsule. Import succeeded; the initial game suite passed 100/101 checks. The new fall speed exposed a stomp timing regression.
2. **Contact reliability and visual review:** fixed stomp detection using the previous foot position, verified 101/101 game-flow checks, and completed the existing level through actual input. Added 28 character-specific checks. Those caught tail/paw clipping during the rotated death frames; gameplay checks passed.
3. **Animation bounds and final refinement:** aligned the full death silhouette inside each cell without scaling its anatomy, centered mirrored feet, increased run cadence and corrected the stance/body phase to avoid limb stretching. Final result: **129/129 assertions passed**, clean imports, and an input-driven full-level traversal with 45 embers, both checkpoints, and three lives. Rendered the full playthrough and eight-state motion review. World-art/audio hashes match the prior files exactly.

## Files changed

Player implementation:

- `scripts/player.gd` — tuned controller, animation selection, landing recovery, buffered-release intent, swept-foot data and rebound handling.
- `scenes/player.tscn` — capsule collider and editor-visible SpriteFrames resource.
- `assets/sprites/player.png` and new `player_frames.tres` — source atlas and animation definitions.
- `tools/generate_player.py` and `tools/pixel_canvas.py` — character rig and shared rasterizer.
- `tools/generate_assets.py` — delegates character generation to the focused generator; all other generated output is unchanged.

Required consumers and verification:

- `scripts/menu_art.gd` — reads the new idle animation rather than hardcoding 64px cells.
- `scripts/enemy.gd` — character stomp classification and top-hit alignment only.
- `tests/integration.gd`, new `tests/character.gd`, `tests/run_checks.sh` — updated frame expectations and targeted regression coverage.
- `tools/review_character.gd`, `docs/character/`, asset manifest and README files — reproducible reviews, measurements and documentation.
- Rebuilt `builds/embertrail.pck` and the project ZIP.

## Run and reproduce

Use the existing `launch_game.command`, or open `project.godot` and press F5. Controls are unchanged: A/D or arrows, Space jump, Shift run, X dash.

```sh
python3 tools/generate_player.py --review
./tests/run_checks.sh
godot --path . --fixed-fps 60 --script res://tools/review_character.gd
```

## Remaining limits

The art remains a stylized, procedurally articulated pixel interpretation; it does not reproduce every painted detail in the source. The single right-facing sheet is mirrored for left-facing movement, including asymmetric clothing details. The tail fan is decorative; collisions intentionally follow the narrow body. There is no separate melee attack beyond the existing dash/stomp. Verification covers automated physical playthroughs and rendered frame inspection, not human playtesting or controller hardware.
