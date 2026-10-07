"""Track E2 reader: frame-consistent reads through the proxy dxgi.dll's shared snapshot.

The proxy (native/dxgi_proxy) copies a list of memory regions into Local\\BioShockLiveSnapshot at
every Present. SnapshotProc wraps a bsmem.Proc with the same read()/u32() interface: reads of a
registered (addr, size) come from the newest snapshot, so a whole bridge frame sees one game frame;
anything new is read live once and registered for the next frame. Regions unused for a while are
dropped, so moving targets (reallocated bone arrays) don't pile up.

    snap = SnapshotProc.attach(proc)   # None when the proxy isn't loaded
    snap.begin_frame()                 # once per bridge frame, before its reads
"""
import ctypes
import mmap
import struct
import time

NAME = "Local\\BioShockLiveSnapshot"
MAGIC = 0x42534E50
MAX_REGIONS = 16384
HEADER_BYTES = 1 << 20
SLOT_BYTES = 8 << 20
SLOTS = 3
TOTAL = HEADER_BYTES + SLOTS * SLOT_BYTES
# Header: magic, version, request_seq, applied_seq, region_count, latest, frame, present_thread,
# main_thread, min_interval_us, reserved[6]; then regions[] of (addr, offset, size, flags).
HDR = struct.Struct("<4I i i i 3I 6I")
REGIONS_AT = HDR.size
SLOT_HDR = struct.Struct("<i I q I I i I")  # seq_begin, frame, qpc, bytes, failed, seq_end, pad

k32 = ctypes.WinDLL("kernel32", use_last_error=True)
k32.OpenFileMappingW.restype = ctypes.c_void_p


class SnapshotProc:
    def __init__(self, proc, view):
        self.p = proc
        self.h = proc.h
        self.view = view
        self.table = []        # [(addr, size)] in the order the DLL lays them out
        self.index = {}        # (addr, size) -> payload offset (valid once applied)
        self.pending = []
        self.in_table = set()  # queued or published, not necessarily applied yet
        self.last_used = {}
        self.seq = 0
        self.applied_layout = {}
        self.data = b""
        self.frame = -1
        self.stats = {"hits": 0, "misses": 0, "torn": 0, "stale": 0}
        self.next_prune = time.perf_counter() + 2.0
        self._write_header(min_interval_us=16000)  # ~60 snapshots/s: one syscall per region

    @classmethod
    def attach(cls, proc):
        if not k32.OpenFileMappingW(0x0004, False, NAME):  # FILE_MAP_READ: exists only if the proxy made it
            return None
        view = mmap.mmap(-1, TOTAL, tagname=NAME)
        if struct.unpack_from("<I", view, 0)[0] != MAGIC:
            return None
        return cls(proc, view)

    def _write_header(self, min_interval_us=None):
        if min_interval_us is not None:
            struct.pack_into("<I", self.view, 36, min_interval_us)

    def _publish(self):
        self.seq += 1  # odd: table being rewritten, the DLL skips snapshots
        struct.pack_into("<i", self.view, 8, self.seq)
        for i, (addr, size) in enumerate(self.table):
            struct.pack_into("<4I", self.view, REGIONS_AT + i * 16, addr, 0, size, 0)
        struct.pack_into("<I", self.view, 16, len(self.table))
        self.seq += 1  # even again: stable
        struct.pack_into("<i", self.view, 8, self.seq)
        layout, off = {}, 0
        for key in self.table:
            layout[key] = off
            off += key[1]
        self.pending_layout = (self.seq, layout)

    def begin_frame(self):
        magic, ver, req, applied, count, latest, frame = struct.unpack_from("<4I i i i", self.view, 0)
        # Adopt a published table only once the DLL has used it; publish again only when there is
        # something new (re-publishing every frame meant it never caught up: 0 hits, 7 Oct).
        if hasattr(self, "pending_layout") and applied >= self.pending_layout[0]:
            self.applied_layout = self.pending_layout[1]
            del self.pending_layout
        now = time.perf_counter()
        if not hasattr(self, "pending_layout") and (self.pending or now >= self.next_prune):
            if now >= self.next_prune:
                self.next_prune = now + 2.0
                self.table = [k for k in self.table if now - self.last_used.get(k, 0) < 2.0]
                self.in_table = set(self.table) | set(self.pending)
            seen = set(self.table)
            self.table += [k for k in dict.fromkeys(self.pending) if k not in seen][: MAX_REGIONS - len(self.table)]
            self.pending = []
            self._publish()
        if latest < 0:
            self.index = {}
            return False
        base = HEADER_BYTES + latest * SLOT_BYTES
        s0, sframe, qpc, nbytes, failed, s1, _ = SLOT_HDR.unpack_from(self.view, base)
        data = self.view[base + SLOT_HDR.size: base + SLOT_HDR.size + nbytes]
        s0b = struct.unpack_from("<i", self.view, base)[0]
        if s0 != s1 or s0b != s0:
            self.stats["torn"] += 1
            return False
        if sframe == self.frame:
            self.stats["stale"] += 1
        self.frame, self.data, self.failed = sframe, data, failed
        self.lag = frame - sframe  # game frames presented since this snapshot
        self.index = self.applied_layout
        return True

    def read(self, addr, n):
        key = (addr, n)
        off = self.index.get(key)
        self.last_used[key] = time.perf_counter()
        if off is not None and off + n <= len(self.data):
            self.stats["hits"] += 1
            return self.data[off: off + n]
        self.stats["misses"] += 1
        if key not in self.applied_layout and key not in self.in_table:
            self.pending.append(key)
            self.in_table.add(key)
        return self.p.read(addr, n)

    def u32(self, addr):
        b = self.read(addr, 4)
        return struct.unpack("<I", b)[0] if b and len(b) == 4 else None

    def regions(self, *a, **k):
        return self.p.regions(*a, **k)

    def scan(self, *a, **k):
        return self.p.scan(*a, **k)
