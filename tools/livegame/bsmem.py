"""Read-only access to a running BioshockHD.exe (32-bit) process memory."""
import ctypes
import ctypes.wintypes as wt
import struct
import subprocess

k32 = ctypes.WinDLL("kernel32", use_last_error=True)
PROCESS_VM_READ = 0x10
PROCESS_QUERY_INFORMATION = 0x400


class MBI(ctypes.Structure):
    _fields_ = [("BaseAddress", ctypes.c_void_p), ("AllocationBase", ctypes.c_void_p),
                ("AllocationProtect", wt.DWORD), ("PartitionId", wt.WORD), ("RegionSize", ctypes.c_size_t),
                ("State", wt.DWORD), ("Protect", wt.DWORD), ("Type", wt.DWORD)]


k32.OpenProcess.restype = wt.HANDLE
k32.ReadProcessMemory.argtypes = [wt.HANDLE, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_size_t, ctypes.POINTER(ctypes.c_size_t)]
k32.VirtualQueryEx.argtypes = [wt.HANDLE, ctypes.c_void_p, ctypes.POINTER(MBI), ctypes.c_size_t]
k32.VirtualQueryEx.restype = ctypes.c_size_t


def find_pid(name="BioshockHD.exe"):
    out = subprocess.run(["tasklist", "/FI", f"IMAGENAME eq {name}", "/FO", "CSV", "/NH"],
                         capture_output=True, text=True).stdout
    for line in out.splitlines():
        parts = [p.strip('"') for p in line.split('","')]
        if parts and parts[0].lower() == name.lower():
            return int(parts[1])
    raise SystemExit("game not running")


class Proc:
    def __init__(self, pid=None):
        self.pid = pid or find_pid()
        self.h = k32.OpenProcess(PROCESS_VM_READ | PROCESS_QUERY_INFORMATION, False, self.pid)
        if not self.h:
            raise OSError(ctypes.get_last_error())

    def read(self, addr, n):
        buf = ctypes.create_string_buffer(n)
        got = ctypes.c_size_t(0)
        if not k32.ReadProcessMemory(self.h, ctypes.c_void_p(addr), buf, n, ctypes.byref(got)):
            return None
        return buf.raw[:got.value]

    def u32(self, addr):
        b = self.read(addr, 4)
        return struct.unpack("<I", b)[0] if b and len(b) == 4 else None

    def regions(self, max_addr=0xFFFF0000):
        addr, mbi = 0, MBI()
        while addr < max_addr:
            if not k32.VirtualQueryEx(self.h, ctypes.c_void_p(addr), ctypes.byref(mbi), ctypes.sizeof(mbi)):
                break
            base, size = mbi.BaseAddress or 0, mbi.RegionSize
            # committed, readable, not guard/noaccess
            if mbi.State == 0x1000 and (mbi.Protect & 0xEE) and not (mbi.Protect & 0x101):
                yield base, size, mbi.Protect, mbi.Type
            addr = base + size

    def scan(self, needle, limit=50, chunk=1 << 22):
        hits = []
        for base, size, prot, typ in self.regions():
            off = 0
            while off < size:
                n = min(chunk, size - off)
                # Overlap into the next chunk only inside this region: reading past the region end
                # fails the whole read when the next region is unreadable.
                b = self.read(base + off, min(n + len(needle), size - off))
                if b:
                    i = b.find(needle)
                    while i != -1:
                        hits.append(base + off + i)
                        if len(hits) >= limit:
                            return hits
                        i = b.find(needle, i + 1)
                off += n
        return hits
