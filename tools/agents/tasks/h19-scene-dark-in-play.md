---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Level is entirely dark when the user presses Play (PIE/Standalone), unlike the editor viewport

User report (5 Sept 2026): clicking Play makes the game go completely dark, even though
the editor viewport itself looks fine (was reported "super fuckin bright" earlier this
same session in the editor viewport — a *different*, already-diagnosed-but-not-yet-fixed
issue: inverse-square falloff disabled + overlapping light fixtures, no task dispatched
for it yet). This is specifically about the gap between editor-viewport lighting and
actual Play/Standalone lighting, not a continuation of the brightness issue.

## Leading hypothesis — check this first, it's a real risk from tonight's own changes

This project already has an `EnableDynamicLighting` stopgap (`ShockGameMode.cpp` /
`import_level.py`) built specifically because levels have no baked lightmaps — it forces
static meshes to Movable mobility so their lighting computes dynamically at runtime
instead of requiring a lighting build. **h11 (fix-broken-player-movement, already
committed) changed this function** to explicitly detect the compiled-world shell (by
actor label "compiled world" or asset name matching `Model\d+_\d+`) and *keep/restore it
Static* instead of flipping it Movable like every other prop — this was necessary for
`CTF_USE_COMPLEX_AS_SIMPLE` collision to work, but a Static mesh with no baked lightmap
renders unlit (black) in an actual Play session, while the editor viewport can still show
a live unbuilt-lighting preview approximation that doesn't reflect what Play actually
uses. If the compiled-world shell is most of the visible level geometry (it likely is —
it's the BSP-compiled level mesh), forcing it back to Static for collision reasons may
have traded "wrong collision" for "renders black in Play," and that trade was made
without anyone testing actual Play at the time (movement testing that night used the
`-game` headless path, not interactive PIE/Standalone).

Confirm or rule this out directly: does the compiled-world shell actually have baked
lighting data (a lightmap) for its Static mobility to use? If not, either (a) it needs a
real lighting build (check whether this project's pipeline can/does run one, and whether
that's even feasible for a level this large), or (b) the collision fix needs a different
approach that doesn't require Static mobility (e.g. a separate invisible collision-only
proxy mesh, Static, alongside a Movable/dynamically-lit render mesh) — don't just flip
mobility back to Movable and silently reintroduce the collision regression h11 fixed.

## Other things to check if the above isn't the whole story

- Are there any actual light actors placed in the level at all with real intensity, or
  does the import pipeline's light-placement/intensity handling have its own separate gap
  between editor-preview and Play?
- Post-process / auto-exposure: a very common "looks fine in editor, black in Play"
  cause is eye-adaptation/auto-exposure starting from a dark-adapted state with a slow
  ramp, or a PostProcessVolume's exposure settings differing between editor and game
  camera. Check `AShockPlayer`'s camera/post-process setup for anything exposure-related.

## Tests / verify

Headless lighting state is hard to assert meaningfully without a real render — this is
likely a "human confirms in Play" task more than a scriptable one. If a specific mobility/
lightmap gap is confirmed as the cause, at minimum verify the fix doesn't reintroduce the
`run_collision.py`/`verify_collision.py` regression h11 fixed (still must report 0
errors).

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- Do not silently revert h11's Static-mobility collision fix to solve this — if that
  trade-off is real, say so explicitly and propose the dual-mesh (or other) alternative
  rather than trading one regression for the other.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
