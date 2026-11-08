import os, re
from pathlib import Path

roots = []
env = os.environ.get("BIOSHOCK_REMASTERED_PATH")
if env:
    roots.append(Path(env))
for drive in ["C:", "D:"]:
    p = Path(f"{drive}/Program Files (x86)/Steam/steamapps/libraryfolders.vdf")
    if p.exists():
        text = p.read_text(errors="ignore")
        for m in re.finditer(r'"path"\s+"([^"]+)"', text):
            lib = Path(m.group(1).replace("\\\\", "\\"))
            roots.append(lib / "steamapps" / "common" / "BioShock Remastered")
    roots.append(Path(f"{drive}/Program Files (x86)/Steam/steamapps/common/BioShock Remastered"))

for r in roots:
    m = r / "ContentBaked" / "pc" / "Maps" / "1-Medical.bsm"
    if m.exists():
        print("FOUND", m)
        break
else:
    print("NOT FOUND")
    for r in roots[:15]:
        print(" tried", r)
