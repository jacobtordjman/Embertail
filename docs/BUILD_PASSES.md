# Build–test–refine record

Test environment: Godot 4.7.1, macOS, Apple M5, OpenGL compatibility renderer. Assets generated with Python's standard library; no dependencies installed.

## Pass 1 — complete playable foundation

Built the level, reusable player/enemy/item/hazard/checkpoint/goal scenes, game states, menus, HUD, procedural assets, audio, parallax, and effects. Ran Godot's headless editor import, runtime startup, and the initial integration/route tests.

Found and fixed a helper named `draw_ellipse` conflicting with a new native CanvasItem method. Runtime testing exposed a missing public dash-cooldown property used by the HUD. Added that property and the missing landing sound. Initial test placement for a collectible was corrected so an earlier dash could not consume its fixture.

Remaining: jump clearance for optional platforms, visual inspection of menus and HUD, and clean final test shutdown.

## Pass 2 — platforming and game-flow refinement

Measured short/held jumps, acceleration, friction, run speed, coyote time, jump buffering, dash duration/cooldown, physical collectible/enemy/spike interactions, checkpoint healing, delayed death, game over, restart, pause/resume, and physical goal overlap.

Raised jump impulse from 490 to 530 px/s after measuring only 93.1 px of held-jump height against optional ledges 95–105 px above ground. Final measured arcs are about 36.8 px for a tap and 108.6 px for a held jump; a physical test confirms landing on the first raised platform.

Outcome: **72/72 behavioral checks passed**. An actual Input-action-driven route completed the whole level without teleportation, health overrides, or bypassing collisions. Tuned route: 19.55 simulated seconds, 45 embers, two checkpoints, 13 jumps, four dashes, three lives remaining. A brief audio-mixer drain at test shutdown removed accelerated-headless audio resource warnings.

Remaining: visual layout verification, keyboard/mouse menu acceptance, and export validation.

## Pass 3 — rendered UI, regression coverage, and delivery

Launched the real OpenGL game and inspected captures. The system's Hebrew locale caused English Controls positioned before tree insertion to be mirrored off-screen. Setting only the root's layout direction was insufficient; setting the authored English locale before constructing controls resolved it. Added explicit left-to-right roots and regression checks for menu-button/title/HUD bounds and actual mouse/keyboard activation.

Inspected all five rendered states: main menu, gameplay, pause, game over, and level complete. Corrected beetle sprite facing, adjusted HUD progress styling, and set explicit music loop sample bounds. Added audio-mixer cleanup on game shutdown after the packed build exposed a looping-WAV exit warning. The rebuilt pack then exited cleanly. Added a portable local launcher, asset regeneration instructions, an export preset, and documentation.

Outcome: **100/100 final behavioral checks passed**, followed by a clean physical full-level traversal. No script errors or missing resources in the final checks. Exported `builds/embertrail.pck` and launched the packed game headlessly as an independent smoke check. Screenshots are `docs/menu.png`, `gameplay.png`, `pause.png`, `game_over.png`, and `complete.png`.

Remaining limitations: one short level, one enemy type, synthesized placeholder music/SFX, no save/rebinding menus, no physical controller or non-macOS validation, and no standalone executable because export templates are absent. The complete project and resource pack run with the installed Godot engine.
