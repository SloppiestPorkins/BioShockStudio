// Track E, step E1: a proxy dxgi.dll for BioshockHD.exe (32-bit, Direct3D 11).
//
// Placed next to BioshockHD.exe, the game loads it instead of the system dxgi.dll. Every export
// forwards to the real one in SysWOW64; CreateDXGIFactory/1/2 additionally hook the factory's
// CreateSwapChain so the swap chain's Present - called once per rendered frame - can be counted.
// E1 only proves the way in: it logs frames to %TEMP%\bioshock-e1.log and changes nothing.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <dxgi1_2.h>
#include <cstdio>

static HMODULE g_real;
static FILE* g_log;
static LARGE_INTEGER g_freq, g_start;
static LONG g_frames;

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

typedef HRESULT(STDMETHODCALLTYPE* PresentFn)(IDXGISwapChain*, UINT, UINT);
static PresentFn g_present;

static HRESULT STDMETHODCALLTYPE HookedPresent(IDXGISwapChain* self, UINT sync, UINT flags)
{
    const LONG n = InterlockedIncrement(&g_frames);
    if (n <= 300 || n % 600 == 0) Log("frame %ld", n);
    return g_present(self, sync, flags);
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
        QueryPerformanceFrequency(&g_freq);
        QueryPerformanceCounter(&g_start);
        char path[MAX_PATH];
        GetTempPathA(MAX_PATH, path);
        strcat_s(path, "bioshock-e1.log");
        fopen_s(&g_log, path, "w");
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
