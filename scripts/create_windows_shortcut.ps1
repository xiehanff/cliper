param(
  [string]$TargetExe = '',
  [string]$ShortcutName = 'CLIPER',
  [string]$DesktopDir = [Environment]::GetFolderPath('Desktop')
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($TargetExe)) {
  $localExe = Join-Path $PSScriptRoot 'cliper.exe'
  if (Test-Path -LiteralPath $localExe) {
    $TargetExe = $localExe
  } else {
    $TargetExe = Join-Path $PSScriptRoot '..\build\windows\x64\runner\Release\cliper.exe'
  }
}

$resolvedTarget = [System.IO.Path]::GetFullPath($TargetExe)

if (-not (Test-Path -LiteralPath $resolvedTarget)) {
  throw "目标文件不存在: $resolvedTarget"
}

$shortcutPath = Join-Path $DesktopDir "$ShortcutName.lnk"
$workingDir = Split-Path -Parent $resolvedTarget
$localIconSource = Join-Path $PSScriptRoot 'app_icon.ico'
$repoIconSource = Join-Path $PSScriptRoot '..\windows\runner\resources\app_icon.ico'
$packagedIconPath = Join-Path $workingDir 'app_icon.ico'

$iconSource = if (Test-Path -LiteralPath $localIconSource) {
  $localIconSource
} elseif (Test-Path -LiteralPath $repoIconSource) {
  $repoIconSource
} else {
  $null
}

if ((-not (Test-Path -LiteralPath $packagedIconPath)) -and $iconSource) {
  Copy-Item -LiteralPath $iconSource -Destination $packagedIconPath
}

$iconPath = if (Test-Path -LiteralPath $packagedIconPath) {
  $packagedIconPath
} else {
  $resolvedTarget
}

$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $resolvedTarget
$shortcut.WorkingDirectory = $workingDir
$shortcut.IconLocation = "$iconPath,0"
$shortcut.WindowStyle = 1
$shortcut.Save()

$shortcutInfo = $wshShell.CreateShortcut($shortcutPath)

Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
  [System.Runtime.InteropServices.DllImport("shell32.dll")]
  public static extern void SHChangeNotify(int wEventId, uint uFlags, System.IntPtr dwItem1, System.IntPtr dwItem2);
'@
[Win32.NativeMethods]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)

[pscustomobject]@{
  ShortcutPath = $shortcutPath
  TargetPath = $shortcutInfo.TargetPath
  WorkingDirectory = $shortcutInfo.WorkingDirectory
  IconLocation = $shortcutInfo.IconLocation
  IconFileCopied = (Test-Path -LiteralPath $packagedIconPath)
}
