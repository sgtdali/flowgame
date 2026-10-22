param([switch]$Editor)
$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$enginePath = $env:GODOT_PATH
if (-not $enginePath) {
    $enginePath = Join-Path (Split-Path $projectRoot -Parent) 'Godot_v4.7.2-stable_win64.exe'
}
if (-not (Test-Path -LiteralPath $enginePath -PathType Leaf)) {
    throw 'Godot bulunamadi. GODOT_PATH ortam degiskenini Godot exe dosyasina ayarlayin.'
}
$launchArgs = @('--path', ('"{0}"' -f $projectRoot))
if ($Editor) { $launchArgs += '--editor' }
Start-Process -FilePath $enginePath -ArgumentList $launchArgs
