$ErrorActionPreference = "Stop"
$repository = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $repository "bin"
$control = Join-Path $PSScriptRoot "arena_control.ps1"
. (Join-Path $PSScriptRoot "identity.ps1")
$game = Join-Path $bin $GameExe
$server = Join-Path $bin $GameServerExe
$captures = Join-Path $bin "captures"

# Retry localhost is centered at (window.x/2, window.y/2 + 72) in Frame_Info (top-left, Y down).
$RetryLocalhostX = 683
$RetryLocalhostY = 456

function Invoke-Control {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $Command,
        [string] $Body
    )
    if ($Body) {
        $response = & $control -Body $Body
    }
    else {
        $response = & $control @Command
    }
    if ($LASTEXITCODE -ne 0) {
        $what = if ($Body) { $Body } else { $Command -join " " }
        throw "control failed: $what`n$response"
    }
    return $response
}

if (-not (Test-Path -LiteralPath $game)) {
    throw "Missing $game. Build with: jai Build.jai - game    and    jai Build.jai - win32"
}
if (-not (Test-Path -LiteralPath $server)) {
    throw "Missing $server. Build with: jai Build.jai - win32"
}

Get-Process $GameName, $GameServerName -ErrorAction SilentlyContinue | ForEach-Object {
    throw "A game or server process is already running ($($_.Name)). Close it first."
}

New-Item -ItemType Directory -Force -Path $captures | Out-Null

$proc = Start-Process -FilePath $game -WorkingDirectory $bin -PassThru
try {
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    $connected = $false
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            Invoke-Control status | Out-Null
            $connected = $true
            break
        }
        catch {
            if ($proc.HasExited) {
                throw "$GameExe exited before the control pipe came up."
            }
            Start-Sleep -Milliseconds 200
        }
    }
    if (-not $connected) {
        throw "Timed out waiting for $GameControlPipe."
    }

    $before = Invoke-Control -Body @"
pause
capture once
"@
    if ($before -notmatch "ok capture path=captures/frame_(\d+)\.png") {
        throw "before capture failed:`n$before"
    }
    $beforeSerial = $Matches[1]

    $spawn = Invoke-Control -Body @"
key F9 down
wait 1
key F9 up
wait 180
"@
    if ($spawn -notmatch "ok") {
        throw "F9 spawn failed:`n$spawn"
    }
    $serverProc = Get-Process $GameServerName -ErrorAction SilentlyContinue
    if (-not $serverProc) {
        throw "F9 did not start $GameServerExe. Control said:`n$spawn"
    }

    $click = Invoke-Control -Body @"
mouse $RetryLocalhostX $RetryLocalhostY
wait 2
mouse_button left down
wait 1
mouse_button left up
wait 30
capture once
resume
"@
    if ($click -notmatch "ok capture path=captures/frame_(\d+)\.png") {
        throw "after capture failed:`n$click"
    }
    $afterSerial = $Matches[1]

    $beforeSrc = Join-Path $captures ("frame_{0}.png" -f $beforeSerial)
    $afterSrc = Join-Path $captures ("frame_{0}.png" -f $afterSerial)
    $beforeDst = Join-Path $captures "retry_localhost_before.png"
    $afterDst = Join-Path $captures "retry_localhost_after.png"
    Copy-Item -LiteralPath $beforeSrc -Destination $beforeDst -Force
    Copy-Item -LiteralPath $afterSrc -Destination $afterDst -Force

    Write-Output $before.TrimEnd()
    Write-Output $spawn.TrimEnd()
    Write-Output $click.TrimEnd()
    Write-Output "before: $beforeDst"
    Write-Output "after:  $afterDst"
}
finally {
    if ($proc -and -not $proc.HasExited) {
        try {
            Invoke-Control -Body @"
key F9 down
wait 1
key F9 up
wait 1
quit
"@ | Out-Null
            if (-not $proc.WaitForExit(5000)) {
                Stop-Process -Id $proc.Id -Force
            }
        }
        catch {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
    Get-Process $GameServerName -ErrorAction SilentlyContinue | Stop-Process -Force
}
