#!/usr/bin/env bash
# OS-aware installer menu. Detects macOS / Linux / Windows (via Git Bash or WSL) and
# offers only the relevant pieces of this repo, so one entry point works everywhere.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux) OS=linux ;;
    MINGW*|MSYS*|CYGWIN*) OS=windows ;;
    *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

echo "Detected OS: ${OS}"
echo

ITEM_NAMES=()
ITEM_FUNCS=()
add_item() { ITEM_NAMES+=("$1"); ITEM_FUNCS+=("$2"); }

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

install_windows_neovim() {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "${DOTFILES_DIR}/windows/install-neovim.ps1")"
}

case "$OS" in
    macos|linux)
        add_item "Git identity + aliases" install_git_identity
        add_item "Fish shell + vim config + brew tools (dotbot)" install_macos_linux_dotfiles
        ;;
    windows)
        add_item "Git identity + aliases" install_git_identity
        add_item "PowerShell profile (Agnoster-style prompt + unix aliases)" install_windows_profile
        add_item "Windows Terminal font + Material Design color scheme" install_windows_terminal_theme
        add_item "Neovim + vim config" install_windows_neovim
        ;;
esac

echo "What do you want to install?"
for i in "${!ITEM_NAMES[@]}"; do
    printf "  %d) %s\n" "$((i + 1))" "${ITEM_NAMES[$i]}"
done
echo

read -rp "Enter numbers separated by spaces, or 'all': " SELECTION

if [ "${SELECTION}" = "all" ]; then
    SELECTION="$(seq 1 "${#ITEM_NAMES[@]}")"
fi

for n in ${SELECTION}; do
    idx=$((n - 1))
    name="${ITEM_NAMES[$idx]:-}"
    func="${ITEM_FUNCS[$idx]:-}"
    if [ -z "${func}" ]; then
        echo "Skipping invalid selection: ${n}"
        continue
    fi
    echo
    echo "==> Installing: ${name}"
    "${func}"
done

echo
echo "Done."
