# Research notes

Every claim in these documents carries a confidence label:

| Label | Meaning |
|---|---|
| `CONFIRMED_BYTES` | Verified against real shipped BioShock 1 Remastered bytes, with a regression test. |
| `CONFIRMED_EXTERNAL` | Documented in an external project's source that we have read directly. |
| `CORROBORATED` | Two or more independent sources agree, but we have not verified the bytes ourselves. |
| `LIKELY` | Consistent with observation, no contradicting evidence, not yet proven. |
| `HYPOTHESIS` | A guess that explains what we see. **Never** hardcoded into a parser. |
| `UNKNOWN` | Observed but not understood. Preserved raw. |

## Index

| Document | Covers |
|---|---|
| [ANIMATION_COORDINATE_SYSTEM.md](ANIMATION_COORDINATE_SYSTEM.md) | The game's basis, the studio's, and the one reflection between them. Read before touching any transform. |
| [remastered.md](remastered.md) | Install layout, file types, what shipped where. |
| [packages.md](packages.md) | The `.bsm` package format — header, names, imports, exports. |
| [havok.md](havok.md) | Havok 2012.2.0-r1 packfile container as BioShock uses it. |
| [havok-compression.md](havok-compression.md) | Spline compression and quantised quaternions. |
| [binding.md](binding.md) | Track-to-bone binding, and why it must precede decoding. |
| [root-motion.md](root-motion.md) | Havok root motion (`m_extractedMotion`) — present on 39.6% of animations, previously unread. |
| [havok-physics.md](havok-physics.md) | Havok collision/ragdoll data — `hkpCapsuleShape` decoded; census and a scoped plan for the rest. |
| [skeletalmesh.md](skeletalmesh.md) | Skinned mesh — header, sockets, bone map, geometry, weights. |
| [staticmesh.md](staticmesh.md) | Static mesh — the props that hang off sockets. |
| [animationpackage.md](animationpackage.md) | `AnimationPackageWrapper` / `AnimationPackageRoot`. |
| [firstperson.md](firstperson.md) | First-person hands, weapons and the pistol target case. |
| [fbx.md](fbx.md) | The FBX the exporter writes, and what it cannot carry. |
| [bulkcontent.md](bulkcontent.md) | The 8 GB of stripped texture mips, and the catalogue into them. |
| [materials.md](materials.md) | `Shader` objects, and how a mesh names the one it uses. |
| [effects.md](effects.md) | Particle emitters — the whole-game template census Gate 4 item 3's Niagara mapping has to be built against. |
| [interaction.md](interaction.md) | Movers and trigger wiring — `TriggeredBy` as the interaction object graph, and what's deliberately deferred (keyframe paths, doors, triggers' own resolution). |
| [bsp.md](bsp.md) | `Model` / `Polys` — the source brushes (decoded) and the built world (documented, not implemented). |
| [external-projects.md](external-projects.md) | Prior art and the cross-game Havok matrix. |
| [reference-comparison.md](reference-comparison.md) | **What each reference project says about the structures we read, field by field, and where they disagree.** Read before deriving anything from bytes. |
| [open-questions.md](open-questions.md) | What is still unknown, in priority order. |

## Ground rules

1. No hypothesis becomes a hardcoded parser. If a field is not understood, it is named
   `Unknown*` and preserved.
2. Every reverse-engineered structure gets a regression test that reads real game bytes.
   There are no synthetic fixtures in this repository.
3. A parse that "looks right once" is not a result. The package layout below is trusted because
   all 21 shipped packages consume to the exact byte, not because one sample worked.
4. **A finding carries the measurement that produced it, separately from the conclusion drawn from
   it.** That is what the `diagnose` command's `Evidence` field is, and what makes a report usable by
   a session that did not produce it. `docs/QUALITY.md`.
