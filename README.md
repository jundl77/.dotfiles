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
installs `eza`/`lnav`/`bat`/`ripgrep`/`highlight`/`vim`/`neovim`/`grc`/`node` via brew on
macOS or apt on Linux (no brew needed on Linux; `node` is required by Mason to install
`pyright` — see below), plus:

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
- `windows/install-neovim.ps1` - installs Neovim, ripgrep, and Node.js via winget, symlinks
  `vimrc` as `init.vim`, and runs `:PlugInstall` + Mason's language-server install headlessly

### vimrc (all platforms)

CLion-flavored: Telescope for Go to File / Find in Path (`Ctrl+Shift+N`/`Ctrl+Shift+F`),
`nvim-tree.lua` as a file-explorer sidebar (`Ctrl+H`), and `nvim-lspconfig` + `mason.nvim`
(auto-installs `pyright` + `lua_ls`) for Go to Declaration/Implementation (`Ctrl+B`/
`Ctrl+Alt+B`), Find Usages (`Alt+F7`), Rename (`Shift+F6`), Quick Documentation (`Ctrl+Q`),
Show Intention Actions (`Alt+Enter`), Reformat Code (`Ctrl+Alt+L`), and next/previous
highlighted error (`F2`/`Shift+F2`). `Ctrl+D` (duplicate line) and `Ctrl+/` (comment) were
deliberately left off since they collide with vim's native scroll and this repo's existing
`Ctrl+C` comment-toggle binding.

## Dependencies:

- fish (macOS/Linux)
- brew (macOS)
- apt-based distro, e.g. Ubuntu/Debian/WSL (Linux)
- Windows Terminal (Windows)
- ripgrep + Node.js (Telescope live_grep and Mason's pyright install, respectively —
  installed automatically by `./install`/`./install.sh` on every platform)

