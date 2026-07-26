# My dotfile configs

## What's inside?

- vimrc
- fish config
- a few handy binaries, installed via brew (macOS) or apt (Linux)
- `windows/` - PowerShell profile + Windows Terminal setup, ported from the fish config

## Usage:

Run `./install.sh` — it detects your OS (macOS, Linux, or Windows via Git Bash/WSL)
and installs everything relevant to it automatically, no prompts.

On Windows, symlinking the PowerShell profile requires Developer Mode (Settings ->
Privacy & Security -> For developers) or an elevated shell; enabling Developer Mode
only takes effect for new shell sessions (sign out/in or reboot first).

### macOS / Linux

Falls through to the existing dotbot-based `./install`, which symlinks the dotfiles and
installs `eza`/`lnav`/`bat`/`ripgrep`/`highlight`/`vim`/`neovim`/`grc` via brew on macOS
or apt on Linux (no brew needed on Linux), plus:

- open vim/nvim and run ```:PlugInstall```
- YouCompleteMe needs a one-time native build: `~/.vim/plugged/YouCompleteMe/install.py --clangd-completer`

### Windows

- `windows/Microsoft.PowerShell_profile.ps1` - Agnoster-style prompt (status/venv/path/git
  segments with powerline separators, ported from `config/fish/functions/fish_prompt.fish`)
  plus unix-like aliases (`ll`, `la`, `grep`, `which`, `touch`, `open`, `df`, `..`/`.../....`)
- `windows/material-design.windowsterminal.json` - Windows Terminal color scheme, ported
  from `iterm-themes/material-design.itermcolors`
- `windows/install-terminal-theme.ps1` - installs the Meslo Nerd Font (glyphs for the
  prompt) and registers the color scheme as the default for all Windows Terminal profiles
- `windows/link-profile.ps1` - symlinks the profile into place and sets the CurrentUser
  script execution policy to RemoteSigned (both required for the profile to load)

## Dependencies:

- fish (macOS/Linux)
- brew (macOS)
- apt-based distro, e.g. Ubuntu/Debian/WSL (Linux)
- Windows Terminal (Windows)

