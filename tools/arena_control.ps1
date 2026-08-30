[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Command,
    [Parameter(ValueFromPipeline = $true)]
    [string] $Body
)

begin {
    $piped = [System.Collections.Generic.List[string]]::new()
}
process {
    if ($null -ne $Body -and $Body.Length -gt 0) {
        $piped.Add($Body)
    }
}
end {
    . (Join-Path $PSScriptRoot "identity.ps1")
    $pipeName = $GameControlPipe
    $parts = [System.Collections.Generic.List[string]]::new()
    if ($piped.Count -gt 0) {
        foreach ($line in $piped) {
            $parts.Add($line)
        }
    }
    if ($Command -and $Command.Count -gt 0) {
        $parts.Add(($Command -join " ").Trim())
    }
    $text = $null
    if ($parts.Count -gt 0) {
        $text = ($parts -join "`n").TrimEnd()
    }
    elseif ([Console]::IsInputRedirected) {
        $text = [Console]::In.ReadToEnd().TrimEnd()
    }
    else {
        throw "Usage: arena_control.ps1 <command...>   or   arena_control.ps1 -Body <lines>"
    }
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "No control commands to send."
    }
    if (-not $text.EndsWith("`n")) {
        $text += "`n"
    }

    $pipe = [System.IO.Pipes.NamedPipeClientStream]::new(
        ".",
        $pipeName,
        [System.IO.Pipes.PipeDirection]::InOut
    )
    try {
        $deadline = [DateTime]::UtcNow.AddSeconds(5)
        while (-not $pipe.IsConnected -and [DateTime]::UtcNow -lt $deadline) {
            try {
                $pipe.Connect(250)
            }
            catch [TimeoutException] {
            }
            catch [System.IO.IOException] {
            }
        }
        if (-not $pipe.IsConnected) {
            throw "Could not connect to the $GameControlPipe pipe within five seconds."
        }
        $writer = [System.IO.StreamWriter]::new($pipe, [System.Text.UTF8Encoding]::new($false))
        $writer.AutoFlush = $true
        $writer.Write($text)
        $reader = [System.IO.StreamReader]::new($pipe, [System.Text.UTF8Encoding]::new($false))
        $response = $reader.ReadToEnd()
        if ($null -eq $response -or $response.Length -eq 0) {
            throw "$GameControlPipe closed without a response."
        }
        Write-Output $response.TrimEnd()
        if ($response.Contains("error ")) {
            exit 1
        }
        exit 0
    }
    finally {
        $pipe.Dispose()
    }
}
