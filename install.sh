#!/usr/bin/env bash
# OS-aware installer. Detects macOS / Linux / Windows (via Git Bash or WSL) and
# installs everything relevant to it, so one entry point works everywhere.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux) OS=linux ;;
    MINGW*|MSYS*|CYGWIN*) OS=windows ;;
    *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

echo "Detected OS: ${OS} -- installing everything for it."
echo

install_git_identity() {
    git config --global user.email "julianbrendl@gmail.com"
    git config --global user.name "Julian Brendl"
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.sm submodule
    echo "Git identity + aliases installed."
}

install_macos_linux_dotfiles() {
    if [ "$OS" = "macos" ] && ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found - install it from https://brew.sh first, then re-run." >&2
        return 1
    fi
    "${DOTFILES_DIR}/install"
}

install_windows_profile() {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "${DOTFILES_DIR}/windows/link-profile.ps1")"
}

install_windows_terminal_theme() {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "${DOTFILES_DIR}/windows/install-terminal-theme.ps1")"
}

case "$OS" in
    macos|linux)
        echo "==> Installing: Git identity + aliases"
        install_git_identity
        echo
        echo "==> Installing: Fish shell + vim config + brew/apt tools (dotbot)"
        install_macos_linux_dotfiles
        ;;
    windows)
        echo "==> Installing: Git identity + aliases"
        install_git_identity
        echo
        echo "==> Installing: PowerShell profile (Agnoster-style prompt + unix aliases)"
        install_windows_profile
        echo
        echo "==> Installing: Windows Terminal font + Material Design color scheme"
        install_windows_terminal_theme
        ;;
esac

echo
echo "Done."
