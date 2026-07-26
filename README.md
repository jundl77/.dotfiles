# My dotfile configs

One Python installer (`env_setup.py`) deploys the full dev setup on any
platform: packages, shell + editor + terminal config, and Claude Code config.

## Usage

```
git clone https://github.com/jundl77/.dotfiles ~/.dotfiles
cd ~/.dotfiles
python env_setup.py          # interactive menu: see what's installed, install what's not
python env_setup.py --status         # non-interactive status table
python env_setup.py --install all    # install everything missing, no menu
```

The first run creates `.venv/` next to the script and installs the two UI
libraries (`rich`, `questionary`) there, then re-executes itself — nothing is
installed into your system Python.

## What it manages

| Component | What it does |
|---|---|
| git identity + aliases | user.name/email, `co`/`br`/`ci`/`st`/`sm` aliases |
| packages | winget (Windows: nvim, ripgrep, node) / brew (macOS) / apt (Linux) |
| shell config | Windows: PowerShell profile (Agnoster-style prompt + unix aliases) + execution policy. macOS/Linux: fish config + bashrc hook |
| vim/nvim config | symlinks `vimrc` (as `init.vim` for nvim) and `ideavimrc` |
| nvim plugins + LSP servers | vim-plug, `:PlugInstall`, prunes removed plugins, Mason installs pyright + lua-language-server (nvim 0.11+) |
| Windows Terminal | Meslo Nerd Font, Material Design color scheme, CSI-u keybinds so Ctrl+Shift+F/N reach nvim |
| claude config | symlinks `claude/settings.json` and `claude/CLAUDE.md` into `~/.claude` (machine-specific `statusLine` is moved to `settings.local.json`, which stays local) |

Configs are **symlinked** into place so a `git pull` updates the live setup.
On Windows without symlink privilege it falls back to copying and tells you
(enable Developer Mode + sign out/in, then re-run to upgrade copies to links).
Pre-existing real files are backed up once as `<name>.backup`.

## vimrc

CLion-flavored nvim setup: Telescope for Go to File / Find in Path
(`Ctrl+Shift+N`/`Ctrl+Shift+F`, laid out like CLion's dialog — prompt on top,
matches, preview editor below; `,fd` greps an arbitrary directory; `Ctrl+P`,
`,ff`, `,fg` as universal fallbacks), `nvim-tree.lua` file-explorer sidebar
(`Ctrl+H`), and `nvim-lspconfig` + `mason.nvim` for Go to Declaration /
Implementation (`Ctrl+B`/`Ctrl+Alt+B`), Find Usages (`Alt+F7`), Rename
(`Shift+F6`), Quick Documentation (`Ctrl+Q`), Intentions (`Alt+Enter`),
Reformat (`Ctrl+Alt+L`), and next/prev error (`F2`/`Shift+F2`). Multi-cursor
is opt-in via `;m` (then `n` next / `q` skip / `Esc` exit).

The LSP features need nvim 0.11+; on older neovim (e.g. apt's) the vimrc
silently skips the LSP section and everything else still works. Plain vim is
still supported: nvim-only plugins and mappings are guarded, and vim gets
syntastic/YouCompleteMe instead.

## Notes

- `Ctrl+D` (CLion duplicate line) and `Ctrl+/` (CLion comment) are deliberately
  unmapped — they collide with vim's native scroll and the existing `Ctrl+C`
  comment binding.
- On macOS, install [Homebrew](https://brew.sh) first; on Windows, `winget`
  (ships with Windows 11) and Python 3 are the only prerequisites.
