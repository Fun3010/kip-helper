param(
    [Parameter(Mandatory = $true)][string]$BuildDirectory,
    [Parameter(Mandatory = $true)][string]$CrtDirectory,
    [Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-f0-9]{7,40}$')][string]$Revision
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$release = (Resolve-Path -LiteralPath $BuildDirectory).Path
$crt = (Resolve-Path -LiteralPath $CrtDirectory).Path
foreach ($required in @('kip_helper.exe', 'flutter_windows.dll', 'data')) {
    if (!(Test-Path -LiteralPath (Join-Path $release $required))) { throw "Missing build component: $required" }
}
foreach ($required in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
    if (!(Test-Path -LiteralPath (Join-Path $crt $required))) { throw "Missing CRT component: $required" }
}
$name = "kip-helper-$Version-windows-x64-$($Revision.Substring(0, 7))"
$dist = Join-Path $projectRoot 'dist'
[System.IO.Directory]::CreateDirectory($dist) | Out-Null
$package = Join-Path $dist $name
$zip = "$package.zip"
if ((Test-Path -LiteralPath $package) -or (Test-Path -LiteralPath $zip)) {
    throw 'An immutable package with this version/revision already exists. Use its existing files or a new revision.'
}
[System.IO.Directory]::CreateDirectory($package) | Out-Null
Get-ChildItem -LiteralPath $release -Force | Where-Object { $_.Extension -ne '.pdb' } |
    Copy-Item -Destination $package -Recurse
Get-ChildItem -LiteralPath $crt -File -Filter '*.dll' | Copy-Item -Destination $package
Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination (Join-Path $package 'LICENSE.txt')
@"
КИП Помощник $Version — Windows x64
Исходный код: https://github.com/Fun3010/kip-helper
Ревизия: $Revision

Распакуйте ВСЮ папку из ZIP и откройте kip_helper.exe. Установка и права
администратора не требуются. Не переносите EXE отдельно от data и DLL.
Для Windows 10/11 x64. Системы ARM64 и 32-bit не проверялись.

Каталог, схемы, расчёты, заметки и добавленные PDF работают без сети.
Личные записи и копии PDF хранятся в данных пользователя Windows, а не
в папке программы. Веб-источники открываются внешним браузером.

Комплект содержит необходимые Flutter/PDFium/плагин DLL и Visual C++ Runtime
из установленного каталога Visual Studio Redist. При обновлении программы
обновляйте всю папку. Для поддержки системного Microsoft Runtime:
https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist

Сборка и поставка не означают проверку реального промышленного оборудования.
Применяйте только сведения для указанного в карточке исполнения.
"@ | Set-Content -LiteralPath (Join-Path $package 'ПРОЧИТАЙТЕ.txt') -Encoding utf8
$manifest = Get-ChildItem -LiteralPath $package -File -Recurse | ForEach-Object {
    [pscustomobject]@{
        path = $_.FullName.Substring($package.Length + 1).Replace('\', '/')
        bytes = $_.Length
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}
$manifest | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $package 'SHA256.json') -Encoding utf8
Compress-Archive -LiteralPath $package -DestinationPath $zip -CompressionLevel Optimal
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $name.zip" | Set-Content -LiteralPath "$zip.sha256" -Encoding ascii
[pscustomobject]@{ Package = $zip; Bytes = (Get-Item -LiteralPath $zip).Length; SHA256 = $hash }
