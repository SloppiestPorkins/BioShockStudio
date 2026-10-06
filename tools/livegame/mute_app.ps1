param([string]$ProcessName = 'BioshockHD', [int]$Seconds = 1800)
# Keep every audio session belonging to $ProcessName muted (Windows per-app mute, Core Audio COM).
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
[Guid("BCDE0395-E52F-467C-8E3D-C4579291692E"), ComImport] class MMDeviceEnumerator {}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator { int EnumAudioEndpoints(int f, int s, out IntPtr c); int GetDefaultAudioEndpoint(int f, int r, out IMMDevice d); }
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice { int Activate(ref Guid iid, int ctx, IntPtr p, [MarshalAs(UnmanagedType.IUnknown)] out object o); }
[Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioSessionManager2 { int a(); int b(); int GetSessionEnumerator(out IAudioSessionEnumerator e); }
[Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioSessionEnumerator { int GetCount(out int n); int GetSession(int i, out IAudioSessionControl2 s); }
[Guid("bfb7ff88-7239-4fc9-8fa2-07c950be9c6d"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioSessionControl2 { int a(); int b(); int c(); int d(); int e(); int f(); int g(); int h(); int i(); int j(); int k(); int GetProcessId(out uint pid); }
[Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface ISimpleAudioVolume { int SetMasterVolume(float v, ref Guid g); int GetMasterVolume(out float v); int SetMute(bool m, ref Guid g); int GetMute(out bool m); }
public static class AppMute {
  public static int Mute(uint[] pids) {
    var en = (IMMDeviceEnumerator)(new MMDeviceEnumerator()); IMMDevice dev; en.GetDefaultAudioEndpoint(0, 1, out dev);
    Guid iid = typeof(IAudioSessionManager2).GUID; object o; dev.Activate(ref iid, 23, IntPtr.Zero, out o);
    var mgr = (IAudioSessionManager2)o; IAudioSessionEnumerator se; mgr.GetSessionEnumerator(out se);
    int n; se.GetCount(out n); int muted = 0; Guid g = Guid.Empty;
    for (int i = 0; i < n; i++) {
      IAudioSessionControl2 s; se.GetSession(i, out s); uint pid; s.GetProcessId(out pid);
      if (Array.IndexOf(pids, pid) < 0) continue;
      var v = (ISimpleAudioVolume)s; bool m; v.GetMute(out m); if (!m) v.SetMute(true, ref g); muted++;
    }
    return muted;
  }
}
"@
$deadline = (Get-Date).AddSeconds($Seconds); $last = -1
while ((Get-Date) -lt $deadline) {
  $pids = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
  if ($pids.Count) { $n = [AppMute]::Mute($pids); if ($n -ne $last) { Write-Output "muted sessions: $n"; $last = $n } }
  Start-Sleep -Milliseconds 250
}
