# This script will most likely only work with PowerShell Core.

$LoveExe = (Get-Command love).Source
$LoveCExe = (Get-Command lovec).Source
$Ignored = Get-Content .buildignore

if (Test-Path build) { Remove-Item -Recurse build/ }

New-Item -ItemType Directory -Path build | Out-Null

Get-ChildItem -Path . -Exclude $Ignored | Compress-Archive -DestinationPath build/lightning.love
Get-Content $LoveExe, build/lightning.love -Read 512 -AsByteStream | Set-Content build/lightning.exe -AsByteStream
Get-Content $LoveCExe, build/lightning.love -Read 512 -AsByteStream | Set-Content build/lightningc.exe -AsByteStream