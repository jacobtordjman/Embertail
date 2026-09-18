# Character reference archive

These files are read-only copies of the user's existing character assets, included so the Godot repository is self-contained for future player-animation work. They are excluded from the runtime `.pck` by `export_presets.cfg`. They are **not** the active animation atlas.

| Path | Original workspace path | Use |
| --- | --- | --- |
| `character_reference.png` | `/Users/JacobT/p/a64f5852-f462-4bde-a16d-debc126e082d.png` | Initial visual reference |
| `character_sheet.png` | `/Users/JacobT/p/game/assets/raw/assets_character1.png` | Composite of additional fox poses |
| `character_index.png` | `/Users/JacobT/p/game/assets/INDEX_character.png` | Visual index |
| `cuts/` | `/Users/JacobT/p/game/assets/cut/character/` | 162 existing tight crops, `manifest.json`, `names.json` |
| `legacy_animations/` | `/Users/JacobT/p/game/assets/anim/` | Padded poses, strips and action JSON |

The active runtime uses the 13 preserved PNGs in `assets/sprites/source_fox/`. Their individual hashes and original paths are in `assets/sprites/source_fox/provenance.json`. Upstream creation history for the composite sheet is not established by the files in this workspace. The cut manifest lists five absent cut PNGs; some legacy idle/dash metadata arrays do not match their frame counts. Check actual images and poses before importing additional frames. The handoff guide at `docs/AI_AGENT_HANDOFF.md` documents the current nine states, active importer, these discrepancies, and the expansion workflow.
