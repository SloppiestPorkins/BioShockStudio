# BioShock asks "failed to properly shutdown... revert the in-game Options to default settings?"
# after it was killed. Answer No (keep the player's settings). Prints what it did.
Add-Type -AssemblyName UIAutomationClient
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class DC {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, IntPtr e);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
}
"@
[DC]::SetProcessDPIAware() | Out-Null
$p = Get-Process BioshockHD -ErrorAction SilentlyContinue
if (-not $p -or $p.MainWindowTitle -ne 'Message') { 'no prompt'; exit 0 }
$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, 'No')
$no = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
if (-not $no) { 'prompt without a No button'; exit 1 }
$r = $no.Current.BoundingRectangle
[DC]::keybd_event(0x12, 0, 0, [IntPtr]::Zero); [DC]::keybd_event(0x12, 0, 2, [IntPtr]::Zero)
[DC]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 200
[DC]::SetCursorPos([int]($r.X + $r.Width / 2), [int]($r.Y + $r.Height / 2)) | Out-Null
Start-Sleep -Milliseconds 100
[DC]::mouse_event(2, 0, 0, 0, [IntPtr]::Zero); Start-Sleep -Milliseconds 60; [DC]::mouse_event(4, 0, 0, 0, [IntPtr]::Zero)
'answered No to the shutdown prompt'
