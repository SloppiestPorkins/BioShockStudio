# Hack-failure self-damage could kill the player

Found during the same guide cross-reference pass as the other fixes this session.

`32-Hacking.md`: "The damage of a failure is never lethal: it is capped one point below the
player's health." Neither of the runtime's two hack-failure damage call sites honored this —
both applied a flat, uncapped amount straight through `AShockPawn::ApplyAuthoredDamage`, which
has no lethality guard of its own:

- `AShockPlayer::TryHackDevice`'s instant-fallback path (used when the real minigame widget
  fails to create): flat `HackFailSelfDamage` (5.0, itself an acknowledged "PLAUSIBLE... stand-in"
  since the real per-puzzle `DamageDealtOnOverload`/`DamageDealtOnShortCircuit` values from
  `Hacking.ini` aren't imported).
- `UShockHackingMinigame::FinishFail` (the real pipe-puzzle widget's failure path): flat
  `OverloadDamage` or `5.0f`.

A player at low health failing a hack could die from it — something that never happens in the
real game. Both sites now clamp to `min(RawDamage, CurrentHealth - 1)` before applying, so a
failure always leaves the player at 1 HP or above.

This doesn't fix the larger acknowledged gap (the flat placeholder damage values instead of
reading the real per-deck `Hacking.ini` numbers) — that's unchanged, still a known
simplification. This fixes the one guarantee the guide states explicitly regardless of which
numbers are used: a hack failure cannot kill you.

## Verify

`verify_hacking.py` gained `hack_fail_never_lethal`: brings a player down to 2 HP, fails a hack,
confirms health lands at exactly 1 (not 0, not negative, not dead). No regressions:
`verify_hacking.py` (full suite), `verify_hacking_minigame.py`, `verify_security.py`.
