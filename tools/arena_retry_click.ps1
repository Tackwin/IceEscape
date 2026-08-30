$ErrorActionPreference = "Stop"
$repository = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $repository "bin"
$control = Join-Path $PSScriptRoot "arena_control.ps1"
. (Join-Path $PSScriptRoot "identity.ps1")
$captures = Join-Path $bin "captures"

# Retry is centered at (window.x/2, window.y/2 - 24) in Frame_Info (bottom-left).
# Protocol mouse is top-left, Y down: y = 768 - (768/2 - 24) = 408.
$RetryX = 683
$RetryY = 408

function Invoke-Control {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]] $Command)
    $response = & $control @Command
    if ($LASTEXITCODE -ne 0) {
        throw "control failed: $($Command -join ' ')`n$response"
    }
    return $response
}

try {
    Invoke-Control status | Out-Null
}
catch {
    throw "Could not reach $GameControlPipe. Run bin/$GameExe from bin/ first."
}

New-Item -ItemType Directory -Force -Path $captures | Out-Null

$body = @"
pause
capture once
mouse $RetryX $RetryY
wait 2
mouse_button left down
wait 1
mouse_button left up
wait 5
capture once
resume
"@

$response = & $control -Body $body
if ($LASTEXITCODE -ne 0) {
    throw "Retry click batch failed:`n$response"
}

$matchesFound = [regex]::Matches($response, "ok capture path=captures/frame_(\d+)\.png")
if ($matchesFound.Count -lt 2) {
    throw "Expected two captures, got:`n$response"
}

$beforeSrc = Join-Path $captures ("frame_{0}.png" -f $matchesFound[0].Groups[1].Value)
$afterSrc = Join-Path $captures ("frame_{0}.png" -f $matchesFound[1].Groups[1].Value)
$beforeDst = Join-Path $captures "retry_before.png"
$afterDst = Join-Path $captures "retry_after.png"
Copy-Item -LiteralPath $beforeSrc -Destination $beforeDst -Force
Copy-Item -LiteralPath $afterSrc -Destination $afterDst -Force

Write-Output $response.TrimEnd()
Write-Output "before: $beforeDst"
Write-Output "after:  $afterDst"
