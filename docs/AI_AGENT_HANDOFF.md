# Embertrail: reproducible technical handoff for Claude Code

Workspace audit: **2026-09-18**, macOS, Godot **4.7.1.stable.official.a13da4feb**. Paths and counts below were checked against the files on disk. This guide describes observable code, assets, commands, and recorded test results. It contains no credentials or private agent instructions.

**Start here:** `/Users/JacobT/p/embertrail` is the active project. `/Users/JacobT/p/game` is a separate Godot project and asset collection, not another folder inside Embertrail. Their `res://` roots, player implementations, and animation loaders differ. Portable read-only copies of its character references are included under `source_art/` in the GitHub repository. Do not launch or edit the sibling project accidentally.

This documentation pass did not expand the animation set. The current baseline is **nine states / 44 playback frames derived from 13 supplied PNGs**. The next task is the character-only expansion described at the end. No new image-generation service, package, or plugin is needed to read, run, or regenerate the current Embertrail project.

## 1. Project overview and verified state

**Embertrail: The Last Lantern** is a short original 2D side-scrolling platformer. A many-tailed fox spirit crosses Lanternwood, collects embers, avoids thorns and pits, defeats moss beetles by stomping or dashing, activates checkpoint lanterns, and reaches the final shrine. Embers are optional; reaching the shrine wins.

The level spans 6,240 world pixels and contains 17 raised platforms, four gaps, five thorn beds, six beetles, 84 embers, two checkpoints, and one goal. The player starts with three hearts and three lives. Death consumes a life and returns to the latest checkpoint; defeated enemies and collected embers stay removed until a full restart. Checkpoints restore health. Main menu, pause/resume, game over, level complete, and replay are implemented.

The project uses GDScript, Godot's compatibility renderer, a 960×540 logical viewport displayed at 1280×720 by default, nearest-neighbor sprite filtering, and 60 Hz physics. `project.godot` advertises `4.3`/GL Compatibility features, but **4.7.1 is the tested engine**, not a claim of testing on every Godot 4 release.

Fresh audit validation:

- `tests/integration.gd`: **101/101** passing assertions.
- `tests/character.gd`: **31/31** passing assertions.
- `tests/traversal.gd`: actual input/collision completion at x=5993, 45 embers, both checkpoints, 13 jumps, four dashes, three lives; 19.08 simulated seconds.
- No `ERROR:` or `SCRIPT ERROR:` in the successful runner output. Current logs are under `tests/results/`.
- Prior rendered reviews and a packed-build launch are recorded under `docs/character/supplied/`.

These tests verify behavior; they do not establish that the animation is artistically finished. The current motion set is visibly limited: repeated run/idle frames, no dedicated start/stop/turn/apex states, and whole-image transforms for several missing actions. Audio is synthesized placeholder work. There is one level and enemy type, no save/rebinding screen, and no verified Windows/Linux/controller-hardware release. The `.pck` requires Godot; it is not a standalone application.

## 2. Exact workspace map

All relative paths in the following active-project tables are relative to **`/Users/JacobT/p/embertrail/`**. `res://foo` means that root plus `foo`.

Classification: **authored** = editable code/configuration or prose; **source** = preserved input art; **generated** = rebuild from its producer; **cache** = Godot/Python-managed output. Runtime-generated objects may have no corresponding image or scene file.

### Entry points, configuration, scenes, and scripts

| Exact relative path | Role / consumer | Classification and edit policy |
| --- | --- | --- |
| `project.godot` | Godot configuration; starts `res://scenes/main.tscn` | Authored; edit deliberately or through editor |
| `launch_game.command` | macOS/shell launcher; imports assets then launches Godot | Authored; edit for launcher behavior |
| `export_presets.cfg` | `Desktop Pack` resource-pack export; excludes `source_art/` from the runtime pack | Authored; update export settings here |
| `.gitignore` | Excludes `.godot`, import sidecars, logs, Python cache; packaged PCK remains tracked | Authored; repository is `jacobtordjman/Embertail` |
| `LICENSE` | BSD 3-Clause license supplied by the destination repository | Existing repository file; preserve |
| `scenes/main.tscn` → `scripts/main.gd` | Main Node, world creation, input map, states, sound, camera, score | Authored; main scene processes even while paused |
| `scenes/player.tscn` → `scripts/player.gd` | `EmberPlayer` CharacterBody2D, AnimatedSprite2D, capsule collision | Authored; primary animation-integration files |
| `scenes/enemy.tscn` → `scripts/enemy.gd` | Patrol beetle, Sprite2D, contact Area2D, stomp/dash defeat | Authored; preserve during character-only work |
| `scenes/collectible.tscn` → `scripts/collectible.gd` | Animated ember pickup Area2D | Authored |
| `scenes/hazard.tscn` → `scripts/hazard.gd` | Thorn Area2D, code-drawn art, repeated overlap damage | Authored |
| `scenes/checkpoint.tscn` → `scripts/checkpoint.gd` | Lantern Area2D and code-drawn glow | Authored |
| `scenes/level_goal.tscn` → `scripts/level_goal.gd` | Shrine Area2D and code-drawn goal | Authored |
| `levels/lanternwood.tscn` → `scripts/level.gd` | Level root; constructs terrain and entity placement at runtime | Authored; terrain arrays are the layout source |
| `ui/hud.tscn` → `scripts/hud.gd` | Health/lives, score/embers, timer, progress, dash readiness, notifications | Authored; Controls are constructed in code |
| `ui/menus.tscn` → `scripts/menus.gd` | Menu/pause/game-over/complete panels and buttons | Authored; emits `action_selected` to main |
| `scripts/menu_art.gd` | Animated menu fox portrait from player idle frames | Authored; depends on atlas metadata/crop |
| `scripts/backdrop.gd` | Parallax drawing, layered sky/foliage/motes | Authored; attached to a Node2D under a CanvasLayer |
| `scripts/burst.gd` | Runtime dust, sparkles, dash, damage and defeat motes | Authored; creates/draws lightweight particles |

There is **no authored TileMap/TileMapLayer, TileSet `.tres`, AnimationPlayer, skeleton rig, particle `.tscn`, or `.blend` file in Embertrail**. Terrain uses StaticBody2D/RectangleShape2D plus drawing calls. Player animation uses AnimatedSprite2D/SpriteFrames. Do not look for editor-painted tiles or an animation timeline that does not exist.

### Active assets and their producers

| Exact relative path | Shape / purpose / consumer | Classification; modify by |
| --- | --- | --- |
| `assets/sprites/source_fox/` | 13 original user-supplied cropped PNGs; importer inputs | Source; preserve unchanged |
| `source_art/character_reference.png` | Portable copy of the initial 1024×572 reference | Source; preserve unchanged, not used at runtime |
| `source_art/character_sheet.png`, `source_art/character_index.png` | Portable copies of the larger composite sheet and visual index | Source/review; preserve, inspect before selecting new poses |
| `source_art/cuts/` | 162 existing extra cropped character PNGs plus manifest/names | Source candidates; not active runtime inputs |
| `source_art/legacy_animations/` | Existing padded frames, strips and JSON from the sibling project | Reference candidates; visually check labels and metadata |
| `source_art/README.md` | Portable art inventory and provenance caveats | Authored; update when adding art |
| `assets/sprites/source_fox/provenance.json` | Original workspace-relative paths and SHA256 for each copy | Authored provenance record; append verified entries for new sources |
| `assets/sprites/player.png` | 1280×1440 RGBA atlas, 160px cells, eight columns, nine rows | Generated by `tools/import_player_sprites.gd`; consumed through SpriteFrames |
| `assets/sprites/player_frames.tres` | AtlasTexture regions, nine animation definitions, anchor/portrait metadata | Generated by importer; player scene and menu art load it |
| `assets/sprites/enemy.png` | 160×64, 40×32 cells, four columns; beetle motion/defeat art | Generated by `tools/generate_assets.py`; enemy scene/script |
| `assets/sprites/coin.png` | 144×24, six 24px frames | Generated by same script; collectible scene/script |
| `assets/sprites/heart.png` | 16×16 HUD icon | Generated by same script; `scripts/hud.gd` |
| `assets/tiles/terrain.png` | 128×32, four 32px tile images | Generated by same script; `scripts/level.gd` draws texture regions |
| `assets/backgrounds/mountains.png` | 960×360 transparent parallax layer | Generated by same script; `scripts/backdrop.gd` |
| `assets/backgrounds/trees.png` | 960×360 transparent parallax layer | Generated by same script; `scripts/backdrop.gd` |
| `assets/effects/sparkle.png` | 64×16, four 16px effect frames | Generated by same script; shipped but current burst code draws rectangles instead |
| `assets/audio/jump.wav` | Rising triangle chirp | Generated by same script; main sound loader / player signal |
| `assets/audio/coin.wav` | Two-note pickup | Generated; main / collectible |
| `assets/audio/hurt.wav` | Descending noisy impact | Generated; main / player |
| `assets/audio/enemy.wav` | Three-note defeat | Generated; main / enemy |
| `assets/audio/checkpoint.wav` | Ascending checkpoint phrase | Generated; main / checkpoint |
| `assets/audio/complete.wav` | Completion phrase; source code contains six note events | Generated; main / goal |
| `assets/audio/dash.wav` | Short whoosh | Generated; main / player |
| `assets/audio/land.wav` | Quiet short impact | Generated; main / player |
| `assets/audio/music.wav` | 16-second synthesized ambient loop | Generated; main loops WAV samples |
| `assets/ASSET_MANIFEST.md` | Asset layouts and provenance summary | Authored documentation; update with generators |
| `assets/**/*.import` | Godot import settings/remaps for PNG/WAV inputs | Godot-managed; change settings through import workflow, never edit `.ctex` caches |
| `.godot/` | Imported textures/audio/editor/class caches | Cache; do not hand-edit or use as source |
| `scripts/*.gd.uid`, `tools/*.gd.uid`, `tests/*.gd.uid` where present | Godot script identity sidecars | Godot-managed; keep identities stable when moving files |

All active non-player art and audio were created by local drawing/synthesis code. The supplied fox images are **user-provided source art**, not newly authored by the local generator. The project does not contain evidence establishing how the original supplied sheet was made or its upstream license; do not invent provenance or claim it is procedurally generated from scratch.

### Tools, tests, documentation, and delivery

| Exact relative path | Purpose | Classification / editing |
| --- | --- | --- |
| `tools/import_player_sprites.gd` | Current source-art alignment/cleanup/pose/atlas/resource generator | Authored; edit this for current player atlas production |
| `tools/generate_player.py` | Wrapper selecting supplied importer; contains earlier procedural fallback | Authored; entry point for character-only regeneration |
| `tools/pixel_canvas.py` | Standard-library RGBA rasterizer and PNG writer | Authored; polygons/lines/ellipses, used by world/fallback generation |
| `tools/generate_assets.py` | Rebuilds player, world PNGs and all nine WAVs | Authored; avoid for a character-only change unless deliberately testing complete reproduction |
| `tools/review_character.gd` | Rendered nine-state animation review; saves screenshot at frame 180 | Authored; update state list/layout with animation expansion |
| `tools/capture_screens.gd` | Captures menu, gameplay, pause, game over, complete | Authored; intentionally sets up states and teleports near goal for capture |
| `tests/run_checks.sh` | Editor import + three SceneTree test harnesses; catches logged errors even on exit 0 | Authored; canonical project check command |
| `tests/integration.gd` | 101 resource, UI, physics, interaction and game-flow checks | Authored; preserve behavioral coverage |
| `tests/traversal.gd` | Physical full-level run using real input actions | Authored; no teleport/health overrides |
| `tests/character.gd` | 31 atlas/state/controller/collision regressions | Authored; update structural expectations for expanded sheet; keep behavioral assertions |
| `tests/results/{import,integration,traversal,character}.log` | Latest runner console outputs | Generated; runner overwrites |
| `tests/results/{import,integration,traversal,character}.engine.log` | Latest Godot engine logs | Generated; runner overwrites |
| `tests/README.md` | Test instructions and historical results | Authored |
| `README.md` | Run instructions, controls, current summary | Authored |
| `docs/BUILD_PASSES.md` | Historical three-pass original game build | Authored record; older controller values/counts are historical |
| `docs/character/REFINEMENT.md` | Historical procedural-character/controller refinement | Authored record; explicitly superseded for current sprite art |
| `docs/character/supplied/README.md` | Current supplied-art integration and three-pass record | Authored |
| `docs/character/review.html` | Local interactive atlas review, speed/pause/facing, old/new comparison | Authored HTML/JS; hardcoded cell/state data must be updated with new atlas |
| `docs/AI_AGENT_HANDOFF.md` | This guide | Authored; update after next implementation |
| `docs/{menu,gameplay,pause,game_over,complete}.png` | Current five-screen review | Generated by capture harness |
| `docs/character/animation-review.png` | Current nine-state motion board | Generated by review harness |
| `docs/character/animation-review.mp4` | Rendered current motion review | Godot movie output converted with ffmpeg |
| `docs/character/gameplay-review.mp4` | Current rendered physical traversal | Godot movie output converted with ffmpeg |
| `docs/character/supplied/idle-detail.png` | Current enlarged idle on dark background | Generated by importer |
| `docs/character/supplied/packed-player.png` | Supplied-art packed-build screenshot | Generated via main's `--capture` argument |
| `docs/character/supplied/previous-procedural.png` | Preserved former atlas; HTML comparison input | Historical generated backup; retain |
| `docs/packed-menu.png` | Earlier packed menu capture | Historical output |
| `docs/character/{launcher-menu,packed-player,player-before,running-in-level,pose-review,idle-detail}.png` | Earlier procedural-character reviews | Historical outputs; do not mistake for current artwork |
| `docs/*.log`, `docs/character/*.log`, `docs/character/supplied/*.log` | Historical build/review/export diagnostics | Generated records; old failures are not evidence the current build fails |
| `builds/embertrail.pck` | Resource pack, tested with Godot 4.7.1 | Generated by export preset; rebuild after runtime changes |
| `tools/__pycache__/` | Python bytecode | Cache; ignore |

`/Users/JacobT/p/embertrail.zip` is a previously built project archive outside the project root and is not part of this Git repository. Rebuild it after changes if delivering a ZIP. The GitHub repository is `https://github.com/jacobtordjman/Embertail` and places these project files at its root. No standalone `.app`, Windows `.exe`, or Linux executable was produced for Embertrail. The local Godot export-template directory exists but is empty.

## 3. Source images and the sibling asset collection

### Initial reference and active source copies

The initial reference image exists at:

`/Users/JacobT/p/a64f5852-f462-4bde-a16d-debc126e082d.png` — **1024×572**.

It informed the earlier procedural fox: orange/rust fur, golden tail tips, pointed ears, cream wrap robe, burgundy lapels/belt/trim, tan trousers, confident fox face, and a multi-tail silhouette. The current small supplied sprites are the accepted **style anchor**; preserve their three-quarter face and swept tails rather than reverting to the earlier broad symmetric procedural fan. The large reference is not embedded in Embertrail's runtime pack; a read-only portable copy is `source_art/character_reference.png`.

Each filename below exists in both directories:

- Original: `/Users/JacobT/p/game/assets/cut/character/`
- Preserved active-project copy: `/Users/JacobT/p/embertrail/assets/sprites/source_fox/`

```text
fox_r00_c00.png  fox_r00_c01.png  fox_r00_c02.png  fox_r00_c03.png
fox_r00_c05.png  fox_r00_c06.png  fox_r00_c07.png  fox_r00_c08.png
fox_r00_c09.png  fox_r00_c10.png  fox_r00_c11.png  fox_r00_c14.png
fox_r01_c00.png
```

All 13 copies were compared byte-for-byte with their originals and verified against `provenance.json` during this audit. These are tight crops of differing sizes, not uniform runtime cells. Active Embertrail does **not** currently save every atlas frame as a separate PNG; the individual source PNGs above are inputs, and playback frames are regions in `player.png`.

### Additional existing assets: available, not integrated into Embertrail

The following original paths are relative to **`/Users/JacobT/p/`**, not the active project. A clone of the GitHub repository also contains portable copies in `source_art/`, so the source images remain available without this sibling folder:

| Exact relative path | Purpose and origin status | Policy |
| --- | --- | --- |
| `game/project.godot` | Separate project named `Fox`; main scene `res://levels/main.tscn` within `game/` | Do not modify for Embertrail animation work |
| `game/assets/raw/assets_character1.png` | 1536×1024 composite character sheet; visibly contains the supplied poses and additional actions/effects | Preserve source; upstream creation history is not established here |
| `game/assets/raw/assets1.png` | Separate world composite sheet | Not used in Embertrail; preserve |
| `game/assets/INDEX_character.png` | 1652×1728 labeled contact-sheet overview | Generated review; useful for locating poses |
| `game/assets/cut/character/manifest.json` | Crop coordinates, dimensions, row/column and areas; declares 167 assets | Generated by sibling cutter; see missing-file caveat |
| `game/assets/cut/character/names.json` | Filename → semantic-group labels | Authored/editable mapping over generated names; labels require visual review |
| `game/assets/cut/character/fox_rNN_cNN.png` | 162 existing tightly cropped PNGs | Source candidates; do not silently overwrite/re-cut |
| `game/assets/lib/character/` | 167 semantic-name PNG copies | Generated by `game/tools/name_assets.py apply`; may retain copies missing from `cut/` |
| `game/assets/cut/world/{manifest,names}.json`, `game/assets/cut/world/` | Sibling world crops/mappings | Not active Embertrail inputs |
| `game/assets/lib/world/` | 98 named world PNGs | Generated sibling assets, not active Embertrail art |
| `game/assets/anim/` | Padded per-action PNGs, strips and metadata below | Generated sibling animation resources; not referenced by Embertrail |
| `game/tools/cut_assets.py` | Native-size crop/background-removal utility | Requires Pillow + NumPy; inspect settings before reuse |
| `game/tools/name_assets.py` | `plan` writes maps; `apply` recreates named libraries | Standard-library helper; `apply` deletes/recreates destinations |
| `game/tools/pack_anim.py` | Packs named groups into padded frames/strips/JSON | Requires Pillow + NumPy; not the active importer |
| `game/tools/contact_sheet.py` | Labeled contact sheet of cuts | Requires Pillow |
| `game/tools/row_strip.py` | Review selected manifest rows | Requires Pillow |
| `game/systems/anim_loader.gd` | Runtime loader of sibling numbered PNGs + anchor JSON | Uses Image.load_from_file; differs from Embertrail's imported atlas |
| `game/hero/player.gd`, `game/levels/{main.tscn,world.gd}` | Sibling player/level implementation | Do not transplant controller wholesale |
| `game/entities/{coin,patrol_enemy}.gd`, `game/systems/{lib,autoplay}.gd` | Sibling gameplay/helpers | Separate implementation; no dependency from Embertrail |

Exact sibling animation files follow `game/assets/anim/character_NAME.json`, `game/assets/anim/character_NAME/000.png` through the final index below. Strips are `game/assets/anim/character_NAME_strip.png` where listed.

| NAME | PNG indices / count | Uniform frame size | Anchor | Strip exists? |
| --- | --- | --- | --- | --- |
| idle | 000–007 / 8 | 151×96 | (64,92) | No |
| walk | 000–014 / 15 | 151×96 | (64,92) | Yes |
| run | 000–015 / 16 | 139×102 | (70,98) | Yes |
| jump | 000–015 / 16 | 190×105 | (96,101) | Yes |
| dash | 000–006 / 7 | 151×96 | (64,92) | No |
| climb | 000–015 / 16 | 202×129 | (100,125) | Yes |
| attack | 000–015 / 16 | 117×101 | (56,97) | Yes |
| magic | 000–013 / 14 | 156×107 | (71,103) | Yes |
| hurt | 000–011 / 12 | 213×95 | (101,91) | Yes |

**Known sibling inconsistencies, verified on disk:**

- The cut manifest lists five PNGs that are absent from `game/assets/cut/character/`: `fox_r00_c04.png`, `fox_r00_c12.png`, `fox_r00_c13.png`, `fox_r01_c01.png`, `fox_r01_c08.png`. All 13 active Embertrail inputs are present. Inspect `lib/`, packed frames, and original sheet before considering recovery.
- Idle/dash JSON each has a `vertical_offsets` array of length 15 despite counts of 8/7. The current sibling loader does not use this field, but other importers could misinterpret it.
- Semantic names were assigned by sheet row; the sheet mixes actions within rows. For example, row 0 contains standing, moving and dash poses, and row 1 includes aerial/falling poses. A directory named `character_run` is **not proof of a coherent 16-frame run loop**.
- No exact historical cutter command or full generation history for these sibling assets was found. Do not promise byte-identical reconstruction from raw sheets using default arguments.

## 4. Tool inventory and invocation

These paths/versions were observed on this machine; rediscover them on another machine. No installation was performed for the handoff.

| Tool | Observed path/version | Role, inputs/outputs, common failures |
| --- | --- | --- |
| Godot | `/opt/homebrew/bin/godot` → `/Applications/Godot.app/Contents/MacOS/Godot`; 4.7.1 | Imports assets, runs `.tscn`/GDScript, headless tests, writes logs/cache/captures/PCK. Some script errors can still return exit 0: inspect logs. |
| Python | `/opt/homebrew/bin/python3`; 3.14.6 | Runs active generators with standard library; writes PNG/WAV/TRES through helpers. Current player branch also requires Godot. |
| Blender | `/opt/homebrew/bin/blender`; 5.2.0 LTS; `/Applications/Blender.app` exists | Available but **not used** in Embertrail. No project `.blend`, Blender automation script, or Blender render output was found in the workspace scan. |
| ffmpeg | `/opt/homebrew/bin/ffmpeg`; 8.1.2 | Converts Godot movie AVI to review MP4; codec arguments below. Not needed to play/regenerate sprites. |
| sips | `/usr/bin/sips` | Available macOS image inspection/conversion; not an asset generator used by this project. Example: `sips -g pixelWidth -g pixelHeight assets/sprites/player.png`. |
| Shell / ripgrep | zsh interactive shell; executable scripts use `/bin/sh`; `rg` available | File discovery, launcher and test orchestration. Run sibling helpers from `game/`, active generators from Embertrail. |
| Pillow / NumPy / OpenCV | Not importable in the observed default Python | Not needed for active Embertrail. Pillow/NumPy are required by several sibling helpers; no install was attempted. |
| ImageMagick | `magick`/`convert` not found on PATH | Do not assume available. |

Local image inspection was done by opening PNG files; runtime screenshots and Godot movies supplied the visual evidence. There is no project-local AI-image CLI, model, API key requirement, or AI-generation prompt set for the shipped assets. An editor preview or ordinary image viewer can replace agent-specific viewing tools.

Active helper behavior:

- `python3 tools/generate_player.py --review`: if `source_fox/fox_r00_c00.png` exists, invokes `godot --headless --path PROJECT --script res://tools/import_player_sprites.gd`. Honors `GODOT_BIN`; otherwise finds `godot`/`godot4` on PATH. Fails on nonzero exit or `ERROR:`. Outputs atlas, SpriteFrames and supplied idle detail; **does not render the animation movie**. If that sentinel input is absent it switches to the older procedural rig, changing art direction: never delete it to “fix” an import.
- `python3 tools/generate_assets.py`: delegates the player first, then writes world images and nine WAVs. The standard-library rasterizer scan-converts polygons, draws lines/ellipses, copies RGBA pixels and writes PNG chunks with zlib/CRC. World RNG seed is 914; sound noise seeds and tone parameters are fixed. WAVs are mono signed 16-bit PCM at 22,050 Hz. Review the final source functions rather than relying on older prose note counts.
- `tools/import_player_sprites.gd`: `SOURCES` defines source/anchor pairs, `SPEC` defines rows/timing/order, `pose()` supplies current limited derived actions. `Image` operations avoid Pillow requirements. Writes explicit external AtlasTexture references so resource creation does not depend on an already imported texture. A raw headless script can log an error without a failing exit; use its Python wrapper or inspect logs.
- `tools/review_character.gd`: instantiates sprites on a review board and manually advances frames; even non-looping actions repeat **only for review**, with a 0.28s hold. Writes `docs/character/animation-review.png`, then quits.
- `tools/capture_screens.gd`: renders all five game screens. Its complete-screen screenshot is staged; use the independent traversal test for actual completion evidence.

Blender would be an optional future choice for a deliberately approved 3D rig-to-sprite rendering pipeline, but introducing one now is unnecessary and risks changing the accepted 2D style. A safe availability check is `blender --background --factory-startup --python-expr 'import bpy; print(bpy.app.version_string)'`. There is no real `.blend` render command to provide for this project.

## 5. Godot architecture and gameplay pipeline

`scenes/main.tscn` attaches `scripts/main.gd`. Main instantiates the reusable scenes, connects player signals (`died`, `damaged`, `effect_requested`, `sound_requested`), and creates Camera2D, background and transient effects. Many `.tscn` files are deliberately minimal: the complete runtime hierarchy appears after `_ready()` runs.

Input actions are created in **`scripts/main.gd::configure_inputs()`**, not in a `[input]` block in `project.godot`. Running only the player scene in isolation does not initialize those actions; start main or set up the same map in a dedicated harness.

| Controls | Action |
| --- | --- |
| A/D or Left/Right | move_left / move_right |
| Space/W/Up | jump; hold for higher arc |
| Shift | run |
| X/J | dash; the only attack-like player action |
| Escape/P | pause/resume |
| R | full restart |
| M | mute |
| F11 | fullscreen |
| Enter / mouse | menu activation |
| Controller left stick, A, X, right shoulder, Start | movement, jump, dash, run, pause; hardware not tested |

### Player constants and collision behavior

All following values are from **`scripts/player.gd`**, not historical documents:

| Behavior | Current implementation |
| --- | --- |
| Walk/run | 225 / 335 px/s |
| Ground/turn acceleration | 2100 / 3200 px/s² |
| Ground friction | 2500 px/s² |
| Air acceleration/friction | 1150 / 320 px/s² |
| Jump / early-release upward cap | -565 / -270 px/s |
| Rising/falling gravity | 1450 / 1900 px/s²; player overrides project default gravity |
| Apex assist | 0.72 gravity multiplier while cuttable jump and abs(vertical speed) < 85 |
| Maximum fall speed | 780 px/s |
| Coyote time / jump buffer | 0.12 / 0.14 seconds |
| Dash | 600 px/s for 0.18s, cooldown 0.65s; one air dash until landing |
| Hurt / knockback / invulnerability | 0.24 / 0.18 / 1.2 seconds |
| Landing / death delay | 0.16 / 0.74 seconds |
| Pit kill threshold | feet y > 850 |
| Collider | CapsuleShape2D radius 11, height 44, local center (0,-22) |
| Floor handling | snap 4px, max angle 46°, safe margin 0.04, max slides 5 |

The CharacterBody2D origin is at the feet. `move_and_slide()` handles collisions. Buffered jump release is remembered so a short tap released before landing stays a short hop. Buffered landing jumps must not accidentally refresh coyote time twice. Dash direction locks during the burst; hitting a wall cancels it; dash exits at ordinary movement speed. `can_stomp()` checks prior feet position and pre-collision downward speed to classify fast contacts reliably. `bounce()` deliberately prevents a jump release from cutting an enemy rebound. `respawn()` resets action timers.

### Other systems and dependencies

- **Level:** `scripts/level.gd` creates five ground rectangles and 17 one-way ledges, positions hazards/enemies/coins/checkpoints/goal, and draws terrain/signs. Ground collision is layer 1; player layer 2/mask 1; enemies use layer 3. Layer names are configured in `project.godot`.
- **Enemy:** `scripts/enemy.gd` uses patrol bounds, a forward floor ray, wall detection and a contact Area2D. It checks both body-entry and continued overlap; dash or swept stomp defeats it. Defeat awards score, plays effects and frees the node.
- **Hazards/coins:** `scripts/hazard.gd` applies damage while overlapping; dash is not thorn invulnerability. `scripts/collectible.gd` animates/bobs the ember then frees it on pickup.
- **Checkpoints/death:** checkpoint positions are x=2080 and 4170, floor y=470. `main.activate_checkpoint()` stores a return position and heals. `main._on_player_died()` decrements lives, respawns or opens game over. `start_game()` recreates the world, clears score/embers/time and restores three lives.
- **Camera:** main creates a Camera2D with smoothing speed 7.5, bounds x=0..6240/y=0..540, horizontal velocity look-ahead and decaying shake. Camera center is clamped x=480..5760 at y=270. `backdrop.gd` draws parallax from camera scroll; it is not a Parallax2D scene.
- **Goal:** shrine at (6020,470) calls `complete_level()`. Main disables control, adds lives/time bonus, shows completion and pauses. There is currently no victory animation; adding one must account for this immediate pause.
- **UI:** main's states are `menu`, `playing`, `paused`, `complete`, `game_over`. Menus emit actions; HUD receives health/lives/score/time/progress/cooldown each frame. Locale is explicitly English and UI roots use LTR: preserve this fix on Hebrew/RTL systems.
- **Sound/effects:** main loads WAVs and creates short-lived AudioStreamPlayers; `burst.gd` draws motes. Landing/running dust, pickup sparkles, enemy defeat, hurt flash and camera shake are functional even though animation poses are limited. Audio shutdown includes a short mixer drain in main/tests; do not remove it as apparently redundant headless code.

## 6. Current sprite and animation pipeline

```text
13 preserved source PNGs + SOURCES anchors + SPEC/pose code
  -> tools/import_player_sprites.gd (via generate_player.py)
  -> assets/sprites/player.png + player_frames.tres
  -> Godot import (.godot cache)
  -> scenes/player.tscn / Sprite (AnimatedSprite2D)
  -> scripts/player.gd::_update_visuals()
  -> menu_art.gd and review tools consume the same SpriteFrames
```

### Pixel/anchor rules

The importer copies originals and changes only its generated images. It removes pale neutral exterior fringe pixels in two passes: chroma < 0.09, max channel >= 0.32, touching transparency/image boundary. This is an edge heuristic, not blanket removal of all white pixels; keep cream clothing and warm tail tips intact.

Each output cell is **160×160**, with feet/body anchor **(100,145)**. The atlas is eight columns × nine rows. Source-specific anchors compensate for tight crops and tails extending behind the body. Do not center by each crop's bounding box: the torso will visibly jump sideways.

The runtime sprite is centered, scaled **0.75**, positioned **(-15,-48.75)** while facing right. The horizontal offset mirrors with facing. This maps the cell's (100,145) anchor back to the player's origin. Tiny landing/jump spring scaling is applied visually; collider dimensions do not change. Metadata in `player_frames.tres` stores `frame_size=160`, `columns=8`, `feet_anchor=Vector2(100,145)`, and `portrait_region=Rect2(46,53,84,96)`. `menu_art.gd` crops idle frames using that portrait rectangle.

Use RGBA PNGs with actual transparency. No baked checkerboard/ground slab/neighboring effects should enter a cell unintentionally. The raw sibling sheet shows a checker pattern, while active source cuts have alpha. Preserve nearest filtering and margins around ears/tails/paws. Current texture import is lossless, no mipmaps, alpha-border fix enabled; `scenes/player.tscn` explicitly uses nearest texture filtering.

### Exact current animation definitions

`tools/import_player_sprites.gd::SPEC` is the source of truth. Each frame duration is 1.0 units at the stated base FPS. **44 is the playback-entry count, not 44 independently drawn poses.** Unused columns in a row repeat the last pose but are not included in playback.

| Row / state | Frames | Base FPS | Loop | Source sequence / current limitation |
| --- | --- | --- | --- | --- |
| 0 idle | 8 | 8 | Yes | 00,01,02,03,05,02,01,00; five source poses, repetitions |
| 1 walk | 4 | 9 | Yes | 06,07,08,07; three source poses |
| 2 run | 4 | 12 | Yes | 09,10,11,10; three source poses, short ping-pong cycle |
| 3 jump | 4 | 16 | No | crouch source (`fox_r01_c00`), four small whole-image tilts/offsets |
| 4 fall | 4 | 9 | Yes | source 07, small tilts; no dedicated airborne leg/arm posing |
| 5 dash | 4 | 23 | No | source 14, tiny translations; one original burst pose |
| 6 hurt | 4 | 18 | No | source 03, progressively relaxing backward tilt |
| 7 death | 8 | 12 | No | source 00 rotates toward prone; bounds/floor correction, no articulated collapse |
| 8 land | 4 | 25 | No | crouch,crouch,07,00 with slight offset |

Source keys `00`–`14` mean `fox_r00_cNN.png`; `crouch` means `fox_r01_c00.png`. There is no separate melee attack, anticipation, start-run, stop/skid, turn, apex, or victory state in the active game.

`_update_visuals()` priority is: death → hurt → dash → rising jump (`velocity.y < -10`) → airborne fall → landing if timer active and abs(horizontal speed)<50 → locomotion if speed>12 → idle. Locomotion selects run above `WALK_SPEED+8` (233 px/s), otherwise walk. It calls `play()` only when the state changes, avoiding per-frame restarts. Walk/run `speed_scale = clamp(abs(velocity.x)/200, 0.45, 1.75)`; other states use 1.0. This is speed-dependent cadence, **not measured foot-contact distance matching**, so residual sliding is expected. Facing currently flips immediately on new directional input outside dash; no turn anticipation exists.

### How to add frames safely

1. Review original small frames, current atlas, motion video, and raw sibling sheet side-by-side. Classify additional poses visually before using row labels.
2. Preserve copies of selected source art and record provenance. Do not paint over the 13 originals. Decide on coherent key poses first: contact/compression/passing/flight for a stride; compression/extension/rise/apex/fall/recovery for a jump.
3. Draw or locally construct real limb, torso, clothing and tail changes. Whole-image rotation, stretched copies, duplicated frames or cross-fades do not substitute for missing anatomy/in-betweens. Keep head size, muzzle angle, costume and palette stable.
4. Maintain feet/hip anchors and native scale. Use controlled body bounce, opposing arm/leg swing and delayed tail/robe follow-through. Grounded stance should remain planted relative to world travel; do not erase intentional airborne displacement by blindly bottom-aligning every frame.
5. Update `SOURCES`, `SPEC`, pose construction and atlas writing in the importer (or replace it with an explicitly documented generator that the Python wrapper calls). Increase columns from eight if using a single row for a 10–16-frame state. Current writer cannot hold those counts without a layout change.
6. Regenerate both PNG and `.tres`, then reimport. Preserve/recalculate portrait metadata, player scale/offset, and runtime facing alignment together if dimensions change.
7. Add new states to `_update_visuals()` with interrupt rules. Keep jump input immediate; anticipation must not delay physics/coyote/buffer response. A visual start sequence can overlap acceleration; a short takeoff pose can play while upward movement begins. Preserve walk/run cycle phase when switching if practical. Use speed/displacement to sync contact cadence, not unconditional fixed-rate cycling.
8. Update `tests/character.gd` atlas bounds/count expectations, `tools/review_character.gd` state layout, `docs/character/review.html` hardcoded specs/cell offsets, current README/manifest, and this guide. Update only legitimate structural assertions; retain collision and movement protections.

## 7. Reproducible commands

Commands below use real observed paths. Unless stated otherwise, run from the active project. Redirection of a command to a log is not itself validation: check its exit status and `ERROR:` lines.

### Discover and establish baseline

```sh
cd /Users/JacobT/p/embertrail
pwd
rg --files -g '!*.import' -g '!*.uid' -g '!*.log' -g '!**/__pycache__/**'
rg --files scenes scripts assets tools tests docs
rg -n 'class_name EmberPlayer|_update_visuals|SPRITE_|JUMP_|DASH_' scripts/player.gd
rg --files assets/sprites /Users/JacobT/p/game/assets/cut/character /Users/JacobT/p/game/assets/anim
rg -n '"name"|"speed"|"loop"|region =|metadata/' assets/sprites/player_frames.tres
/opt/homebrew/bin/godot --version
/opt/homebrew/bin/python3 --version
/opt/homebrew/bin/blender --version
./tests/run_checks.sh
```

The runner imports first, then uses `--headless --fixed-fps 60 --script` for integration, traversal and character. It stops on failed assertions or logged engine/script errors. For focused iteration:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --fixed-fps 60 --script res://tests/character.gd
godot --headless --path . --fixed-fps 60 --script res://tests/traversal.gd
rg -n 'ERROR:|SCRIPT ERROR:|RESULT|PASS full level' tests/results/*.log
```

The focused commands do not replace the runner's log inspection. If Godot is not on PATH, set `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot` when invoking the launcher, runner, or Python wrapper.

### Launch and preview

```sh
cd /Users/JacobT/p/embertrail
./launch_game.command
# Or open project.godot in Godot and press F5.
# Direct engine start requires imported assets:
godot --path .
# Start playing immediately:
godot --path . -- --preview
# Local interactive frame viewer, no server required on this macOS host:
open docs/character/review.html
# Render the current motion board and save animation-review.png:
godot --path . --fixed-fps 60 --script res://tools/review_character.gd
# Capture all five screens:
godot --path . --fixed-fps 60 --script res://tools/capture_screens.gd
```

For a specific current gameplay capture (must use a graphical renderer, not headless):

```sh
godot --path . -- --preview --preview-x=1500 --capture=/tmp/embertrail-player-review.png
```

`--capture` saves after 90 process frames and quits. `--preview-x` is a staging shortcut, not evidence of playable traversal. Keep `--preview` before it because starting a new game rebuilds the player.

### Regenerate active assets

```sh
cd /Users/JacobT/p/embertrail
# Character only; preferred for this next task:
python3 tools/generate_player.py --review
godot --headless --path . --editor --import --quit
./tests/run_checks.sh
# Full player + world + audio rebuild, only when intended:
python3 tools/generate_assets.py
godot --headless --path . --editor --import --quit
```

The older `generate_procedural()` implementation remains in `tools/generate_player.py`, with 128px cells/64 poses. Its `ANIMS` constant is **not the active animation specification**. Do not accidentally tune that fallback instead of `tools/import_player_sprites.gd`.

### Render videos and export

```sh
cd /Users/JacobT/p/embertrail
godot --path . --fixed-fps 60 --write-movie /tmp/embertrail-motion.avi --script res://tools/review_character.gd
ffmpeg -y -hide_banner -loglevel error -i /tmp/embertrail-motion.avi -an -c:v libx264 -crf 22 -pix_fmt yuv420p -movflags +faststart docs/character/animation-review.mp4

godot --path . --fixed-fps 60 --write-movie /tmp/embertrail-route.avi --script res://tests/traversal.gd
ffmpeg -y -hide_banner -loglevel error -i /tmp/embertrail-route.avi -an -vf fps=30 -c:v libx264 -crf 22 -pix_fmt yuv420p -movflags +faststart docs/character/gameplay-review.mp4

godot --headless --path . --export-pack 'Desktop Pack' builds/embertrail.pck
godot --main-pack builds/embertrail.pck --quit-after 150 -- --preview --capture=/tmp/embertrail-packed-player.png
```

Videos intentionally omit audio (`-an`). The source WAVs remain available. The pack preset excludes `tests/*`, `tools/*`, `docs/*`, `source_art/*`, and `*.md`. Rebuilding the pack requires no native export templates; native app export would. Do not install anything without the user's approval.

If delivering an updated archive, rebuild it from the source directory rather than assuming the old ZIP updates itself. This standard-library command preserves executable mode metadata through `ZipFile.write` and checks archive integrity:

```sh
cd /Users/JacobT/p/embertrail
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root = Path.cwd()
out = root.parent / 'embertrail.zip'
with ZipFile(out, 'w', ZIP_DEFLATED) as archive:
    for path in sorted(root.rglob('*')):
        if not path.is_file() or any(part in {'.godot', '__pycache__', '.DS_Store'} for part in path.parts):
            continue
        if path.suffix == '.pyc' or (path.suffix == '.log' and 'tests/results' not in path.as_posix()):
            continue
        archive.write(path, path.relative_to(root.parent))
with ZipFile(out) as archive:
    assert archive.testzip() is None
print(out)
PY
```

### Optional sibling helper use: inspect before running

These examples describe the existing utilities, **not a required reproduction step for Embertrail**. Pillow/NumPy are absent from the default Python. Do not install them or regenerate source cuts without approval. Run from `/Users/JacobT/p/game` because these scripts contain relative paths. Use a new review directory to avoid altering source assets.

```sh
cd /Users/JacobT/p/game
python3 -c 'import PIL, numpy; print(PIL.__version__, numpy.__version__)'
# The check above currently fails; the following need those dependencies.
mkdir -p /tmp/embertrail-sibling-review
python3 tools/contact_sheet.py assets/cut/character /tmp/embertrail-sibling-review/contact.png --cell 128 --cols 10
python3 tools/row_strip.py character 0,1,2 /tmp/embertrail-sibling-review/rows.png 128
# Example fresh cut, NOT a claim of reproducing the historic manifest exactly:
python3 tools/cut_assets.py assets/raw/assets_character1.png /tmp/embertrail-sibling-review/cuts --prefix fox
# Requires selected groups' missing source files to be resolved first:
python3 tools/pack_anim.py character run jump hurt --out /tmp/embertrail-sibling-review/anim
```

`python3 tools/name_assets.py plan` overwrites both character/world `names.json` maps. `python3 tools/name_assets.py apply` deletes/recreates both `assets/lib/<sheet>/` destinations and will fail on missing cuts. They are documented for completeness, **not safe default commands to run against the current collection**. The contact-sheet helper skips absent files, whereas the row-strip and pack helpers can fail on them. Inspect source and choose a recovered copy or explicit frame list before reuse.

## 8. Build–test–evaluate–refine workflow

The prior observable work is recorded in `docs/BUILD_PASSES.md`, `docs/character/REFINEMENT.md`, and `docs/character/supplied/README.md`:

1. Built the smallest complete loop: reusable scenes, level, controller, menus/HUD, world art/audio. Headless/runtime checks found a native-method naming conflict, missing dash-cooldown exposure, and a test collectible already consumed by another check.
2. Measured jump/landing and contact behavior, adjusted physics, verified physical route completion, and corrected accelerated-test audio shutdown. Later controller work added reliable swept stomps, jump-release/buffer handling and dash recovery.
3. Inspected rendered screens, corrected English UI layout under an RTL system locale, checked sprite facing and camera/HUD presentation, validated packed output. The procedural player was subsequently replaced by the 13 supplied sprites with feet alignment, separate walk/run selection and refreshed media.

Those documents contain old counts/measurements. Treat the live source and latest tests as current truth. The history is evidence of iteration, not a instruction to reproduce obsolete assets.

For each new character pass:

1. **Choose one observable weakness.** Example: run has only three unique poses and a reversal in its foot cycle. Save a baseline screenshot/movie and inspect the actual frames at gameplay scale.
2. **Change its source.** Preserve immutable PNGs and back up current atlas/spec before layout changes. Implement contact/passing/flight poses and actual in-betweens; change state logic only as needed to display them.
3. **Regenerate/reimport.** Use the focused player wrapper; verify PNG bounds, region sizes, transparency, atlas dependencies and parser output. Missing paths must be fixed in source generation, not patched only into the cache.
4. **Run focused checks.** Use character harness and targeted transition tests. Check opposite facing, thin walls, ceiling hits, rebound, buffered jump, short-hop release, and interrupted land/dash/hurt/death.
5. **Render and play.** Inspect loop seams, limb length/clothing consistency, soles relative to ground, animation speed, tail overlap and menu portrait. Play acceleration, release, reversal, held/tapped jumps, gap falls and damage. Headless assertions cannot judge this art quality.
6. **Refine the highest-impact defect.** Fix clipped tails, misaligned roots and incorrect state priority before extra decorative frames. Distinct pixel hashes alone cannot prove distinct meaningful poses.
7. **Record the pass.** State changed files, old/new counts, test results, visual findings, and remaining weaknesses. Repeat for at least three passes for the expansion task.
8. **Complete regression/delivery.** Run the full runner once focused changes pass, refresh rendered reviews/docs, export and smoke-test the pack if shipping it. Re-run only when new changes or failures justify it; keep archived output consistent with source.

Suggested three-pass structure: (1) coherent expanded key poses and atlas integration; (2) in-betweens, transition timing and contact/cadence correction; (3) adversarial interruption tests, final visual cleanup and export review. A passing test suite alone is not completion of the animation brief.

## 9. What not to do

- Do not overwrite the original large reference, the 13 source copies, raw sibling sheets, or historical art backups. Preserve hashes and add newly selected sources explicitly.
- Do not hand-edit only `player.png` or `player_frames.tres` while leaving the generator stale; next regeneration will erase the change. If introducing a new authored-art pipeline, make that the documented source of truth first.
- Do not blindly reuse `game/assets/anim` labels, dimensions or sidecars. Inspect mixed-action rows and the missing-file issues above.
- Do not pad frame counts with duplicate poses or whole-body stretch/rotation and report them as newly drawn animation. Separate unique poses, in-betweens and playback holds in reporting.
- Do not change cell size/columns/anchor without updating AtlasTexture regions, metadata, player offset, portrait crop, review tools and structural tests together.
- Do not hardcode keyboard checks into the player or depend on inputs that exist only when the editor runs another scene.
- Do not add animation locks that consume coyote time, delay jump response, restart jump repeatedly near apex, repeat dash before ground contact, or prevent a buffered landing jump.
- Do not rewrite terrain, level design, enemies, scoring, audio, or menus to solve an unrelated sprite issue. A victory display may require a narrow completion/pause integration change; document it.
- Do not remove audio mixer cleanup or the RTL fix just because they look unrelated to gameplay.
- Do not use `.godot` caches, an old ZIP, or a historical review image as the asset source of truth.
- Do not assume an upstream license for the supplied artwork, copy copyrighted game characters/levels/music, or introduce paid assets/services. Existing game names mentioned as inspiration are not asset sources.
- Do not install missing tools/dependencies without approval; the active pipeline already works locally.

## 10. Quality checklists

### Workspace understanding

- [ ] Working directory is `/Users/JacobT/p/embertrail`; main scene/config confirmed.
- [ ] Active 13-source importer is distinguished from procedural fallback and sibling `game/` loader.
- [ ] Current atlas, motion review, player code and source PNGs inspected.
- [ ] Baseline tests and source provenance verified; historical documents identified as historical.
- [ ] Selected extra poses are visually classified; missing sibling sources/sidecars handled explicitly.

### Sprite consistency

- [ ] Same head/muzzle/ear proportions, eyes, robe trim, sash, trousers and paws across frames.
- [ ] Same orange/rust/gold/cream palette and readable swept-tail silhouette.
- [ ] Actual RGBA transparency; no baked checkerboard, fringe, detached crop fragments or neighboring props.
- [ ] Feet/hips consistently anchored; intentional airborne offsets preserved.
- [ ] Ears/tails/limbs fit safely inside every cell, including mirrored/prone poses.
- [ ] Meaningful pose variation, with no accidental limb-length changes or rubber stretching.

### Animation quality

- [ ] Run has contact, compression, passing, lift/flight and opposite-leg phases; loop seam is smooth.
- [ ] Stance-foot travel is checked against gameplay speed; timing does not amplify foot sliding.
- [ ] Arms counter legs; tail/cloth follow-through lags the body without changing the character model.
- [ ] Start, stop and turnaround remain readable at native gameplay scale.
- [ ] Rise/apex/fall/landing have distinct readable poses and transitions.
- [ ] Hurt/death convey recoil/collapse through body articulation, not just rotating an idle still.
- [ ] One-shots settle appropriately; loops remain seamless; holds are intentional and reported.

### Godot integration

- [ ] Atlas/resource references import without errors; every referenced region is in bounds.
- [ ] AnimatedSprite2D gets correct state, FPS, loop flag and facing offset.
- [ ] Menu portrait, HTML review and Godot review reflect the new atlas.
- [ ] Animation changes do not reset cycles every physics frame or oscillate near thresholds.
- [ ] Pause/resume, respawn, hurt and completion preserve intended animation state.

### Movement feel

- [ ] Acceleration/release/reversal stay responsive; no mandatory visual delay before jumping.
- [ ] Tap/held jump, coyote jump and released buffered tap still work.
- [ ] Landing is interruptible; wall/ceiling contact remains reliable.
- [ ] Dash direction, cooldown/air-use limit and exit speed remain correct.
- [ ] Stomp/rebound and damage interruptions remain correct.

### Final validation

- [ ] At least three expansion passes recorded with actual findings/fixes.
- [ ] Full `./tests/run_checks.sh` succeeds; no script/resource/runtime errors in logs.
- [ ] Real input-only route reaches complete; loss/restart/pause still verified.
- [ ] Rendered review at normal and slower playback inspected, plus real gameplay.
- [ ] Source hashes remain unchanged; frame counts and remaining limitations documented honestly.
- [ ] Pack rebuilt/smoke-tested if delivering a build; ZIP refreshed only if delivering an archive.

## 11. Recommended next task: expand the reference-based player animation set

**Analyze the current player sprites that were based on the user's reference and expand them into a fuller animation set with more frames, smoother motion, better flow, and less small-set stiffness. Keep the accepted design.** This work remains pending at the handoff; the inspection for it found the larger sibling collection but did not implement a new atlas or controller states.

Inspect first, in order:

1. `assets/sprites/source_fox/`, `provenance.json`, `assets/sprites/player.png` and `player_frames.tres`.
2. `tools/import_player_sprites.gd` (`SOURCES`, `SPEC`, `pose`, `generate`) and the dispatch in `tools/generate_player.py`.
3. `scenes/player.tscn` and `scripts/player.gd`, especially `_update_visuals`, `_perform_jump`, landing, dash, damage and respawn.
4. `docs/character/review.html`, `animation-review.mp4`, `gameplay-review.mp4`, and `tests/character.gd`.
5. `source_art/character_sheet.png`, `source_art/character_index.png`, and visually selected files in `source_art/cuts/` and `source_art/legacy_animations/` (originals: `/Users/JacobT/p/game/assets/raw/assets_character1.png` and siblings). The raw sheet contains promising aerial, landing, damage and celebration poses; verify each before copying it into Embertrail with provenance.

Preserve the 13 accepted source PNGs, their body scale/identity, the existing capsule and tested platforming behavior, and all unrelated world systems. The larger sheet may provide better key poses, but mixed rows and frame inconsistencies mean it is not an automatic finished animation set.

| Animation | Current frames | Target frames / intended improvement |
| --- | --- | --- |
| Idle | 8 | 6–10; breathing/blink variation and stable planted feet |
| Walk | 4 | Keep supported; expand to a coherent 8–12-frame cycle if needed for smooth walk/run handoff |
| Idle-to-run | Absent | 2–4; weight shift/push-off overlapping acceleration |
| Run | 4 | 10–16; complete alternating foot cycle, counter-swing, bounce and tail delay |
| Stop/skid/turnaround | Absent | 4–8; braking lean and readable reversal without input lag |
| Jump anticipation | Absent | 2–4; visual compression/takeoff with immediate physics response |
| Jump rise | 4 transformed crouch frames (`jump`) | 4–6; extension and leg tuck, actual joint/cloth changes |
| Jump apex | Absent | 2–4; brief weightless transition selected by vertical motion |
| Fall | 4 transformed walking frames | 4–6; descending limbs/tails, readable landing preparation |
| Landing | 4 | 3–6; impact compression and recovery, interruptible |
| Dash/burst | 4 offsets of one image | 6–10; commitment, extension, trailing motion and recovery |
| Attack/action | No separate attack; dash is offensive | 6–12 only if expanding an existing action presentation; do not invent a new combat system |
| Hurt | 4 transformed standing frames | 4–6; recoil, flinch and recovery with consistent anatomy |
| Death | 8 rotated standing frames | 8–16; stagger, collapse, grounded settle, held final pose |
| Victory (optional) | Absent | 6–12; celebration that can actually play before/during completion UI pause |

After building the expanded art, update SpriteFrames generation and state logic together. If keeping rows, expand atlas columns for long cycles; update all hardcoded previews/tests. Consider a distance-based locomotion phase to reduce sliding and phase continuity when changing walk/run speed. Use separate ascent/apex/descent state thresholds with stable transitions rather than a velocity sign flip alone. Never make visual anticipation delay the jump impulse.

Success means more than meeting frame-count targets: actual distinct key poses and in-betweens, consistent identity, seamless loops, stable roots, readable transitions at gameplay scale, three documented review/refinement passes, preserved movement/input behavior, and a clean full validation route. Finish with old-versus-new counts, edited-file list, preview commands, source provenance, and candid remaining limitations.
