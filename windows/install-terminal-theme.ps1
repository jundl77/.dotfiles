# Installs the Meslo Nerd Font (glyphs for the Agnoster prompt) and registers the
# Material Design color scheme (ported from ../iterm-themes/material-design.itermcolors)
# as the default for all Windows Terminal profiles. Safe to re-run.

$ErrorActionPreference = "Stop"

# oh-my-posh isn't used for the prompt itself (see Microsoft.PowerShell_profile.ps1),
# but its font installer is the simplest way to fetch and register a patched Nerd Font.
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements
}
oh-my-posh font install meslo

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

# Free Ctrl+Shift+F / Ctrl+Shift+N so they reach nvim (the vimrc's CLion-style
# Telescope binds); Windows Terminal otherwise swallows them for its own
# find / new-window actions. id = $null is WT's canonical "unbound" form.
if (-not $settings.PSObject.Properties['keybindings']) {
    $settings | Add-Member -MemberType NoteProperty -Name keybindings -Value @() -Force
}
foreach ($chord in @("ctrl+shift+f", "ctrl+shift+n")) {
    $settings.keybindings = @(@($settings.keybindings) | Where-Object { $_.keys -ne $chord })
    $settings.keybindings += [PSCustomObject]@{ id = $null; keys = $chord }
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8
Write-Output "Windows Terminal font + Material Design color scheme installed."
