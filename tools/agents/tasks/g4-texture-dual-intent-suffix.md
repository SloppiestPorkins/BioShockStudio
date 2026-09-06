---
worker: chatgpt
base: main
verify: python tools/ue5/test_texture_intent.py
lane: tools/ue5/texture_intent.py, tools/ue5/test_texture_intent.py
---

# A pure-python helper for per-intent texture asset naming

## The bug this feeds

`tools/ue5/import_bioshock.py::_import_textures` (around line 281) has this comment:

> The same PNG can be bound twice with different intent. Import it once per distinct
> intent, **suffixed**, so neither binding has to compromise on colour space.

The code does NOT suffix. It keys de-dup on `(stem, srgb)` but imports every distinct key to
the SAME asset path `f"{destination}/Textures/{stem}"` with `replace_existing=True`, so the
second intent silently **overwrites** the first. A colour diffuse texture that is also bound
somewhere as an R-channel mask gets clobbered to `srgb=False` / `TC_MASKS`, which is the
"41 diffuse textures clobbered" wall-regression that has recurred (`0f635bf`).

The real fix will wire a naming helper into `_import_textures`, but that file is owned by
another task right now. **Your job is only the pure, unit-tested helper.** Someone else
wires it in.

## Deliverable

### `tools/ue5/texture_intent.py`

No `import unreal`. Pure functions:

```python
def intent_key(stem: str, srgb: bool, usage: str, is_opacity: bool) -> tuple:
    """A hashable identity for one (texture file, engine intent) pair.
    usage is the manifest 'usage' string: 'Diffuse' | 'NormalMap' | 'Mask' | 'Height' | ...
    """

def asset_name(stem: str, srgb: bool, usage: str, is_opacity: bool, *, is_primary: bool) -> str:
    """UE asset name for this intent.
      - The PRIMARY intent for a stem keeps the bare stem ('med_wall_public_dirt').
      - Any SECONDARY intent gets a deterministic suffix that names the intent, not a
        counter: '<stem>_mask' for opacity/Mask, '<stem>_data' for a non-sRGB colour reuse,
        '<stem>_n' for NormalMap. Never '<stem>_1'.
    """

def classify(entries: list[dict], opacity_pairs: set) -> dict:
    """Given the manifest 'textures' list (each entry has at least 'file', 'material',
    'usage', 'colourSpace') and the set of (material_name, file) pairs that are opacity
    bindings, return a dict keyed by entry id(entry) -> {'name': str, 'srgb': bool,
    'is_primary': bool}. The primary intent for a stem is the FIRST one encountered in list
    order that is a colour/sRGB diffuse; if a stem has no sRGB diffuse binding, the first
    entry in list order is primary. Deterministic for a given list order."""
```

Keep it small. `srgb` for an entry = `False` if it is an opacity binding, else
`entry['colourSpace'] == 'Srgb'` — mirror what `_import_textures` already computes; do not
re-derive colour space from anything else.

### `tools/ue5/test_texture_intent.py`

`unittest`, runnable as `python tools/ue5/test_texture_intent.py` (mirror the style of
`tools/ue5/test_import_policy.py` — `sys.path.insert(0, dirname)`, a `unittest.main()`
guard). Cover:

1. A stem bound once as sRGB diffuse → `asset_name` returns the bare stem, `is_primary` True.
2. The SAME stem also bound as an R-channel mask on another material → the mask intent gets
   `<stem>_mask`, the diffuse stays bare. Two distinct assets, the diffuse is NOT the one
   that gets the suffix.
3. A stem bound only as a normal map → bare stem (it is the only/primary intent), no `_n`.
4. A stem bound as sRGB diffuse AND as non-sRGB colour (data) → diffuse bare, the data reuse
   → `<stem>_data`.
5. `classify` is deterministic: same input list twice → identical output.
6. Order independence of the DECISION but not the primary pick: document in a comment that
   primary = first sRGB diffuse in list order.

## Do NOT

- Do not `import unreal`, do not touch `import_bioshock.py` or any other file.
- Do not add a claim-table row to `docs/HANDOFF.md`.
- Do not commit.
