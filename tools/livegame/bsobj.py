"""BioShock Remastered (BioshockHD.exe) object model, read-only.

Found 6 Oct 2026 by memory search; offsets are relative to the exe image base:
  FName::Names        TArray<FNameEntry*> at image + 0x13904EC; entry = {int Index; u64 Flags; ptr HashNext; wchar Name[]}
  UObject::GObjObjects TArray<UObject*> at image + 0x139042C
UObject (32-bit): +0x04 Index, +0x1C Outer, +0x28 Name (FName index), +0x2C name Number
(suffix = Number-1 appended with no separator when Number > 0), +0x30 Class.
"""
import struct

from bsmem import Proc, MBI, k32
import ctypes

NAMES_RVA = 0x13904EC
OBJECTS_RVA = 0x139042C
O_OUTER, O_NAME, O_NUM, O_CLASS = 0x1C, 0x28, 0x2C, 0x30


def image_base(p, probe_addr):
    mbi = MBI()
    k32.VirtualQueryEx(p.h, ctypes.c_void_p(probe_addr), ctypes.byref(mbi), ctypes.sizeof(mbi))
    return mbi.AllocationBase


class World:
    def __init__(self, base=None):
        self.p = Proc()
        self.base = base if base is not None else self._find_base()
        self.refresh()

    def _find_base(self):
        # The exe is the MEM_IMAGE allocation whose first bytes are 'MZ' and that is ~21 MB: take the
        # module list from the process instead of guessing.
        import subprocess
        out = subprocess.run(["powershell", "-NoProfile", "-Command",
                              f"(Get-Process -Id {self.p.pid}).MainModule.BaseAddress.ToInt64()"],
                             capture_output=True, text=True).stdout.strip()
        return int(out)

    def refresh(self):
        p = self.p
        nd, nn, _ = struct.unpack("<3I", p.read(self.base + NAMES_RVA, 12))
        od, on, _ = struct.unpack("<3I", p.read(self.base + OBJECTS_RVA, 12))
        self.name_ptrs = struct.unpack(f"<{nn}I", p.read(nd, 4 * nn))
        self.obj_ptrs = struct.unpack(f"<{on}I", p.read(od, 4 * on))
        self._names = {}

    def name(self, i):
        if i in self._names:
            return self._names[i]
        e = self.name_ptrs[i] if 0 <= i < len(self.name_ptrs) else 0
        s = None
        if e:
            # A 256-byte read fails outright when the entry sits near the end of an allocation
            # (which name breaks changes with every launch: 7 Oct it was "Region"); retry shorter.
            for n in (256, 96, 48, 24):
                b = self.p.read(e + 16, n)
                if b:
                    break
            s = b.decode("utf-16-le", "replace").split("\0")[0] if b else None
        self._names[i] = s
        return s

    def header(self, o):
        b = self.p.read(o, 0x34)
        if not b or len(b) < 0x34:
            return None
        return {"outer": struct.unpack_from("<I", b, O_OUTER)[0], "name": struct.unpack_from("<I", b, O_NAME)[0], "num": struct.unpack_from("<I", b, O_NUM)[0],
                "cls": struct.unpack_from("<I", b, O_CLASS)[0]}

    def obj_name(self, o):
        h = self.header(o)
        return self._fname(h) if h else None

    def _fname(self, h):
        base = self.name(h["name"]) or "?"
        return f"{base}{h['num'] - 1}" if h["num"] > 0 else base

    def full_name(self, o):
        parts, cur, guard = [], o, 0
        while cur and guard < 8:
            h = self.header(cur)
            if not h:
                break
            parts.append(self._fname(h))
            cur, guard = h["outer"], guard + 1
        return ".".join(reversed([x or "?" for x in parts]))

    def class_name(self, o):
        h = self.header(o)
        return self.obj_name(h["cls"]) if h and h["cls"] else None
