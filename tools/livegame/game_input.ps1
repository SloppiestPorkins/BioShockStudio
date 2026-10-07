param([string]$Key = 'W', [int]$HoldMs = 2000, [int]$MouseDX = 0, [int]$MouseDY = 0)
# Focus BioShock and hold one key (scan-code SendInput, which DirectInput games read).
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class GI {
  [StructLayout(LayoutKind.Sequential)] public struct KI { public ushort vk, scan; public uint flags, time; public IntPtr extra; }
  [StructLayout(LayoutKind.Sequential)] public struct MI { public int dx, dy; public uint data, flags, time; public IntPtr extra; }
  [StructLayout(LayoutKind.Explicit, Size = 40)] public struct INPUT { [FieldOffset(0)] public uint type; [FieldOffset(8)] public KI ki; [FieldOffset(8)] public MI mi; }
  public static void Move(int dx, int dy) { var i = new INPUT[1]; i[0].type = 0; i[0].mi.dx = dx; i[0].mi.dy = dy; i[0].mi.flags = 0x0001; SendInput(1, i, Marshal.SizeOf(typeof(INPUT))); }
  [DllImport("user32.dll")] public static extern uint SendInput(uint n, INPUT[] i, int size);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
  public static void Key(ushort scan, bool up, bool ext) {
    var i = new INPUT[1]; i[0].type = 1; i[0].ki.scan = scan; i[0].ki.flags = 0x0008u | (up ? 0x0002u : 0u) | (ext ? 0x0001u : 0u);
    SendInput(1, i, Marshal.SizeOf(typeof(INPUT)));
  }
}
"@
$scan = @{ W = 0x11; A = 0x1E; S = 0x1F; D = 0x20; E = 0x12; Space = 0x39; Esc = 0x01; Enter = 0x1C; Up = 0x48; Down = 0x50; Left = 0x4B; Right = 0x4D; M = 0x32; Tab = 0x0F; F = 0x21; R = 0x13; Q = 0x10 }[$Key]
$ext = @('Up', 'Down', 'Left', 'Right') -contains $Key
$h = (Get-Process BioshockHD).MainWindowHandle
[GI]::ShowWindow($h, 9) | Out-Null
# Windows only lets the process with the last input take the foreground; a synthetic Alt tap
# counts as input, so a background script can then focus the game (it pauses when unfocused).
for ($try = 0; $try -lt 3 -and [GI]::GetForegroundWindow() -ne $h; $try++) {
  [GI]::keybd_event(0x12, 0, 0, [IntPtr]::Zero); [GI]::keybd_event(0x12, 0, 2, [IntPtr]::Zero)
  [GI]::SetForegroundWindow($h) | Out-Null; Start-Sleep -Milliseconds 200
}
Start-Sleep -Milliseconds 700
"foreground=$([GI]::GetForegroundWindow() -eq $h)"
for ($k = 0; $k -lt 20; $k++) { if ($MouseDX -or $MouseDY) { [GI]::Move([int]($MouseDX / 20), [int]($MouseDY / 20)); Start-Sleep -Milliseconds 15 } }
if ($HoldMs -gt 0) { [GI]::Key($scan, $false, $ext); Start-Sleep -Milliseconds $HoldMs; [GI]::Key($scan, $true, $ext) }
