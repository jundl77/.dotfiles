# Installs Neovim and wires up the repo's vimrc, mirroring the mac/linux `./install`
# step that links `~/.vim`/`~/.vimrc` into `~/.config/nvim`. Safe to re-run.

$ErrorActionPreference = "Stop"

# $ErrorActionPreference does not apply to native commands (winget, nvim) - their
# failures must be surfaced explicitly or the script reports false success.
function Assert-LastExitCode([string]$what) {
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$what failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}

# Refresh PATH from the registry BEFORE the presence checks below, so tools
# installed by a previous run (or another installer) are visible even though this
# process's PATH was cached at shell startup. Append rather than replace: the
# inherited process PATH can carry entries that exist nowhere in the registry
# (e.g. Git Bash's own bin dirs when install.sh invokes this script), and
# vim-plug needs git on PATH for :PlugInstall.
function Update-PathFromRegistry {
    $env:Path = $env:Path + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "User")
}
Update-PathFromRegistry

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    # Try user scope first to avoid a UAC prompt blocking the unattended flow;
    # Neovim currently ships a per-machine MSI, so fall back to machine scope
    # (which may prompt for elevation) if winget rejects the user scope.
    winget install Neovim.Neovim --scope user --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        winget install Neovim.Neovim --accept-package-agreements --accept-source-agreements
        Assert-LastExitCode "winget install Neovim"
    }
}
if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
    # required by Telescope's live_grep (Ctrl+Shift+F)
    winget install BurntSushi.ripgrep.MSVC --accept-package-agreements --accept-source-agreements
    Assert-LastExitCode "winget install ripgrep"
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    # required by Mason to install pyright (lua-language-server ships as a standalone binary).
    # --scope user avoids the MSI's admin-elevation prompt (picks the portable zip build instead).
    winget install OpenJS.NodeJS.LTS --scope user --accept-package-agreements --accept-source-agreements
    Assert-LastExitCode "winget install Node.js"
}

# Pick up whatever the installs above just added to the registry PATH.
Update-PathFromRegistry

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
        Write-Warning "Could not create symlink (enable Windows Developer Mode and sign out/in, or run as Administrator) - copied instead of linking for now. Underlying error: $_"
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
Assert-LastExitCode "headless :PlugInstall"

# :PlugClean! doesn't reliably delete in headless mode (it appears to need a UI), so prune
# directly: remove any plugged/ directory whose repo isn't currently declared in vimrc.
# vim-plug installs to vimrc's plug#begin('~/.config/nvim/plugged'), NOT under LOCALAPPDATA.
$declaredPlugins = [regex]::Matches((Get-Content $source -Raw), "Plug\s+'[^/]+/([^']+)'") |
    ForEach-Object { $_.Groups[1].Value }
$pluggedDir = Join-Path $HOME ".config\nvim\plugged"
if (Test-Path $pluggedDir) {
    Get-ChildItem $pluggedDir -Directory | Where-Object { $declaredPlugins -notcontains $_.Name } | ForEach-Object {
        Write-Output "Removing unused plugin: $($_.Name)"
        Remove-Item $_.FullName -Recurse -Force
    }
}

Write-Output "Installing language servers via Mason (pyright, lua-language-server)..."
nvim --headless "+MasonInstall pyright lua-language-server" "+qa"
Assert-LastExitCode "headless :MasonInstall"

Write-Output "Neovim setup complete."
