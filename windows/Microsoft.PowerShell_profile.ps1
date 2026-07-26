# Ported from the fish Agnoster theme in this repo (config/fish/functions/fish_prompt.fish).
# Segment colors use named ANSI 8-colors, not truecolor, so they follow whatever
# terminal color scheme is active (see windows/material-design.windowsterminal.json)
# the same way the fish version follows the active iTerm color preset.

$env:VIRTUAL_ENV_DISABLE_PROMPT = "1"

$script:SepGlyph = [char]0xE0B0
$script:BranchGlyph = [char]0xE0A0
$script:AnsiColor = @{
    black = 0; red = 1; green = 2; yellow = 3
    blue = 4; magenta = 5; cyan = 6; white = 7
}

function Get-FishStylePath {
    param([string]$Path)

    if ($Path -eq $HOME) { return "~" }

    if ($Path.StartsWith($HOME + "\")) {
        $prefix = "~"
        $rest = $Path.Substring($HOME.Length)
    } else {
        $qualifier = Split-Path $Path -Qualifier
        $prefix = $qualifier
        $rest = $Path.Substring($qualifier.Length)
    }

    $parts = $rest.Trim('\') -split '\\' | Where-Object { $_ -ne '' }
    if ($parts.Count -eq 0) { return $prefix }

    $abbreviated = @()
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        $abbreviated += $parts[$i].Substring(0, 1)
    }
    $abbreviated += $parts[-1]

    return "$prefix/$($abbreviated -join '/')"
}

function prompt {
    $lastSuccess = $?
    $e = [char]27
    $reset = "$e[0m"

    $segments = @()

    if (-not $lastSuccess) {
        $segments += @{ bg = 'red'; fg = 'black'; text = [char]0x2718 }
    }
    if ($env:VIRTUAL_ENV) {
        $segments += @{ bg = 'white'; fg = 'black'; text = (Split-Path $env:VIRTUAL_ENV -Leaf) }
    }
    $segments += @{ bg = 'blue'; fg = 'black'; text = (Get-FishStylePath $PWD.Path) }

    $status = git status --porcelain --branch 2>$null
    if ($LASTEXITCODE -eq 0 -and $status) {
        $branchLine = $status[0] -replace '^## ', ''
        $branch = ($branchLine -split '\.\.\.')[0] -replace ' \[.*\]', ''
        if ($branch -match '^HEAD ') { $branch = "detached" }
        $dirty = if ($status.Count -gt 1) { [char]0xB1 } else { "" }
        $gitBg = if ($status.Count -gt 1) { 'yellow' } else { 'green' }
        $gitText = "$BranchGlyph $branch $dirty".TrimEnd()
        $segments += @{ bg = $gitBg; fg = 'black'; text = $gitText }
    }

    $line = ""
    $prevBg = $null
    foreach ($seg in $segments) {
        $bgCode = 40 + $AnsiColor[$seg.bg]
        $fgCode = 30 + $AnsiColor[$seg.fg]
        if ($null -ne $prevBg) {
            $prevFgCode = 30 + $AnsiColor[$prevBg]
            $line += "$e[${prevFgCode}m$e[${bgCode}m$SepGlyph "
        } else {
            $line += "$e[${bgCode}m "
        }
        $line += "$e[${fgCode}m$($seg.text) "
        $prevBg = $seg.bg
    }

    if ($null -ne $prevBg) {
        $prevFgCode = 30 + $AnsiColor[$prevBg]
        $line += "$reset$e[${prevFgCode}m$SepGlyph $reset"
    }

    return $line
}

# Unix-like aliases (cat/ls/rm/cp/mv/pwd/clear/man already exist as built-in PowerShell aliases)
function ll { Get-ChildItem -Force @args | Sort-Object LastWriteTime -Descending | Format-Table Mode, LastWriteTime, @{N = 'Size'; E = { $_.Length } }, Name -AutoSize }
function la { Get-ChildItem -Force @args }
function l { Get-ChildItem @args }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function grep {
    param([Parameter(Position = 0)]$Pattern, [Parameter(ValueFromPipeline = $true)]$InputObject)
    process {
        if ($null -ne $InputObject) { $InputObject | Select-String $Pattern }
        else { Get-ChildItem -Recurse -File | Select-String $Pattern }
    }
}
function which ($cmd) { (Get-Command $cmd -ErrorAction SilentlyContinue).Source }
function touch ($file) {
    if (Test-Path $file) { (Get-Item $file).LastWriteTime = Get-Date }
    else { New-Item -ItemType File -Path $file | Out-Null }
}
function open ($path = '.') { Invoke-Item $path }
function df {
    Get-PSDrive -PSProvider FileSystem | Select-Object Name,
        @{N = 'Used(GB)'; E = { [math]::Round($_.Used / 1GB, 2) } },
        @{N = 'Free(GB)'; E = { [math]::Round($_.Free / 1GB, 2) } }
}
