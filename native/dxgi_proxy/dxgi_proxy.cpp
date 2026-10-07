// Track E, step E1: a proxy dxgi.dll for BioshockHD.exe (32-bit, Direct3D 11).
//
// Placed next to BioshockHD.exe, the game loads it instead of the system dxgi.dll. Every export
// forwards to the real one in SysWOW64; CreateDXGIFactory/1/2 additionally hook the factory's
// CreateSwapChain so the swap chain's Present - called once per rendered frame - can be counted.
// E1 only proves the way in: it logs frames to %TEMP%\bioshock-e1.log and changes nothing.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <dxgi1_2.h>
#include <d3d11.h>
#include <string>
#include <cstdio>
#include <share.h>

static HMODULE g_real;
static FILE* g_log;
static LARGE_INTEGER g_freq, g_start;
static LONG g_frames;
static DWORD g_mainThread;

// ---- E2 snapshot ---------------------------------------------------------------------------
namespace snap
{
const DWORD kMagic = 0x42534E50;  // 'BSNP'
const DWORD kMaxRegions = 16384;
const DWORD kSlotBytes = 8u << 20;
const DWORD kHeaderBytes = 1u << 20;
const DWORD kSlots = 3;

struct Region { DWORD addr, offset, size, flags; };  // flags bit0: indirect (*(DWORD*)addr + offset)

#pragma pack(push, 4)
struct Header
{
    DWORD magic, version;
    volatile LONG request_seq;   // odd while the reader rewrites the region table
    volatile LONG applied_seq;   // DLL echoes request_seq once it has used that table
    DWORD region_count;
    volatile LONG latest;        // slot index of the newest complete snapshot (-1: none)
    volatile LONG frame;         // game frames presented so far
    DWORD present_thread, main_thread;
    DWORD min_interval_us;       // reader's requested minimum time between snapshots
    DWORD reserved[6];
    Region regions[kMaxRegions];
};
struct SlotHeader
{
    volatile LONG seq_begin;     // == seq_end when the slot is consistent
    DWORD frame;
    LARGE_INTEGER qpc;
    DWORD bytes, failed;         // payload bytes, regions that could not be read
    volatile LONG seq_end;
    DWORD pad;
};
#pragma pack(pop)

static HANDLE g_map;
static BYTE* g_base;
static Header* g_hdr;
static LARGE_INTEGER g_last;

static bool Open()
{
    if (g_base) return true;
    const DWORD total = kHeaderBytes + kSlots * kSlotBytes;
    g_map = CreateFileMappingA(INVALID_HANDLE_VALUE, nullptr, PAGE_READWRITE, 0, total, "Local\\BioShockLiveSnapshot");
    if (!g_map) return false;
    g_base = static_cast<BYTE*>(MapViewOfFile(g_map, FILE_MAP_ALL_ACCESS, 0, 0, total));
    if (!g_base) return false;
    g_hdr = reinterpret_cast<Header*>(g_base);
    g_hdr->version = 1;
    g_hdr->latest = -1;
    g_hdr->main_thread = g_mainThread;
    g_hdr->magic = kMagic;
    return true;
}

// ReadProcessMemory on our own process: a dead pointer just fails. Never fault here - the game's
// vectored exception handlers would run, and with the main thread paused one of them deadlocked
// the game (7 Oct: frozen at frame 9670 the moment the reader's region list arrived).
static bool Copy(BYTE* dst, const Region& r)
{
    const HANDLE self = GetCurrentProcess();
    DWORD src = r.addr;
    SIZE_T got = 0;
    if (r.flags & 1)
    {
        DWORD ptr = 0;
        if (!ReadProcessMemory(self, reinterpret_cast<LPCVOID>(r.addr), &ptr, 4, &got) || !ptr)
        {
            memset(dst, 0, r.size);
            return false;
        }
        src = ptr + r.offset;
    }
    if (!ReadProcessMemory(self, reinterpret_cast<LPCVOID>(src), dst, r.size, &got) || got != r.size)
    {
        memset(dst, 0, r.size);
        return false;
    }
    return true;
}

static void Take(LONG frame)
{
    if (!Open()) return;
    Header* h = g_hdr;
    h->frame = frame;
    h->present_thread = GetCurrentThreadId();
    LARGE_INTEGER now;
    QueryPerformanceCounter(&now);
    if (h->min_interval_us && g_last.QuadPart &&
        double(now.QuadPart - g_last.QuadPart) * 1e6 / double(g_freq.QuadPart) < h->min_interval_us)
        return;
    g_last = now;
    const LONG seq = h->request_seq;
    if (seq & 1) return;  // the reader is rewriting the region table
    const DWORD n = h->region_count < kMaxRegions ? h->region_count : kMaxRegions;
    const LONG slot = (h->latest + 1 + kSlots) % kSlots;
    BYTE* base = g_base + kHeaderBytes + slot * kSlotBytes;
    SlotHeader* sh = reinterpret_cast<SlotHeader*>(base);
    InterlockedIncrement(&sh->seq_begin);
    BYTE* out = base + sizeof(SlotHeader);
    const BYTE* end = base + kSlotBytes;
    DWORD failed = 0;
    // Present runs on the render thread; the game logic runs on the main thread. Pause the main
    // thread for the copy (microseconds; memcpy only, no locks) so nothing changes mid-snapshot.
    static HANDLE mainThread = OpenThread(THREAD_SUSPEND_RESUME, FALSE, g_mainThread);
    const bool paused = mainThread && GetCurrentThreadId() != g_mainThread && SuspendThread(mainThread) != DWORD(-1);
    for (DWORD i = 0; i < n; ++i)
    {
        const Region r = h->regions[i];
        if (out + r.size > end) break;
        if (!Copy(out, r)) ++failed;
        out += r.size;
    }
    if (paused) ResumeThread(mainThread);
    if (h->request_seq != seq)  // table changed under us: this copy mixes layouts
    {
        sh->seq_end = sh->seq_begin - 1;
        return;
    }
    sh->frame = frame;
    sh->qpc = now;
    sh->bytes = DWORD(out - (base + sizeof(SlotHeader)));
    sh->failed = failed;
    sh->seq_end = sh->seq_begin;
    MemoryBarrier();
    h->latest = slot;
    h->applied_seq = seq;
}
}  // namespace snap

static void Log(const char* fmt, ...)
{
    if (!g_log) return;
    LARGE_INTEGER now;
    QueryPerformanceCounter(&now);
    fprintf(g_log, "%10.3f ", double(now.QuadPart - g_start.QuadPart) * 1000.0 / double(g_freq.QuadPart));
    va_list args;
    va_start(args, fmt);
    vfprintf(g_log, fmt, args);
    va_end(args);
    fputc('\n', g_log);
    fflush(g_log);
}

static void* Real(const char* name)
{
    if (!g_real)
    {
        char path[MAX_PATH];
        GetSystemDirectoryA(path, MAX_PATH);  // SysWOW64 for a 32-bit process
        strcat_s(path, "\\dxgi.dll");
        g_real = LoadLibraryA(path);
    }
    return g_real ? reinterpret_cast<void*>(GetProcAddress(g_real, name)) : nullptr;
}

// Patch one vtable slot; returns the original function.
static void* HookSlot(void* object, int slot, void* replacement)
{
    void** vtable = *reinterpret_cast<void***>(object);
    if (vtable[slot] == replacement) return nullptr;
    DWORD old;
    VirtualProtect(&vtable[slot], sizeof(void*), PAGE_EXECUTE_READWRITE, &old);
    void* original = vtable[slot];
    vtable[slot] = replacement;
    VirtualProtect(&vtable[slot], sizeof(void*), old, &old);
    return original;
}

// ---- E3/E4 groundwork: one-frame trace of render-target switches and draws ------------------
// Create %TEMP%\bioshock-trace-request and the next whole frame is written to
// %TEMP%\bioshock-frame-trace.txt: every OMSetRenderTargets (target size/format, whether it is the
// back buffer), clears, copies and how many draws went to each target - to find where the world
// ends and the HUD begins.
namespace trace
{
static volatile LONG g_active;  // 1 while recording the current frame
static std::string g_buf;
static int g_draws;
static ID3D11Resource* g_backbuffer;
static IDXGISwapChain* g_chain;

static void Flush()
{
    if (g_draws)
    {
        char line[64];
        sprintf_s(line, "    %d draws\n", g_draws);
        g_buf += line;
        g_draws = 0;
    }
}

static void Describe(ID3D11RenderTargetView* rtv, char* out, size_t n)
{
    if (!rtv) { strcpy_s(out, n, "null"); return; }
    ID3D11Resource* res = nullptr;
    rtv->GetResource(&res);
    D3D11_RESOURCE_DIMENSION dim;
    res->GetType(&dim);
    if (dim == D3D11_RESOURCE_DIMENSION_TEXTURE2D)
    {
        D3D11_TEXTURE2D_DESC d;
        static_cast<ID3D11Texture2D*>(res)->GetDesc(&d);
        sprintf_s(out, n, "%p %ux%u fmt%u%s", (void*)res, d.Width, d.Height, d.Format, res == g_backbuffer ? " BACKBUFFER" : "");
    }
    else
        sprintf_s(out, n, "%p dim%d", (void*)res, int(dim));
    res->Release();
}

typedef void(STDMETHODCALLTYPE* OMSetRTFn)(ID3D11DeviceContext*, UINT, ID3D11RenderTargetView* const*, ID3D11DepthStencilView*);
typedef void(STDMETHODCALLTYPE* DrawIndexedFn)(ID3D11DeviceContext*, UINT, UINT, INT);
typedef void(STDMETHODCALLTYPE* DrawFn)(ID3D11DeviceContext*, UINT, UINT);
typedef void(STDMETHODCALLTYPE* DrawIndexedInstancedFn)(ID3D11DeviceContext*, UINT, UINT, UINT, INT, UINT);
typedef void(STDMETHODCALLTYPE* DrawInstancedFn)(ID3D11DeviceContext*, UINT, UINT, UINT, UINT);
typedef void(STDMETHODCALLTYPE* ClearRTFn)(ID3D11DeviceContext*, ID3D11RenderTargetView*, const FLOAT[4]);
typedef void(STDMETHODCALLTYPE* CopyResourceFn)(ID3D11DeviceContext*, ID3D11Resource*, ID3D11Resource*);
typedef void(STDMETHODCALLTYPE* ExecuteFn)(ID3D11DeviceContext*, ID3D11CommandList*, BOOL);
typedef void(STDMETHODCALLTYPE* ClearDsvFn)(ID3D11DeviceContext*, ID3D11DepthStencilView*, UINT, FLOAT, UINT8);
static OMSetRTFn o_omset;
static DrawIndexedFn o_drawIndexed;
static DrawFn o_draw;
static DrawIndexedInstancedFn o_drawIndexedInstanced;
static DrawInstancedFn o_drawInstanced;
static ClearRTFn o_clear;
static CopyResourceFn o_copy;
static ExecuteFn o_execute;
static ClearDsvFn o_clearDsv;
static int g_lists;

static void STDMETHODCALLTYPE OMSet(ID3D11DeviceContext* c, UINT n, ID3D11RenderTargetView* const* rtvs, ID3D11DepthStencilView* dsv)
{
    if (g_active)
    {
        Flush();
        char d[160];
        Describe(n && rtvs ? rtvs[0] : nullptr, d, sizeof d);
        char line[256];
        sprintf_s(line, "RT[%u] %s%s\n", n, d, dsv ? " +depth" : "");
        g_buf += line;
    }
    o_omset(c, n, rtvs, dsv);
}
static void STDMETHODCALLTYPE DrawIndexed(ID3D11DeviceContext* c, UINT a, UINT b, INT d) { if (g_active) ++g_draws; o_drawIndexed(c, a, b, d); }
static void STDMETHODCALLTYPE Draw(ID3D11DeviceContext* c, UINT a, UINT b) { if (g_active) ++g_draws; o_draw(c, a, b); }
static void STDMETHODCALLTYPE DrawIndexedInstanced(ID3D11DeviceContext* c, UINT a, UINT b, UINT d, INT e, UINT f) { if (g_active) ++g_draws; o_drawIndexedInstanced(c, a, b, d, e, f); }
static void STDMETHODCALLTYPE DrawInstanced(ID3D11DeviceContext* c, UINT a, UINT b, UINT d, UINT e) { if (g_active) ++g_draws; o_drawInstanced(c, a, b, d, e); }
static void STDMETHODCALLTYPE Clear(ID3D11DeviceContext* c, ID3D11RenderTargetView* rtv, const FLOAT col[4])
{
    if (g_active)
    {
        Flush();
        char d[160];
        Describe(rtv, d, sizeof d);
        g_buf += "  clear " + std::string(d) + "\n";
    }
    o_clear(c, rtv, col);
}
static void STDMETHODCALLTYPE Copy(ID3D11DeviceContext* c, ID3D11Resource* dst, ID3D11Resource* src)
{
    if (g_active)
    {
        Flush();
        char line[128];
        sprintf_s(line, "  copy %p -> %p%s\n", (void*)src, (void*)dst, dst == g_backbuffer ? " (BACKBUFFER)" : "");
        g_buf += line;
    }
    o_copy(c, dst, src);
}

static void STDMETHODCALLTYPE Execute(ID3D11DeviceContext* c, ID3D11CommandList* list, BOOL restore)
{
    if (g_active)
    {
        Flush();
        char line[96];
        sprintf_s(line, "  execute command list %p (#%d)\n", (void*)list, ++g_lists);
        g_buf += line;
    }
    o_execute(c, list, restore);
}
static void STDMETHODCALLTYPE ClearDsv(ID3D11DeviceContext* c, ID3D11DepthStencilView* dsv, UINT flags, FLOAT d, UINT8 st)
{
    if (g_active) { Flush(); g_buf += "  clear depth\n"; }
    o_clearDsv(c, dsv, flags, d, st);
}

static void Install(IDXGISwapChain* chain);
}  // namespace trace

typedef HRESULT(STDMETHODCALLTYPE* PresentFn)(IDXGISwapChain*, UINT, UINT);
static PresentFn g_present;

static HRESULT STDMETHODCALLTYPE HookedPresent(IDXGISwapChain* self, UINT sync, UINT flags)
{
    const LONG n = InterlockedIncrement(&g_frames);
    {
        // End a recorded frame; start one if requested.
        char req[MAX_PATH], out[MAX_PATH];
        GetTempPathA(MAX_PATH, req);
        strcpy_s(out, req);
        strcat_s(req, "bioshock-trace-request");
        strcat_s(out, "bioshock-frame-trace.txt");
        if (trace::g_active)
        {
            trace::Flush();
            trace::g_active = 0;
            FILE* f = nullptr;
            fopen_s(&f, out, "w");
            if (f) { fprintf(f, "frame %ld\n%s", n, trace::g_buf.c_str()); fclose(f); }
            Log("frame trace written (%u bytes)", unsigned(trace::g_buf.size()));
            trace::g_buf.clear();
        }
        else if ((n & 31) == 0 && GetFileAttributesA(req) != INVALID_FILE_ATTRIBUTES)
        {
            DeleteFileA(req);
            trace::Install(self);
            ID3D11Texture2D* bb = nullptr;
            if (SUCCEEDED(self->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&bb))) && bb)
            {
                trace::g_backbuffer = bb;
                bb->Release();  // keep the pointer for identity only
            }
            trace::g_buf.clear();
            trace::g_lists = 0;
            trace::g_active = 1;
        }
    }
    if (n <= 3 || n % 3600 == 0) Log("frame %ld (present thread %lu, main thread %lu)", n, GetCurrentThreadId(), g_mainThread);
    snap::Take(n);
    return g_present(self, sync, flags);
}

void trace::Install(IDXGISwapChain* chain)
{
    static bool done;
    if (done) return;
    ID3D11Device* dev = nullptr;
    if (FAILED(chain->GetDevice(__uuidof(ID3D11Device), reinterpret_cast<void**>(&dev))) || !dev) return;
    ID3D11DeviceContext* ctx = nullptr;
    dev->GetImmediateContext(&ctx);
    dev->Release();
    if (!ctx) return;
    // ID3D11DeviceContext vtable slots.
    o_drawIndexed = reinterpret_cast<DrawIndexedFn>(HookSlot(ctx, 12, reinterpret_cast<void*>(&DrawIndexed)));
    o_draw = reinterpret_cast<DrawFn>(HookSlot(ctx, 13, reinterpret_cast<void*>(&Draw)));
    o_drawIndexedInstanced = reinterpret_cast<DrawIndexedInstancedFn>(HookSlot(ctx, 20, reinterpret_cast<void*>(&DrawIndexedInstanced)));
    o_drawInstanced = reinterpret_cast<DrawInstancedFn>(HookSlot(ctx, 21, reinterpret_cast<void*>(&DrawInstanced)));
    o_omset = reinterpret_cast<OMSetRTFn>(HookSlot(ctx, 33, reinterpret_cast<void*>(&OMSet)));
    o_copy = reinterpret_cast<CopyResourceFn>(HookSlot(ctx, 47, reinterpret_cast<void*>(&Copy)));
    o_clear = reinterpret_cast<ClearRTFn>(HookSlot(ctx, 50, reinterpret_cast<void*>(&Clear)));
    o_clearDsv = reinterpret_cast<ClearDsvFn>(HookSlot(ctx, 53, reinterpret_cast<void*>(&ClearDsv)));
    o_execute = reinterpret_cast<ExecuteFn>(HookSlot(ctx, 58, reinterpret_cast<void*>(&Execute)));
    Log("context type %d (0 immediate)", int(ctx->GetType()));
    ctx->Release();
    done = o_draw && o_omset;
    Log("device context hooked for frame traces (%s)", done ? "ok" : "FAILED");
}

static void HookSwapChain(IDXGISwapChain* chain)
{
    if (!chain) return;
    if (void* original = HookSlot(chain, 8, reinterpret_cast<void*>(&HookedPresent)))  // IDXGISwapChain::Present
    {
        g_present = reinterpret_cast<PresentFn>(original);
        DXGI_SWAP_CHAIN_DESC desc = {};
        chain->GetDesc(&desc);
        Log("swap chain %ux%u hooked", desc.BufferDesc.Width, desc.BufferDesc.Height);
    }
}

typedef HRESULT(STDMETHODCALLTYPE* CreateSwapChainFn)(IDXGIFactory*, IUnknown*, DXGI_SWAP_CHAIN_DESC*, IDXGISwapChain**);
static CreateSwapChainFn g_createSwapChain;

static HRESULT STDMETHODCALLTYPE HookedCreateSwapChain(IDXGIFactory* self, IUnknown* device, DXGI_SWAP_CHAIN_DESC* desc, IDXGISwapChain** out)
{
    const HRESULT hr = g_createSwapChain(self, device, desc, out);
    if (SUCCEEDED(hr) && out) HookSwapChain(*out);
    return hr;
}

typedef HRESULT(STDMETHODCALLTYPE* CreateSwapChainForHwndFn)(IDXGIFactory2*, IUnknown*, HWND, const DXGI_SWAP_CHAIN_DESC1*,
    const DXGI_SWAP_CHAIN_FULLSCREEN_DESC*, IDXGIOutput*, IDXGISwapChain1**);
static CreateSwapChainForHwndFn g_createForHwnd;

static HRESULT STDMETHODCALLTYPE HookedCreateForHwnd(IDXGIFactory2* self, IUnknown* device, HWND hwnd, const DXGI_SWAP_CHAIN_DESC1* desc,
    const DXGI_SWAP_CHAIN_FULLSCREEN_DESC* fs, IDXGIOutput* output, IDXGISwapChain1** out)
{
    const HRESULT hr = g_createForHwnd(self, device, hwnd, desc, fs, output, out);
    if (SUCCEEDED(hr) && out) HookSwapChain(*out);
    return hr;
}

static void HookFactory(void* factory)
{
    if (!factory) return;
    if (void* o = HookSlot(factory, 10, reinterpret_cast<void*>(&HookedCreateSwapChain)))  // IDXGIFactory::CreateSwapChain
        g_createSwapChain = reinterpret_cast<CreateSwapChainFn>(o);
    IDXGIFactory2* f2 = nullptr;
    if (SUCCEEDED(static_cast<IUnknown*>(factory)->QueryInterface(__uuidof(IDXGIFactory2), reinterpret_cast<void**>(&f2))) && f2)
    {
        if (void* o = HookSlot(f2, 15, reinterpret_cast<void*>(&HookedCreateForHwnd)))  // IDXGIFactory2::CreateSwapChainForHwnd
            g_createForHwnd = reinterpret_cast<CreateSwapChainForHwndFn>(o);
        f2->Release();
    }
}

extern "C" HRESULT WINAPI Proxy_CreateDXGIFactory(REFIID riid, void** out)
{
    typedef HRESULT(WINAPI * Fn)(REFIID, void**);
    const HRESULT hr = reinterpret_cast<Fn>(Real("CreateDXGIFactory"))(riid, out);
    Log("CreateDXGIFactory -> 0x%08lx", hr);
    if (SUCCEEDED(hr)) HookFactory(*out);
    return hr;
}

extern "C" HRESULT WINAPI Proxy_CreateDXGIFactory1(REFIID riid, void** out)
{
    typedef HRESULT(WINAPI * Fn)(REFIID, void**);
    const HRESULT hr = reinterpret_cast<Fn>(Real("CreateDXGIFactory1"))(riid, out);
    Log("CreateDXGIFactory1 -> 0x%08lx", hr);
    if (SUCCEEDED(hr)) HookFactory(*out);
    return hr;
}

extern "C" HRESULT WINAPI Proxy_CreateDXGIFactory2(UINT flags, REFIID riid, void** out)
{
    typedef HRESULT(WINAPI * Fn)(UINT, REFIID, void**);
    const HRESULT hr = reinterpret_cast<Fn>(Real("CreateDXGIFactory2"))(flags, riid, out);
    Log("CreateDXGIFactory2 -> 0x%08lx", hr);
    if (SUCCEEDED(hr)) HookFactory(*out);
    return hr;
}

// Everything else is a straight jump into the real dxgi.dll (x86 naked stubs keep the caller's
// stack and arguments untouched).
#define FORWARD(name)                                                       \
    static void* p_##name;                                                  \
    extern "C" __declspec(naked) void Proxy_##name()                        \
    {                                                                       \
        __asm { mov eax, p_##name }                                         \
        __asm { test eax, eax }                                             \
        __asm { jnz go }                                                    \
        __asm { push offset s_##name }                                      \
        __asm { call Real }                                                 \
        __asm { add esp, 4 }                                                \
        __asm { mov p_##name, eax }                                         \
        __asm { go: jmp eax }                                               \
    }

#define NAME(name) static const char s_##name[] = #name;
NAME(ApplyCompatResolutionQuirking) NAME(CompatString) NAME(CompatValue) NAME(DXGID3D10CreateDevice)
NAME(DXGID3D10CreateLayeredDevice) NAME(DXGID3D10GetLayeredDeviceSize) NAME(DXGID3D10RegisterLayers)
NAME(DXGIDeclareAdapterRemovalSupport) NAME(DXGIDisableVBlankVirtualization) NAME(DXGIDumpJournal)
NAME(DXGIGetDebugInterface1) NAME(DXGIReportAdapterConfiguration) NAME(PIXBeginCapture) NAME(PIXEndCapture)
NAME(PIXGetCaptureState) NAME(SetAppCompatStringPointer) NAME(UpdateHMDEmulationStatus)

FORWARD(ApplyCompatResolutionQuirking) FORWARD(CompatString) FORWARD(CompatValue) FORWARD(DXGID3D10CreateDevice)
FORWARD(DXGID3D10CreateLayeredDevice) FORWARD(DXGID3D10GetLayeredDeviceSize) FORWARD(DXGID3D10RegisterLayers)
FORWARD(DXGIDeclareAdapterRemovalSupport) FORWARD(DXGIDisableVBlankVirtualization) FORWARD(DXGIDumpJournal)
FORWARD(DXGIGetDebugInterface1) FORWARD(DXGIReportAdapterConfiguration) FORWARD(PIXBeginCapture) FORWARD(PIXEndCapture)
FORWARD(PIXGetCaptureState) FORWARD(SetAppCompatStringPointer) FORWARD(UpdateHMDEmulationStatus)

BOOL WINAPI DllMain(HINSTANCE, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        g_mainThread = GetCurrentThreadId();
        QueryPerformanceFrequency(&g_freq);
        QueryPerformanceCounter(&g_start);
        char path[MAX_PATH];
        GetTempPathA(MAX_PATH, path);
        strcat_s(path, "bioshock-e1.log");
        g_log = _fsopen(path, "w", _SH_DENYNO);  // readable while the game runs
        char exe[MAX_PATH];
        GetModuleFileNameA(nullptr, exe, MAX_PATH);
        Log("dxgi proxy loaded into %s (pid %lu)", exe, GetCurrentProcessId());
    }
    else if (reason == DLL_PROCESS_DETACH && g_log)
    {
        Log("unloading after %ld frames", g_frames);
        fclose(g_log);
    }
    return TRUE;
}
