# Automated checks

Run `./tests/run_checks.sh` from the project directory. The script locates `godot`, `godot4`, or a standard macOS Godot installation. Set `GODOT_BIN=/path/to/godot` to choose an executable. No test framework or package installation is required.

The runner imports and validates the project, then executes three actual Godot SceneTree harnesses at a deterministic 60 FPS. It returns a nonzero exit status for either failed assertions or engine/script errors, including cases where Godot itself returns zero after logging an error. Logs are saved in `tests/results/`.

`integration.gd` contains 101 checks covering resource loading, core animation sets, initial menu and HUD, input mappings, acceleration, friction, run speed, variable-height jumping, reachable optional platforms, coyote time, jump buffering, dash cooldown, pause/resume, collectibles, enemy contact, dash defeat, stomping, spikes, checkpoint healing, delayed pit deaths, checkpoint respawning, three-life game over, restart after loss, physical goal activation, and restart after completion. Isolated interaction checks place the player at controlled starting positions and then exercise actual collision overlaps or input actions.

`traversal.gd` drives the real player through the entire level using movement, run, jump and dash input actions. It does not teleport, change health, disable collisions, invoke interactions directly, or skip sections. Passing requires reaching the goal, covering more than 5,900 world pixels, collecting embers, lighting both checkpoints and making the necessary jumps.

Fast headless tests can advance simulated gameplay much faster than the audio mixer runs. The harnesses stop their audio voices and allow a short mixer drain before shutdown, so ordinary queued audio is not falsely reported as leaked playback resources.

## Recorded refinement results

1. Initial integration: 70/71 checks passed. The HUD referenced an unavailable cooldown property. The one assertion failure was a reused collectible that an earlier test had consumed; that fixture was replaced with an isolated collectible. The first input-only playthrough reached the goal with all three lives. Measurements also showed a held jump of 93.1 pixels, slightly below some lower ledges.
2. Controller refinement: the cooldown property was exposed, held jump height increased to 108.6 pixels, and landing audio added. The expanded 72-check integration suite passed, including a new physical test confirming the first optional platform was reachable. Verbose shutdown diagnostics isolated remaining warnings to asynchronous audio playback resources.
3. Complete verification: audio cleanup was corrected in the harnesses and the runner was strengthened to reject engine errors. UI regression checks were added for menu/title/HUD bounds, Enter-to-start, and actual mouse-click resume. Import, all 100 integration checks and the full physical playthrough passed with no script, runtime or shutdown errors. The playthrough completed in 19.55 simulated seconds, collected 45 embers, lit both checkpoints, used 13 jumps and four dashes, and retained all three lives.

These automated checks verify behavior and collision flow; visual review is performed separately using captured running-game screenshots. The driving agent is deliberately efficient and is not a player-completion-time estimate.

## Character-specific regression suite

`character.gd` adds 31 checks for the supplied-art 160px-cell atlas, all 44 playback frames, separate walk/run selection, transparent sprite margins/no clipped ears or tails, distinct frames in every state, dedicated landing/death playback, acceleration/stopping/reversal, mirrored foot alignment, dash direction lock/recovery/air-use limits, thin-wall and ceiling collision, short buffered taps, interruptible landing and single impact audio, moderate/terminal-speed stomps, release-independent rebound, death and clean respawn.

The current total is **132/132 passing assertions**, plus the input-only traversal. The revised controller completes the route in 19.08 simulated seconds with 45 embers, both checkpoints and all three lives. Historical results above record the earlier prototype.
