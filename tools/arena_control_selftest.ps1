$ErrorActionPreference = "Stop"
$repository = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $repository "bin"
$control = Join-Path $PSScriptRoot "arena_control.ps1"
. (Join-Path $PSScriptRoot "identity.ps1")
$game = Join-Path $bin $GameExe

function Invoke-Control {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]] $Command)
    $response = & $control @Command
    if ($LASTEXITCODE -ne 0) {
        throw "control failed: $($Command -join ' ')`n$response"
    }
    return $response
}

if (-not (Test-Path -LiteralPath $game)) {
    throw "Missing $game. Build with: jai Build.jai - game    and    jai Build.jai - win32"
}

Get-Process $GameName -ErrorAction SilentlyContinue | ForEach-Object {
    throw "A game process is already running ($($_.Name)). Close it first."
}

$captures = Join-Path $bin "captures"
New-Item -ItemType Directory -Force -Path $captures | Out-Null
Get-ChildItem -LiteralPath $captures -Filter "frame_*.png" -ErrorAction SilentlyContinue | Remove-Item -Force

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

    $pause = Invoke-Control pause
    if ($pause -notmatch "ok paused") {
        throw "pause failed: $pause"
    }
    $status = Invoke-Control status
    if ($status -notmatch "paused=true") {
        throw "status after pause: $status"
    }

    Invoke-Control wait 1 | Out-Null
    $capture = Invoke-Control capture once
    if ($capture -notmatch "ok capture path=captures/frame_(\d+)\.png") {
        throw "capture once failed: $capture"
    }
    $serial = $Matches[1]
    $png = Join-Path $captures "frame_$serial.png"
    if (-not (Test-Path -LiteralPath $png)) {
        throw "Capture file missing: $png"
    }
    $bytes = [System.IO.File]::ReadAllBytes($png)
    if ($bytes.Length -lt 8 -or $bytes[0] -ne 137 -or $bytes[1] -ne 80) {
        throw "Capture is not a PNG: $png"
    }

    $mouse = Invoke-Control mouse 100 50
    if ($mouse -notmatch "ok") {
        throw "mouse failed: $mouse"
    }
    $afterMouse = Invoke-Control status
    if ($afterMouse -notmatch "mouse=100 50") {
        throw "status mouse: $afterMouse"
    }

    Invoke-Control key w down | Out-Null
    Invoke-Control wait 1 | Out-Null
    Invoke-Control key w up | Out-Null

    Write-Output "arena control selftest passed ($png)"
}
finally {
    if (-not $proc.HasExited) {
        try {
            Invoke-Control quit | Out-Null
            if (-not $proc.WaitForExit(5000)) {
                Stop-Process -Id $proc.Id -Force
            }
        }
        catch {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}
