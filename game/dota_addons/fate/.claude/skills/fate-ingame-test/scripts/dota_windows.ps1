# Окна Dota Tools: список и перевод фокуса.
#   powershell -File dota_windows.ps1            -> список окон dota2/vconsole2
#   powershell -File dota_windows.ps1 -Focus game     -> окно игры («Dota 2»)
#   powershell -File dota_windows.ps1 -Focus console  -> VConsole2
#   powershell -File dota_windows.ps1 -Focus assets   -> Asset Browser
# Зачем: open_application("Dota 2") через Steam запускает ВТОРОЙ экземпляр
# («Only one instance...»), а окна игры часто свёрнуты — поднимаем уже открытые.
param([ValidateSet('', 'game', 'console', 'assets')][string]$Focus = '')

Add-Type @"
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
public class ZtWin {
  public delegate bool EP(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EP f, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
  [DllImport("user32.dll")] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  public static List<KeyValuePair<IntPtr,string>> L(uint pid) {
    var r = new List<KeyValuePair<IntPtr,string>>();
    EnumWindows((h, l) => { uint p; GetWindowThreadProcessId(h, out p);
      if (p == pid && IsWindowVisible(h)) { var s = new StringBuilder(256); GetWindowText(h, s, 256);
        if (s.Length > 0) r.Add(new KeyValuePair<IntPtr,string>(h, s.ToString())); }
      return true; }, IntPtr.Zero);
    return r;
  }
}
"@

$wins = @()
foreach ($p in Get-Process dota2, vconsole2 -ErrorAction SilentlyContinue) {
    foreach ($kv in [ZtWin]::L([uint32]$p.Id)) {
        $wins += [pscustomobject]@{ Proc = $p.Name; Pid = $p.Id; Handle = $kv.Key; Title = $kv.Value;
                                    Minimized = [ZtWin]::IsIconic($kv.Key) }
    }
}

if (-not $Focus) {
    if (-not $wins) { "Dota не запущена (нет окон dota2/vconsole2)"; exit 1 }
    $wins | Format-Table -AutoSize | Out-String -Width 200
    exit 0
}

$pattern = @{ game = '^Dota 2$'; console = '^VConsole2'; assets = '^Asset Browser' }[$Focus]
$w = $wins | Where-Object { $_.Title -match $pattern } | Select-Object -First 1
if (-not $w) {
    "Окно '$Focus' не найдено. Есть:"; $wins | Format-Table -AutoSize | Out-String -Width 200
    if ($Focus -eq 'console') { "VConsole открывается клавишей \ в окне игры." }
    exit 1
}
# Восстанавливаем ТОЛЬКО свёрнутое: ShowWindow(9) на развёрнутом окне VConsole
# превращает его в маленькое, и поле Command уезжает с привычного места.
if ($w.Minimized) { [ZtWin]::ShowWindow($w.Handle, 9) | Out-Null }
else { [ZtWin]::ShowWindow($w.Handle, 5) | Out-Null }   # SW_SHOW: размер не трогает
# Windows не даёт фоновому процессу забрать фокус; нажатие ALT снимает запрет.
for ($i = 0; $i -lt 3 -and [ZtWin]::GetForegroundWindow() -ne $w.Handle; $i++) {
    [ZtWin]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)
    [ZtWin]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
    [ZtWin]::BringWindowToTop($w.Handle) | Out-Null
    [ZtWin]::SetForegroundWindow($w.Handle) | Out-Null
    Start-Sleep -Milliseconds 150
}
if ([ZtWin]::GetForegroundWindow() -eq $w.Handle) { "focused: $($w.Title) ($($w.Proc) $($w.Pid))" }
else { "НЕ удалось перевести фокус на '$($w.Title)' — кликнуть по окну или открыть консоль клавишей \ в игре"; exit 2 }
