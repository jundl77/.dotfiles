# Installs the Meslo Nerd Font (glyphs for the Agnoster prompt) and registers the
# Material Design color scheme (ported from ../iterm-themes/material-design.itermcolors)
# as the default for all Windows Terminal profiles. Safe to re-run.

$ErrorActionPreference = "Stop"

# oh-my-posh isn't used for the prompt itself (see Microsoft.PowerShell_profile.ps1),
# but its font installer is the simplest way to fetch and register a patched Nerd Font.
# Skip when the font is already installed: the font installer's TUI never exits in a
# non-interactive shell, which hangs unattended re-runs.
$fontInstalled = Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\MesloLGMNerdFontMono-Regular.ttf"
if (-not $fontInstalled) {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
    }
    oh-my-posh font install meslo
}

$settingsPath = Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json" -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

if (-not $settingsPath) {
    Write-Warning "Windows Terminal settings.json not found - is Windows Terminal installed?"
    return
}

$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

if (-not $settings.schemes) {
    $settings | Add-Member -MemberType NoteProperty -Name schemes -Value @() -Force
}
if (-not ($settings.schemes | Where-Object { $_.name -eq "Material Design" })) {
    $scheme = Get-Content "$PSScriptRoot\material-design.windowsterminal.json" -Raw | ConvertFrom-Json
    $settings.schemes = @($settings.schemes) + $scheme
}

if (-not $settings.profiles.defaults) {
    $settings.profiles | Add-Member -MemberType NoteProperty -Name defaults -Value ([PSCustomObject]@{}) -Force
}
$settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name colorScheme -Value "Material Design" -Force
$settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name font -Value ([PSCustomObject]@{ face = "MesloLGM Nerd Font Mono" }) -Force

# Route Ctrl+Shift+F / Ctrl+Shift+N to nvim (the vimrc's CLion-style Telescope
# binds). Windows Terminal otherwise swallows them for its own find/new-window
# actions - and even unbound, it cannot transmit Ctrl+Shift distinctly from
# plain Ctrl. sendInput with the CSI-u extended-key encoding (ESC[<codepoint>;6u,
# 6 = shift+ctrl) fixes both: nvim parses CSI-u natively. Side effect: pressing
# these chords at a plain shell prompt inserts a few stray characters.
if (-not $settings.PSObject.Properties['keybindings']) {
    $settings | Add-Member -MemberType NoteProperty -Name keybindings -Value @() -Force
}
if (-not $settings.PSObject.Properties['actions']) {
    $settings | Add-Member -MemberType NoteProperty -Name actions -Value @() -Force
}
$esc = [char]27
$nvimChords = @(
    @{ id = "User.nvimFindInPath"; keys = "ctrl+shift+f"; input = "$esc[102;6u" },
    @{ id = "User.nvimGotoFile"; keys = "ctrl+shift+n"; input = "$esc[110;6u" }
)
foreach ($chord in $nvimChords) {
    $settings.actions = @(@($settings.actions) | Where-Object { $_.id -ne $chord.id })
    $settings.actions += [PSCustomObject]@{
        command = [PSCustomObject]@{ action = "sendInput"; input = $chord.input }
        id      = $chord.id
    }
    $settings.keybindings = @(@($settings.keybindings) | Where-Object { $_.keys -ne $chord.keys })
    $settings.keybindings += [PSCustomObject]@{ id = $chord.id; keys = $chord.keys }
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8
Write-Output "Windows Terminal font + Material Design color scheme installed."
