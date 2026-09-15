---
worker: claude-direct
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**
---

# R3.1/3.2 — EffectsSystem subsystem + ActionPlayEffect/StopEffect/PlayEffectAndWaitForStart/SetEffectsSystemContext real

Done directly by Claude (16 Sept) rather than dispatched — see `docs/research/effects-system.md`
for the full design, scope note (event/tag-name + keyword-heuristic resolution in place of the
never-recovered real per-(event,context,surface) authoring tables), and follow-ups (R3.3 curated
FX pack, R3.4 skeletal-prop anim, context-aware resolution).

Landed `c8f451a`. `verify_effects_system.py` 5/5. No regressions
(`verify_reflection_actions` 7/7, `run_import_scripts` R1.1 5/5, `run_weapon_feedback`,
`run_verify_audio`, `verify_plasmid` 55).
