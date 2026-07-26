#!/usr/bin/env python3
"""One installer for the whole dev setup, on any platform.

Run `python env_setup.py` for the interactive menu, `--status` for a
non-interactive overview, or `--install NAME|all` for scripted installs.

First run creates .venv/ next to this file and installs its own two UI
dependencies (rich, questionary) there, then re-executes itself.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent
HOME = Path.home()

GIT_EMAIL = "julianbrendl@gmail.com"
GIT_NAME = "Julian Brendl"
GIT_ALIASES = {"co": "checkout", "br": "branch", "ci": "commit", "st": "status", "sm": "submodule"}

if sys.platform == "win32":
    PLATFORM = "windows"
elif sys.platform == "darwin":
    PLATFORM = "macos"
else:
    PLATFORM = "linux"


# --------------------------------------------------------------------------- #
# Bootstrap: make sure rich + questionary are importable, via a local venv.
# --------------------------------------------------------------------------- #

def bootstrap():
    try:
        import rich  # noqa: F401
        import questionary  # noqa: F401
        return
    except ImportError:
        pass
    if os.environ.get("ENV_SETUP_BOOTSTRAPPED"):
        sys.exit("Bootstrap failed: rich/questionary still missing inside .venv")

    venv_dir = REPO / ".venv"
    venv_py = venv_dir / ("Scripts/python.exe" if PLATFORM == "windows" else "bin/python")
    if not venv_py.exists():
        print("First run: creating .venv and installing UI dependencies ...")
        import venv as venv_mod
        venv_mod.create(venv_dir, with_pip=True)
        subprocess.run([str(venv_py), "-m", "pip", "install", "--quiet", "rich", "questionary"], check=True)
    env = dict(os.environ, ENV_SETUP_BOOTSTRAPPED="1")
    sys.exit(subprocess.call([str(venv_py), str(Path(__file__).resolve())] + sys.argv[1:], env=env))


bootstrap()

from rich.console import Console  # noqa: E402
from rich.table import Table  # noqa: E402
import questionary  # noqa: E402

console = Console()


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

def run(cmd, check=True, capture=False, **kw):
    return subprocess.run(
        cmd, check=check, text=True,
        capture_output=capture, **kw
    )


def refresh_windows_path():
    """New winget installs land on the registry PATH; merge it into ours."""
    import winreg
    parts = [os.environ.get("PATH", "")]
    for hive, key in [
        (winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment"),
        (winreg.HKEY_CURRENT_USER, r"Environment"),
    ]:
        try:
            with winreg.OpenKey(hive, key) as k:
                value, _ = winreg.QueryValueEx(k, "Path")
                parts.append(winreg.ExpandEnvironmentStrings(value))
        except OSError:
            pass
    os.environ["PATH"] = os.pathsep.join(p for p in parts if p)


if PLATFORM == "windows":
    refresh_windows_path()


def short(path: Path):
    return str(path).replace(str(HOME), "~")


def link_state(link: Path, target: Path):
    """'ok' (symlink to target), 'partial' (plain copy present), or 'missing'."""
    if link.is_symlink():
        try:
            if link.resolve() == target.resolve():
                return "ok"
        except OSError:
            pass
        return "partial"
    if link.exists():
        return "partial"
    return "missing"


def ensure_symlink(target: Path, link: Path):
    """Symlink link -> target; on Windows without the privilege, copy instead."""
    if link_state(link, target) == "ok":
        return
    link.parent.mkdir(parents=True, exist_ok=True)
    if link.exists() or link.is_symlink():
        backup = link.with_name(link.name + ".backup")
        if not link.is_symlink() and not backup.exists():
            shutil.copy2(link, backup)
            console.print(f"  backed up {short(link)} -> {backup.name}")
        if link.is_dir() and not link.is_symlink():
            shutil.rmtree(link)
        else:
            link.unlink()
    try:
        link.symlink_to(target, target_is_directory=target.is_dir())
        console.print(f"  linked {short(link)} -> {short(target)}")
    except OSError:
        if target.is_dir():
            shutil.copytree(target, link)
        else:
            shutil.copy2(target, link)
        console.print(
            f"  [yellow]copied[/] {target.name} -> {short(link)} "
            "(no symlink privilege - enable Developer Mode and sign out/in, then re-run to upgrade)"
        )


def combine(states):
    if all(s == "ok" for s in states):
        return "ok"
    if all(s == "missing" for s in states):
        return "missing"
    return "partial"


def download(url: str, dest: Path):
    dest.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as resp:
        dest.write_bytes(resp.read())


def nvim_version():
    try:
        out = run(["nvim", "--version"], capture=True).stdout.splitlines()[0]
        m = re.search(r"v(\d+)\.(\d+)", out)
        return (int(m.group(1)), int(m.group(2))) if m else None
    except (OSError, subprocess.CalledProcessError):
        return None


def wt_settings_path():
    hits = list((Path(os.environ.get("LOCALAPPDATA", "")) / "Packages").glob(
        "Microsoft.WindowsTerminal_*/LocalState/settings.json"))
    return hits[0] if hits else None


# --------------------------------------------------------------------------- #
# Components. Each declares its sub-checks in items() -> [(label, state)];
# the component state is the roll-up. States: "ok", "partial", "missing".
# --------------------------------------------------------------------------- #

class Component:
    def ok_detail(self, items):
        return "configured"


class GitIdentity(Component):
    name = "git"

    def items(self):
        def cfg(key):
            return run(["git", "config", "--global", key], capture=True, check=False).stdout.strip()
        try:
            items = [
                (f"user.email = {GIT_EMAIL}", "ok" if cfg("user.email") == GIT_EMAIL else "missing"),
                (f"user.name = {GIT_NAME}", "ok" if cfg("user.name") == GIT_NAME else "missing"),
            ]
        except OSError:
            return [("git binary", "missing")]
        for alias, expansion in GIT_ALIASES.items():
            items.append((f"alias {alias} = {expansion}",
                          "ok" if cfg(f"alias.{alias}") == expansion else "missing"))
        return items

    def ok_detail(self, items):
        return GIT_EMAIL

    def install(self):
        run(["git", "config", "--global", "user.email", GIT_EMAIL])
        run(["git", "config", "--global", "user.name", GIT_NAME])
        for alias, expansion in GIT_ALIASES.items():
            run(["git", "config", "--global", f"alias.{alias}", expansion])


class Packages(Component):
    name = "system packages"

    WINDOWS = [  # (binary, winget id, extra args) - node is needed by Mason for pyright
        ("nvim", "Neovim.Neovim", ["--scope", "user"]),
        ("rg", "BurntSushi.ripgrep.MSVC", []),
        ("node", "OpenJS.NodeJS.LTS", ["--scope", "user"]),
    ]
    MACOS = ["eza", "lnav", "bat", "ripgrep", "highlight", "grc", "vim", "neovim", "node"]
    LINUX = ["eza", "lnav", "bat", "ripgrep", "highlight", "vim", "neovim", "grc", "nodejs", "npm"]

    def items(self):
        if PLATFORM == "windows":
            return [(f"{binary} (winget {pkg})", "ok" if shutil.which(binary) else "missing")
                    for binary, pkg, _ in self.WINDOWS]
        if PLATFORM == "macos":
            if not shutil.which("brew"):
                return [("Homebrew (https://brew.sh)", "missing")]
            have = run(["brew", "list", "--formula"], capture=True, check=False).stdout.split()
            return [(f"{p} (brew)", "ok" if p in have else "missing") for p in self.MACOS]
        return [(f"{p} (apt)", "ok" if run(["dpkg", "-s", p], capture=True, check=False).returncode == 0
                 else "missing") for p in self.LINUX]

    def ok_detail(self, items):
        return "all present"

    def install(self):
        if PLATFORM == "windows":
            for binary, pkg, extra in self.WINDOWS:
                if shutil.which(binary):
                    continue
                base = ["winget", "install", pkg, "--accept-package-agreements", "--accept-source-agreements"]
                # user scope first where offered, to dodge UAC; fall back to default scope
                result = run(base + extra, check=False)
                if result.returncode != 0 and extra:
                    run(base)
            refresh_windows_path()
        elif PLATFORM == "macos":
            for p in self.MACOS:
                run(["brew", "install", p], check=False)
        else:
            run(["sudo", "apt-get", "update"])
            run(["sudo", "apt-get", "install", "-y"] + self.LINUX)
            # Debian/Ubuntu ship bat as batcat; expose it as bat
            batcat = shutil.which("batcat")
            if batcat:
                bindir = HOME / "bin"
                bindir.mkdir(exist_ok=True)
                (bindir / "bat").unlink(missing_ok=True)
                (bindir / "bat").symlink_to(batcat)


class VimNvim(Component):
    """Everything editor: config symlinks, plugins, LSP servers."""
    name = "vim/nvim"

    PLUGGED = HOME / ".config/nvim/plugged"
    LSP_SERVERS = ["pyright", "lua-language-server"]

    def _links(self):
        vimrc = REPO / "vimrc"
        links = [(REPO / "ideavimrc", HOME / ".ideavimrc")]
        if PLATFORM == "windows":
            links.append((vimrc, Path(os.environ["LOCALAPPDATA"]) / "nvim/init.vim"))
        else:
            links.append((vimrc, HOME / ".vimrc"))
            links.append((vimrc, HOME / ".config/nvim/init.vim"))
        return links

    def _autoload(self):
        base = Path(os.environ["LOCALAPPDATA"]) / "nvim" if PLATFORM == "windows" else HOME / ".config/nvim"
        return base / "autoload/plug.vim"

    def _mason_dir(self):
        return (Path(os.environ["LOCALAPPDATA"]) / "nvim-data" if PLATFORM == "windows"
                else HOME / ".local/share/nvim") / "mason/packages"

    def _plugin_count(self):
        return len(list(self.PLUGGED.iterdir())) if self.PLUGGED.is_dir() else 0

    def items(self):
        items = [("nvim binary", "ok" if shutil.which("nvim") else "missing")]
        for target, link in self._links():
            items.append((f"{short(link)} -> {target.name}", link_state(link, target)))
        items.append(("vim-plug", "ok" if self._autoload().exists() else "missing"))
        count = self._plugin_count()
        items.append((f"plugins installed ({count})", "ok" if count else "missing"))
        version = nvim_version()
        if version and version >= (0, 11):
            for server in self.LSP_SERVERS:
                items.append((f"LSP: {server}", "ok" if (self._mason_dir() / server).exists() else "missing"))
        return items

    def ok_detail(self, items):
        return f"{self._plugin_count()} plugins"

    def install(self):
        if not shutil.which("nvim"):
            raise RuntimeError("nvim not installed - run the system packages component first")
        for target, link in self._links():
            ensure_symlink(target, link)
        autoload = self._autoload()
        if not autoload.exists():
            download("https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim", autoload)
            console.print("  installed vim-plug")
        run(["nvim", "--headless", "+PlugInstall", "+qa"])
        # :PlugClean! is unreliable headlessly; prune undeclared plugins directly
        declared = re.findall(r"Plug\s+'[^/]+/([^']+)'", (REPO / "vimrc").read_text())
        if self.PLUGGED.is_dir():
            for d in self.PLUGGED.iterdir():
                if d.is_dir() and d.name not in declared:
                    console.print(f"  removing unused plugin: {d.name}")
                    shutil.rmtree(d)
        version = nvim_version()
        if version and version >= (0, 11):
            missing = [s for s in self.LSP_SERVERS if not (self._mason_dir() / s).exists()]
            if missing:
                run(["nvim", "--headless", "+MasonInstall " + " ".join(missing), "+qa"])
        else:
            console.print("  [yellow]nvim < 0.11: skipping LSP servers (vimrc skips LSP there too)[/]")


class TerminalSetup(Component):
    """Shell config everywhere; on Windows also the whole terminal look & keybinds."""
    name = "terminal setup"

    FONT_DIR = Path(os.environ.get("LOCALAPPDATA", "")) / "Microsoft/Windows/Fonts"
    FONT_FACES = ["Regular", "Bold", "Italic", "BoldItalic"]
    NVIM_CHORDS = [  # CSI-u encodings nvim parses natively; WT can't send Ctrl+Shift otherwise
        ("User.nvimFindInPath", "ctrl+shift+f", "\x1b[102;6u"),
        ("User.nvimGotoFile", "ctrl+shift+n", "\x1b[110;6u"),
    ]
    BASHRC_HOOK = "source ~/.dotfiles/julian_bash.sh"

    def _links(self):
        if PLATFORM == "windows":
            return [(REPO / "windows/Microsoft.PowerShell_profile.ps1",
                     HOME / "Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1")]
        return [(REPO / "config/fish", HOME / ".config/fish")]

    def items(self):
        items = []
        for target, link in self._links():
            items.append((f"{short(link)} -> {target.name}", link_state(link, target)))
        if PLATFORM == "windows":
            policy = run(["powershell", "-NoProfile", "-Command", "Get-ExecutionPolicy -Scope CurrentUser"],
                         capture=True, check=False).stdout.strip()
            items.append(("execution policy (RemoteSigned)",
                          "ok" if policy not in ("Undefined", "Restricted") else "missing"))
            items.append(("Meslo Nerd Font",
                          "ok" if (self.FONT_DIR / "MesloLGMNerdFontMono-Regular.ttf").exists() else "missing"))
            settings_path = wt_settings_path()
            if not settings_path:
                items.append(("Windows Terminal", "missing"))
            else:
                s = json.loads(settings_path.read_text(encoding="utf-8-sig"))
                items.append(("Material Design color scheme",
                              "ok" if any(sc.get("name") == "Material Design" for sc in s.get("schemes", []))
                              else "missing"))
                items.append(("Ctrl+Shift+F/N keybinds for nvim",
                              "ok" if all(any(a.get("id") == cid for a in s.get("actions", []))
                                          for cid, _, _ in self.NVIM_CHORDS) else "missing"))
        else:
            bashrc = HOME / ".bashrc"
            hooked = bashrc.exists() and self.BASHRC_HOOK in bashrc.read_text()
            items.append(("bashrc hook (julian_bash.sh)", "ok" if hooked else "missing"))
        return items

    def install(self):
        for target, link in self._links():
            ensure_symlink(target, link)
        if PLATFORM == "windows":
            policy = run(["powershell", "-NoProfile", "-Command", "Get-ExecutionPolicy -Scope CurrentUser"],
                         capture=True, check=False).stdout.strip()
            if policy in ("Undefined", "Restricted"):
                run(["powershell", "-NoProfile", "-Command",
                     "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"])
                console.print("  execution policy set to RemoteSigned")
            self._install_font()
            self._install_terminal_settings()
        else:
            bashrc = HOME / ".bashrc"
            if not bashrc.exists() or self.BASHRC_HOOK not in bashrc.read_text():
                with bashrc.open("a") as f:
                    f.write(f"\n{self.BASHRC_HOOK}\n")

    def _install_font(self):
        if (self.FONT_DIR / "MesloLGMNerdFontMono-Regular.ttf").exists():
            return
        console.print("  downloading Meslo Nerd Font (~30 MB) ...")
        import winreg
        import zipfile
        zip_path = REPO / ".venv/Meslo.zip"
        download("https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip", zip_path)
        self.FONT_DIR.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(zip_path) as zf:
            for face in self.FONT_FACES:
                fname = f"MesloLGMNerdFontMono-{face}.ttf"
                (self.FONT_DIR / fname).write_bytes(zf.read(fname))
                with winreg.OpenKey(winreg.HKEY_CURRENT_USER,
                                    r"Software\Microsoft\Windows NT\CurrentVersion\Fonts",
                                    0, winreg.KEY_SET_VALUE) as k:
                    winreg.SetValueEx(k, f"MesloLGM Nerd Font Mono {face} (TrueType)",
                                      0, winreg.REG_SZ, str(self.FONT_DIR / fname))
        zip_path.unlink()
        console.print("  font installed (restart Windows Terminal to pick it up)")

    def _install_terminal_settings(self):
        settings_path = wt_settings_path()
        if not settings_path:
            console.print("  [yellow]Windows Terminal not installed - skipping theme/keybinds[/]")
            return
        s = json.loads(settings_path.read_text(encoding="utf-8-sig"))
        scheme = json.loads((REPO / "windows/material-design.windowsterminal.json").read_text())
        s.setdefault("schemes", [])
        s["schemes"] = [sc for sc in s["schemes"] if sc.get("name") != "Material Design"] + [scheme]
        s.setdefault("profiles", {}).setdefault("defaults", {})
        s["profiles"]["defaults"]["colorScheme"] = "Material Design"
        s["profiles"]["defaults"]["font"] = {"face": "MesloLGM Nerd Font Mono"}
        s.setdefault("actions", [])
        s.setdefault("keybindings", [])
        for cid, keys, seq in self.NVIM_CHORDS:
            s["actions"] = [a for a in s["actions"] if a.get("id") != cid]
            s["actions"].append({"command": {"action": "sendInput", "input": seq}, "id": cid})
            s["keybindings"] = [b for b in s["keybindings"] if b.get("keys") != keys]
            s["keybindings"].append({"id": cid, "keys": keys})
        settings_path.write_text(json.dumps(s, indent=4), encoding="utf-8")
        console.print("  Windows Terminal settings updated")


class ClaudeConfig(Component):
    name = "claude"

    def _links(self):
        return [
            (REPO / "claude/settings.json", HOME / ".claude/settings.json"),
            (REPO / "claude/CLAUDE.md", HOME / ".claude/CLAUDE.md"),
        ]

    def items(self):
        return [(f"{short(link)} -> claude/{target.name}", link_state(link, target))
                for target, link in self._links()]

    def ok_detail(self, items):
        return "linked"

    def install(self):
        settings_link = HOME / ".claude/settings.json"
        # Machine-specific statusLine must not follow the shared settings around:
        # move it into settings.local.json (merged by Claude Code, stays local).
        if settings_link.exists() and not settings_link.is_symlink():
            existing = json.loads(settings_link.read_text())
            status_line = existing.pop("statusLine", None)
            if status_line:
                local_path = HOME / ".claude/settings.local.json"
                local = json.loads(local_path.read_text()) if local_path.exists() else {}
                local.setdefault("statusLine", status_line)
                local_path.write_text(json.dumps(local, indent=2))
                console.print("  moved machine-specific statusLine to settings.local.json")
        for target, link in self._links():
            ensure_symlink(target, link)


COMPONENTS = [
    GitIdentity(), Packages(), VimNvim(), TerminalSetup(), ClaudeConfig(),
]


# --------------------------------------------------------------------------- #
# UI
# --------------------------------------------------------------------------- #

MARKS = {"ok": "[green]OK[/]", "partial": "[yellow]~[/]", "missing": "[red]X[/]"}


def gather_status():
    out = []
    for c in COMPONENTS:
        try:
            items = c.items()
            state = combine([s for _, s in items])
            if state == "ok":
                detail = c.ok_detail(items)
            else:
                bad = [label for label, s in items if s != "ok"]
                detail = ", ".join(bad[:3]) + (" ..." if len(bad) > 3 else "")
        except Exception as e:  # a broken check must not kill the menu
            items, state, detail = [], "missing", f"check failed: {e}"
        out.append((c, state, detail, items))
    return out


def print_status(status, expanded=()):
    table = Table(title=f"dotfiles on {PLATFORM}", title_justify="left")
    table.add_column("")
    table.add_column("component")
    table.add_column("detail", style="dim")
    for c, state, detail, items in status:
        arrow = "v" if c.name in expanded else ">"
        table.add_row(MARKS[state], f"{arrow} {c.name}", detail)
        if c.name in expanded:
            for label, istate in items:
                table.add_row(MARKS[istate], f"    {label}", "")
    console.print(table)


def install_component(component):
    console.print(f"\n[bold]Installing: {component.name}[/]")
    try:
        component.install()
        console.print(f"[green]done: {component.name}[/]")
        return True
    except Exception as e:
        console.print(f"[red]failed: {component.name}: {e}[/]")
        return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--status", action="store_true", help="print status and exit")
    parser.add_argument("--install", metavar="NAME", help="install one component (or 'all') and exit")
    args = parser.parse_args()

    if args.status:
        print_status(gather_status(), expanded=[c.name for c in COMPONENTS])
        return

    if args.install:
        status = gather_status()
        if args.install == "all":
            targets = [c for c, state, _, _ in status if state != "ok"]
        else:
            targets = [c for c, _, _, _ in status if args.install.lower() in c.name.lower()]
            if not targets:
                sys.exit(f"No component matches '{args.install}'. "
                         f"Components: {', '.join(c.name for c in COMPONENTS)}")
        ok = all([install_component(c) for c in targets])
        print_status(gather_status())
        sys.exit(0 if ok else 1)

    styled_marks = {
        "ok": ("fg:ansigreen bold", "OK"),
        "partial": ("fg:ansiyellow bold", " ~"),
        "missing": ("fg:ansired bold", " X"),
    }
    text_marks = {"ok": "OK", "partial": " ~", "missing": " X"}
    expanded = set()
    status = gather_status()
    while True:
        console.clear()
        console.print(f"[bold]env_setup[/] - dotfiles on {PLATFORM}\n")
        missing = [c for c, state, _, _ in status if state != "ok"]
        width = max(len(c.name) for c, _, _, _ in status) + 2

        choices = []
        if missing:
            choices.append(questionary.Choice(f"Install everything missing ({len(missing)})", value="all"))
        for c, state, detail, items in status:
            arrow = "v" if c.name in expanded else ">"
            style, mark = styled_marks[state]
            title = [(style, mark), ("", f" {arrow} {c.name:<{width}}"), ("fg:ansibrightblack", detail)]
            choices.append(questionary.Choice(title, value=("toggle", c)))
            if c.name in expanded:
                for label, istate in items:
                    choices.append(questionary.Separator(f"      {text_marks[istate]}  {label}"))
                verb = "re-install" if state == "ok" else "install"
                choices.append(questionary.Choice(f"         {verb} {c.name}", value=("install", c)))
        choices.append(questionary.Choice("Refresh", value="refresh"))
        choices.append(questionary.Choice("Re-install everything", value="reinstall-all"))
        choices.append(questionary.Choice("Quit", value="quit"))
        answer = questionary.select("Enter expands a component / runs an action:", choices=choices).ask()

        if answer is None or answer == "quit":
            return
        if answer == "refresh":
            status = gather_status()
            continue
        if isinstance(answer, tuple) and answer[0] == "toggle":
            expanded ^= {answer[1].name}
            continue
        if answer == "all":
            targets = missing
        elif answer == "reinstall-all":
            targets = [c for c, _, _, _ in status]
        else:
            targets = [answer[1]]
        for c in targets:
            install_component(c)
        questionary.press_any_key_to_continue().ask()
        status = gather_status()


if __name__ == "__main__":
    main()
