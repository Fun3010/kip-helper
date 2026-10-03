param(
    [Parameter(Mandatory = $true)][string]$Adb,
    [Parameter(Mandatory = $true)][string]$Device,
    [string]$Apk = (Join-Path $PSScriptRoot '../build/app/outputs/flutter-apk/app-release.apk')
)

$ErrorActionPreference = 'Stop'
if (!(Test-Path -LiteralPath $Adb)) { throw 'adb.exe not found.' }
if (!(Test-Path -LiteralPath $Apk)) { throw 'Build the APK first.' }
$applicationId = 'ru.kiphelper.app'

& $Adb -s $Device install -r $Apk
if ($LASTEXITCODE -ne 0) { throw 'APK installation failed. Existing app was not uninstalled.' }
& $Adb -s $Device shell am force-stop $applicationId
$launchOutput = & $Adb -s $Device shell am start -W -n "$applicationId/.MainActivity"
$launchOutput
if ($LASTEXITCODE -ne 0 -or ($launchOutput -join "`n") -notmatch 'Status: ok') {
    throw 'Android did not confirm a successful launch.'
}
Start-Sleep -Seconds 2
$applicationPid = & $Adb -s $Device shell pidof $applicationId
if (!$applicationPid) { throw 'App process disappeared after launch.' }
Write-Output "App is running on $Device, PID $applicationPid."
Write-Output 'This is a startup smoke check; follow docs/test-plan.md for interactive checks.'
