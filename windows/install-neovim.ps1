# Installs Neovim and wires up the repo's vimrc, mirroring the mac/linux `./install`
# step that links `~/.vim`/`~/.vimrc` into `~/.config/nvim`. Safe to re-run.

$ErrorActionPreference = "Stop"

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    winget install Neovim.Neovim --accept-package-agreements --accept-source-agreements
}
if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
    # required by Telescope's live_grep (Ctrl+Shift+F)
    winget install BurntSushi.ripgrep.MSVC --accept-package-agreements --accept-source-agreements
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    # required by Mason to install pyright (lua_ls ships as a standalone binary, no node needed)
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
}

# Winget-installed binaries land on the machine/user PATH, but this process's own
# PATH was cached at startup, so a fresh install of nvim/rg above wouldn't be found yet.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
    [System.Environment]::GetEnvironmentVariable("Path", "User")

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

Write-Output "Running :PlugClean! and :PlugInstall headlessly (some plugins may need manual follow-up on Windows)..."
nvim --headless "+PlugClean!" "+PlugInstall" "+qa"

Write-Output "Installing language servers via Mason (pyright, lua_ls)..."
nvim --headless "+MasonInstall pyright lua_ls" "+qa"

Write-Output "Neovim setup complete."
