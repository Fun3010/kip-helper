param(
    [Parameter(Mandatory = $true)][string]$FlutterSdk,
    [Parameter(Mandatory = $true)][string]$AndroidSdk,
    [Parameter(Mandatory = $true)][string]$Jdk
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$flutterCommand = Join-Path $FlutterSdk 'bin/flutter.bat'
if (!(Test-Path -LiteralPath $flutterCommand)) { throw 'Flutter SDK not found.' }
if (!(Test-Path -LiteralPath (Join-Path $Jdk 'bin/java.exe'))) { throw 'JDK not found.' }
if (!(Test-Path -LiteralPath $AndroidSdk)) { throw 'Android SDK not found.' }

$previousJava = $env:JAVA_HOME
$previousAndroid = $env:ANDROID_HOME
Push-Location $projectRoot
try {
    $env:JAVA_HOME = $Jdk
    $env:ANDROID_HOME = $AndroidSdk
    & $flutterCommand pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    & $flutterCommand analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
    & $flutterCommand test --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
    & $flutterCommand build apk --release --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
    Get-Item 'build/app/outputs/flutter-apk/app-release.apk'
} finally {
    $env:JAVA_HOME = $previousJava
    $env:ANDROID_HOME = $previousAndroid
    Pop-Location
}
