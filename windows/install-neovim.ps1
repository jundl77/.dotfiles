# Installs Neovim and wires up the repo's vimrc, mirroring the mac/linux `./install`
# step that links `~/.vim`/`~/.vimrc` into `~/.config/nvim`. Safe to re-run.

$ErrorActionPreference = "Stop"

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    winget install Neovim.Neovim --accept-package-agreements --accept-source-agreements
}

$configDir = Join-Path $env:LOCALAPPDATA "nvim"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

$target = Join-Path $configDir "init.vim"
$source = (Resolve-Path (Join-Path $PSScriptRoot "..\vimrc")).Path

if (Test-Path $target) {
    $existing = Get-Item $target
    if (-not ($existing.LinkType -eq "SymbolicLink" -and $existing.Target -eq $source)) {
        Remove-Item $target -Force
    }
}
if (-not (Test-Path $target)) {
    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
        Write-Output "Linked $target -> $source"
    } catch {
        # Developer Mode's symlink privilege only applies to new logon tokens, so this
        # can fail right after enabling it. Fall back to a plain copy so nvim still
        # works today; re-running after a fresh sign-in will upgrade it to a real symlink.
        Copy-Item $source $target -Force
        Write-Warning "Could not create symlink (enable Windows Developer Mode and sign out/in, or run as Administrator) - copied instead of linking for now."
    }
}

$autoloadDir = Join-Path $configDir "autoload"
New-Item -ItemType Directory -Force -Path $autoloadDir | Out-Null
$plugPath = Join-Path $autoloadDir "plug.vim"
if (-not (Test-Path $plugPath)) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" -OutFile $plugPath
    Write-Output "Installed vim-plug."
}

Write-Output "Running :PlugInstall headlessly (some plugins may need manual follow-up on Windows)..."
nvim --headless "+PlugInstall" "+qa"
Write-Output "Neovim setup complete."
