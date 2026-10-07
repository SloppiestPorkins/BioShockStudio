"""Fit the texture scale of every BSP material against the running game.

Renders the exported baked-world geometry (Exports/baked/<map>/<map>/Model1_slots.gltf) from the
game's exact camera, then for each material on screen compares the game frame with that
material's diffuse texture sampled at the exported UVs times a candidate scale. The best scale per
material tells how the remaster really maps BSP textures (the exporter's rule was a guess; the
live floor in Medical measured 2x the exported tile size, the corridor ceiling far more).

  python tools/livegame/uv_fit.py            (BioShock running, standing still, no menu open)

Prints one row per material: pixels on screen, original/shipped texture size, the exporter's
divisor, the best UV scale and its correlation, and the runner-up. Writes uv_fit.json and an
image of material ids next to the game frame into %TEMP%/uv_fit/.
"""
import json
import math
import os
import struct
import subprocess
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bsobj import World  # noqa: E402

UE = r"C:/Users/Jack/Documents/BioShockUE5"
ORIG = r"G:/SteamLibrary/steamapps/common/Bioshock/Builds/Release/UmodelExport"
SCALES = [4.0, 2.0, 1.0, 0.5, 0.25, 0.125]
OUT = os.path.join(os.environ["TEMP"], "uv_fit")
os.makedirs(OUT, exist_ok=True)


def live_camera():
    w = World()
    p = w.p
    objs = {w.full_name(o): o for o in w.obj_ptrs if o}
    off = lambda n: p.u32(objs[n] + 0x74)
    level = next(k.split(".")[0] for k in objs if k.endswith(".ShockPlayerController0"))
    pc = objs[f"{level}.ShockPlayerController0"]
    pawn = p.u32(pc + off("Engine.Controller.Pawn"))
    loc = struct.unpack("<3f", p.read(pawn + off("Engine.Actor.Location"), 12))
    eye = struct.unpack("<f", p.read(pawn + off("Engine.Pawn.EyeHeight"), 4))[0]
    rot = struct.unpack("<3i", p.read(pc + off("Engine.Actor.Rotation"), 12))
    fov = struct.unpack("<f", p.read(pc + off("Engine.PlayerController.DesiredFOV"), 4))[0]
    return level, np.array([loc[0], loc[1], loc[2] + eye]), rot, fov


def grab(path):
    here = os.path.dirname(os.path.abspath(__file__))
    subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                    os.path.join(here, "grab_game.ps1"), "-Out", path], check=True, capture_output=True)
    return Image.open(path).convert("L")


def load_gltf(level):
    d = os.path.join(UE, "Exports", "baked", level, level)
    g = json.load(open(os.path.join(d, "Model1_slots.gltf")))
    buf = open(os.path.join(d, "Model1_slots.bin"), "rb").read()

    def acc(i):
        a = g["accessors"][i]
        bv = g["bufferViews"][a["bufferView"]]
        n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3}[a["type"]]
        dt = {5126: "f4", 5125: "u4", 5123: "u2"}[a["componentType"]]
        r = np.frombuffer(buf, dtype=dt, count=a["count"] * n, offset=bv.get("byteOffset", 0) + a.get("byteOffset", 0))
        return r.reshape(-1, n) if n > 1 else r

    prims = []
    for prim in g["meshes"][0]["primitives"]:
        r = acc(prim["attributes"]["POSITION"]).astype(float)
        pos = np.stack([r[:, 0] * 100, r[:, 2] * 100, r[:, 1] * 100], 1)  # glTF convention -> game units
        uv = acc(prim["attributes"]["TEXCOORD_1"]).astype(float)       # the material UV channel
        prims.append((g["materials"][prim["material"]]["name"], pos, uv, acc(prim["indices"]).reshape(-1, 3)))
    return prims


def raster(prims, eye, rot, hfov, w, h):
    u = lambda r: r * 2 * math.pi / 65536
    pit, yaw, rol = u(rot[0]), u(rot[1]), u(rot[2])
    fwd = np.array([math.cos(pit) * math.cos(yaw), math.cos(pit) * math.sin(yaw), math.sin(pit)])
    right = np.array([-math.sin(yaw), math.cos(yaw), 0.0])
    up = np.cross(right, fwd) * -1  # Unreal is left-handed: up = right x forward with a sign flip
    up = np.cross(fwd, right) if np.dot(np.cross(fwd, right), [0, 0, 1]) > 0 else -np.cross(fwd, right)
    if rol:
        c, s = math.cos(rol), math.sin(rol)
        right, up = right * c + up * s, up * c - right * s
    f = (w / 2) / math.tan(math.radians(hfov) / 2)
    depth = np.full((h, w), np.inf)
    mid = np.full((h, w), -1, int)
    uvb = np.zeros((h, w, 2))
    names = []
    for mi, (name, pos, uv, idx) in enumerate(prims):
        names.append(name)
        v = pos - eye
        z = v @ fwd
        sx = w / 2 + (v @ right) / np.maximum(z, 1e-3) * f
        sy = h / 2 - (v @ up) / np.maximum(z, 1e-3) * f
        for tri in idx:
            zt = z[tri]
            if (zt < 5).any():
                continue
            xs, ys = sx[tri], sy[tri]
            x0, x1 = max(int(xs.min()), 0), min(int(xs.max()) + 1, w)
            y0, y1 = max(int(ys.min()), 0), min(int(ys.max()) + 1, h)
            if x0 >= x1 or y0 >= y1:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
            (ax, bx, cx), (ay, by, cy) = xs, ys
            den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
            if abs(den) < 1e-9:
                continue
            l0 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / den
            l1 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / den
            l2 = 1 - l0 - l1
            inside = (l0 >= 0) & (l1 >= 0) & (l2 >= 0)
            if not inside.any():
                continue
            iz = l0 / zt[0] + l1 / zt[1] + l2 / zt[2]  # perspective-correct
            zz = 1 / iz
            sub = depth[y0:y1, x0:x1]
            win = inside & (zz < sub)
            if not win.any():
                continue
            t = uv[tri]
            uu = (l0 * t[0, 0] / zt[0] + l1 * t[1, 0] / zt[1] + l2 * t[2, 0] / zt[2]) * zz
            vv = (l0 * t[0, 1] / zt[0] + l1 * t[1, 1] / zt[1] + l2 * t[2, 1] / zt[2]) * zz
            sub[win] = zz[win]
            mid[y0:y1, x0:x1][win] = mi
            uvb[y0:y1, x0:x1, 0][win] = uu[win]
            uvb[y0:y1, x0:x1, 1][win] = vv[win]
    return mid, uvb, names


def highpass(a):
    from PIL import ImageFilter
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    blur = np.asarray(im.filter(ImageFilter.GaussianBlur(12)), float)
    return a - blur


def material_info(level):
    m = json.load(open(os.path.join(UE, "Exports", "live", level, level, f"{level}.ue5-level.json"), encoding="utf-8"))
    return {x["name"]: x for x in m["materials"]}


def main():
    level, eye, rot, fov = live_camera()
    game = grab(os.path.join(OUT, "game.png"))
    W, H = game.size
    w, h = W // 2, H // 2
    gimg = np.asarray(game.resize((w, h)), float)
    hfov = 2 * math.degrees(math.atan(math.tan(math.radians(fov / 2)) * (W / H) / (4 / 3)))
    prims = load_gltf(level)
    mid, uvb, names = raster(prims, eye, rot, hfov, w, h)
    ghp = highpass(gimg)
    mats = material_info(level)
    tex_dir = os.path.join(UE, "Exports", "live", level, level)
    rows = []
    for mi in np.unique(mid[mid >= 0]):
        mask = mid == mi
        n = int(mask.sum())
        if n < 1500:
            continue
        slot = names[mi]
        base = slot.split("__", 1)[1].rsplit("__", 1)[0] if "__" in slot else slot
        info = mats.get(base)
        if not info or not info.get("diffuse"):
            continue
        path = os.path.join(tex_dir, info["diffuse"])
        if not os.path.exists(path):
            continue
        tex = np.asarray(Image.open(path).convert("L").resize((512, 512)), float)
        origp = os.path.join(ORIG, level, "Texture", os.path.basename(info["diffuse"]))
        orig = Image.open(origp).size[0] if os.path.exists(origp) else None
        shipped = Image.open(path).size[0]
        scores = []
        for s in SCALES:
            uv = uvb[mask] * s
            tx = (np.mod(uv[:, 0], 1) * 511).astype(int)
            ty = (np.mod(uv[:, 1], 1) * 511).astype(int)
            pred = np.zeros((h, w))
            pred[mask] = tex[ty, tx]
            php = highpass(np.where(mask, pred, pred[mask].mean()))
            a, b = php[mask], ghp[mask]
            r = float(np.corrcoef(a, b)[0, 1]) if a.std() > 0 and b.std() > 0 else 0.0
            scores.append((r, s))
        scores.sort(reverse=True)
        rows.append({"slot": slot, "material": base, "pixels": n, "orig": orig, "shipped": shipped,
                     "best": scores[0][1], "r": round(scores[0][0], 3), "second": scores[1][1], "r2": round(scores[1][0], 3)})
    rows.sort(key=lambda r: -r["pixels"])
    print(f"{level}: eye {eye.round(0)} rot {rot} hfov {hfov:.1f}")
    print(f"{'material':42s} {'px':>6} {'orig':>5} {'ship':>5}  best   r     2nd    r")
    for r in rows:
        print(f"{r['material'][:42]:42s} {r['pixels']:6d} {str(r['orig']):>5} {r['shipped']:5d}  {r['best']:<5} {r['r']:<5}  {r['second']:<5} {r['r2']}")
    json.dump(rows, open(os.path.join(OUT, "uv_fit.json"), "w"), indent=1)
    ids = np.zeros((h, w, 3), np.uint8)
    rng = np.random.default_rng(1)
    pal = rng.integers(40, 255, (len(names), 3))
    ids[mid >= 0] = pal[mid[mid >= 0]]
    side = Image.new("RGB", (w * 2, h))
    side.paste(Image.fromarray(gimg.astype(np.uint8)).convert("RGB"), (0, 0))
    side.paste(Image.fromarray(ids), (w, 0))
    side.save(os.path.join(OUT, "ids.png"))


if __name__ == "__main__":
    main()
