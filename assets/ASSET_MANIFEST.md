# Embertrail asset manifest

World art, enemies, collectibles and audio were drawn or synthesized locally by `tools/generate_assets.py`. Player art uses the user's 13 supplied PNGs, copied unchanged into `sprites/source_fox/`. `provenance.json` records their original paths and SHA256 hashes. No downloaded sprite packs, samples, or paid tools are used.

`tools/import_player_sprites.gd` aligns these crops by body/feet, removes thin neutral exterior matte fringes in the generated atlas, and derives missing transition poses. The original source files are untouched. The large initial reference image is archived as `source_art/character_reference.png` and excluded from the runtime pack. Extra source poses and their metadata are archived in `source_art/`; they are not active player frames.

## Sprite sheets

| Path | Dimensions | Layout |
| --- | --- | --- |
| `sprites/player.png` | 1280 × 1440 | 160 × 160 cells, eight columns. Rows 0–8: idle, walk, run, jump, fall, dash, hurt, death, land. Facing right; mirror for left. Feet anchor (100,145), rendered at 0.75 scale. |
| `sprites/player_frames.tres` | SpriteFrames resource | 44 playback frames: idle 8; walk, run, jump, fall, dash, hurt and land 4 each; death 8. Repeated/derived poses are included; these are not 44 independently drawn source images. |
| `sprites/enemy.png` | 160 × 64 | 40 × 32 cells, four columns. Row 0: walking moss beetle. Row 1: defeated beetle and sparkles. |
| `sprites/coin.png` | 144 × 24 | 24 × 24 cells, six columns. Looping rotating amber seed. |
| `sprites/heart.png` | 16 × 16 | One HUD heart. |
| `tiles/terrain.png` | 128 × 32 | 32 × 32 cells. Columns 0–3: grass over earth, earth, stone blocks, timber. |
| `effects/sparkle.png` | 64 × 16 | 16 × 16 cells, four fading sparkle frames. |
| `backgrounds/mountains.png` | 960 × 360 | Transparent sky, repeating layered sage and teal mountains. |
| `backgrounds/trees.png` | 960 × 360 | Transparent layer of forest silhouettes and amber deciduous trees. |

Use nearest-neighbor texture filtering for sprites and tiles. Each sprite sheet has a transparent background. Canvas-based additional level effects can share the palette: dark outline `#352a36`, orange `#ef7136`, gold `#ffd773`, pale cream `#fff1c2`, teal `#587576`, sage `#82958e`.

## Audio

All audio is mono signed 16-bit PCM at 22,050 Hz, synthesized with sine/triangle tones and deterministic noise, with envelopes to avoid clicks.

- `audio/jump.wav`: rising soft triangle chirp.
- `audio/coin.wav`: two bright notes.
- `audio/hurt.wav`: descending rough impact.
- `audio/enemy.wav`: short three-note defeat sound.
- `audio/checkpoint.wav`: ascending four-note phrase.
- `audio/complete.wav`: original seven-note completion fanfare.
- `audio/dash.wav`: brief falling whoosh.
- `audio/land.wav`: quiet low impact.
- `audio/music.wav`: original 16-second ambient chord and melody loop. Keep its playback volume low enough for sound effects to remain clear.

## Reproduction

From the project root run `python3 tools/generate_assets.py`. The seed and synthesis parameters are fixed, so regeneration is deterministic. The script writes only generated assets listed above. There are no installation requirements.

## Character refinement

Idle, walk, run and dash retain the supplied artwork. Jump, fall, hurt and death use modest translations/rotations of supplied poses; landing sequences the crouch and standing poses. These derived states are placeholders for dedicated action drawings. The importer preserves anatomy rather than generating new clothing or facial details.

For character-only regeneration: `python3 tools/generate_player.py --review`. This invokes the installed Godot 4 importer and updates the player atlas, SpriteFrames resource, and idle detail preview without touching world art or audio. The previous Python drawing rig remains a fallback when supplied source art is absent. See `docs/character/supplied/README.md` for review and verification.
