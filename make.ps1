param(
    [Parameter(Position=0)]
    [ValidateSet("get","clean","analyze","run-windows","build-windows","build-installer-windows","package-windows")]
    [string]$Command = "run-windows"
)

switch ($Command) {
    "get"                    { & fvm flutter pub get }
    "clean"                  { & fvm flutter clean }
    "analyze"                { & fvm flutter analyze }
    "run-windows"            { & fvm flutter run -d windows }
    "build-windows"          { & fvm flutter build windows --release }
    "build-installer-windows" { & powershell -ExecutionPolicy Bypass -File .\windows\installer\build_installer.ps1 }
    "package-windows"        { & powershell -ExecutionPolicy Bypass -File .\windows\installer\build_installer.ps1 }
}
