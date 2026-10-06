param([Parameter(Mandatory = $true)][string]$Out)
# Grab BioShock's client area (no title bar) with PrintWindow; the window need not be focused.
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class GG {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  public struct RECT { public int L, T, R, B; } public struct POINT { public int X, Y; }
}
"@
# Physical pixels: without this, 150% display scaling hands back a 2/3-size window and PrintWindow
# copies only the top-left of the real frame.
[GG]::SetProcessDPIAware() | Out-Null
$h = (Get-Process BioshockHD).MainWindowHandle
$wr = New-Object GG+RECT; [GG]::GetWindowRect($h, [ref]$wr) | Out-Null
$cr = New-Object GG+RECT; [GG]::GetClientRect($h, [ref]$cr) | Out-Null
$pt = New-Object GG+POINT; [GG]::ClientToScreen($h, [ref]$pt) | Out-Null
$bmp = New-Object System.Drawing.Bitmap ($wr.R - $wr.L), ($wr.B - $wr.T)
$g = [System.Drawing.Graphics]::FromImage($bmp); $dc = $g.GetHdc()
[GG]::PrintWindow($h, $dc, 2) | Out-Null; $g.ReleaseHdc($dc)
$rect = New-Object System.Drawing.Rectangle ($pt.X - $wr.L), ($pt.Y - $wr.T), $cr.R, $cr.B
$bmp.Clone($rect, $bmp.PixelFormat).Save($Out)
