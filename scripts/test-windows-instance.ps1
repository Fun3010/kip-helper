param(
    [Parameter(Mandatory = $true)][string]$Executable,
    [Parameter(Mandatory = $true)][string]$Evidence
)
$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path -LiteralPath $Executable).Path
$first = $null
$second = $null
$restart = $null
function Wait-ForWindow($Process) {
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        $Process.Refresh()
        if ($Process.HasExited) { throw 'Primary process exited before showing its window' }
        if ($Process.MainWindowHandle -ne 0) { return }
        Start-Sleep -Milliseconds 250
    }
    throw 'Primary window did not appear'
}
try {
    $first = Start-Process -FilePath $exe -PassThru
    Wait-ForWindow $first
    $title = $first.MainWindowTitle
    if ($title -ne 'КИП Помощник') { throw 'Unexpected native window title' }
    $second = Start-Process -FilePath $exe -PassThru
    if (!$second.WaitForExit(15000)) { throw 'A second instance remained running' }
    if ($second.ExitCode -ne 0) { throw 'Second launch did not exit successfully' }
    $first.Refresh()
    if ($first.HasExited -or !$first.Responding) { throw 'Original instance stopped responding' }
    Stop-Process -Id $first.Id -Force
    $first.WaitForExit()
    $restart = Start-Process -FilePath $exe -PassThru
    Wait-ForWindow $restart
    [pscustomobject]@{
        singleInstance = $true
        secondExitCode = $second.ExitCode
        restartAfterTermination = $true
        title = $title
        primaryPid = $first.Id
        restartPid = $restart.Id
        limit = 'Process isolation check; does not test save-and-exit or physical keyboard'
    } | ConvertTo-Json | Set-Content -LiteralPath $Evidence -Encoding utf8
} finally {
    foreach ($owned in @($first, $second, $restart)) {
        if ($owned) {
            $owned.Refresh()
            if (!$owned.HasExited) { Stop-Process -Id $owned.Id -Force }
            $owned.Dispose()
        }
    }
}
