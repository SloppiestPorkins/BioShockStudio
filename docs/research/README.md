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
| [remastered.md](remastered.md) | Install layout, file types, what shipped where. |
| [packages.md](packages.md) | The `.bsm` package format — header, names, imports, exports. |
| [havok.md](havok.md) | Havok 2012.2.0-r1 packfile container as BioShock uses it. |
| [animationpackage.md](animationpackage.md) | `AnimationPackageWrapper` / `AnimationPackageRoot`. |
| [firstperson.md](firstperson.md) | First-person hands, weapons and the pistol target case. |
| [external-projects.md](external-projects.md) | Prior art and the cross-game Havok matrix. |
| [open-questions.md](open-questions.md) | What is still unknown, in priority order. |

## Ground rules

1. No hypothesis becomes a hardcoded parser. If a field is not understood, it is named
   `Unknown*` and preserved.
2. Every reverse-engineered structure gets a regression test that reads real game bytes.
   There are no synthetic fixtures in this repository.
3. A parse that "looks right once" is not a result. The package layout below is trusted because
   all 21 shipped packages consume to the exact byte, not because one sample worked.
