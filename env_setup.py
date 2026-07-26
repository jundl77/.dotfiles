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


def link_state(link: Path, target: Path):
    """'ok' (symlink to target), 'copy' (plain file present), or 'missing'."""
    if link.is_symlink():
        try:
            if link.resolve() == target.resolve():
                return "ok"
        except OSError:
            pass
        return "copy"
    if link.exists():
        return "copy"
    return "missing"


def ensure_symlink(target: Path, link: Path):
    """Symlink link -> target; on Windows without the privilege, copy instead."""
    state = link_state(link, target)
    if state == "ok":
        return "ok"
    link.parent.mkdir(parents=True, exist_ok=True)
    if link.exists() or link.is_symlink():
        backup = link.with_name(link.name + ".backup")
        if not link.is_symlink() and not backup.exists():
            shutil.copy2(link, backup)
            console.print(f"  backed up {link} -> {backup.name}")
        if link.is_dir() and not link.is_symlink():
            shutil.rmtree(link)
        else:
            link.unlink()
    try:
        link.symlink_to(target, target_is_directory=target.is_dir())
        console.print(f"  linked {link} -> {target}")
        return "ok"
    except OSError:
        if target.is_dir():
            shutil.copytree(target, link)
        else:
            shutil.copy2(target, link)
        console.print(
            f"  [yellow]copied[/] {target.name} -> {link} "
            "(no symlink privilege - enable Developer Mode and sign out/in, then re-run to upgrade)"
        )
        return "copy"


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
# Components. Each: name, platforms, detect() -> (state, detail), install().
# States: "ok", "partial", "missing".
# --------------------------------------------------------------------------- #

class GitIdentity:
    name = "git identity + aliases"
    platforms = ("windows", "macos", "linux")

    def detect(self):
        try:
            email = run(["git", "config", "--global", "user.email"], capture=True, check=False).stdout.strip()
            alias = run(["git", "config", "--global", "alias.co"], capture=True, check=False).stdout.strip()
        except OSError:
            return "missing", "git not installed"
        if email == GIT_EMAIL and alias == "checkout":
            return "ok", email
        return "missing", "not configured"

    def install(self):
        run(["git", "config", "--global", "user.email", GIT_EMAIL])
        run(["git", "config", "--global", "user.name", GIT_NAME])
        for alias, expansion in GIT_ALIASES.items():
            run(["git", "config", "--global", f"alias.{alias}", expansion])


class Packages:
    name = "packages"
    platforms = ("windows", "macos", "linux")

    WINDOWS = [  # (binary, winget id, extra args)
        ("nvim", "Neovim.Neovim", []),
        ("rg", "BurntSushi.ripgrep.MSVC", []),
        ("node", "OpenJS.NodeJS.LTS", ["--scope", "user"]),
    ]
    MACOS = ["eza", "lnav", "bat", "ripgrep", "highlight", "grc", "vim", "neovim", "node"]
    LINUX = ["eza", "lnav", "bat", "ripgrep", "highlight", "vim", "neovim", "grc", "nodejs", "npm"]

    def detect(self):
        if PLATFORM == "windows":
            missing = [b for b, _, _ in self.WINDOWS if not shutil.which(b)]
        elif PLATFORM == "macos":
            if not shutil.which("brew"):
                return "missing", "Homebrew not installed (https://brew.sh)"
            have = run(["brew", "list", "--formula"], capture=True, check=False).stdout.split()
            missing = [p for p in self.MACOS if p not in have]
        else:
            missing = [p for p in self.LINUX
                       if run(["dpkg", "-s", p], capture=True, check=False).returncode != 0]
        if not missing:
            return "ok", "all present"
        return ("partial" if len(missing) < 3 else "missing"), "missing: " + ", ".join(missing)

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


class ShellConfig:
    name = "shell config"
    platforms = ("windows", "macos", "linux")

    def _links(self):
        if PLATFORM == "windows":
            return [(REPO / "windows/Microsoft.PowerShell_profile.ps1",
                     HOME / "Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1")]
        return [(REPO / "config/fish", HOME / ".config/fish")]

    def detect(self):
        states = [link_state(link, target) for target, link in self._links()]
        if PLATFORM != "windows":
            bashrc = HOME / ".bashrc"
            hook = "source ~/.dotfiles/julian_bash.sh"
            states.append("ok" if bashrc.exists() and hook in bashrc.read_text() else "missing")
        if all(s == "ok" for s in states):
            return "ok", "linked"
        if any(s != "missing" for s in states):
            return "partial", "copied, not symlinked" if "copy" in states else "incomplete"
        return "missing", "not set up"

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
        else:
            bashrc = HOME / ".bashrc"
            hook = "source ~/.dotfiles/julian_bash.sh"
            if not bashrc.exists() or hook not in bashrc.read_text():
                with bashrc.open("a") as f:
                    f.write(f"\n{hook}\n")


class EditorConfig:
    name = "vim/nvim config"
    platforms = ("windows", "macos", "linux")

    def _links(self):
        vimrc = REPO / "vimrc"
        links = [(REPO / "ideavimrc", HOME / ".ideavimrc")]
        if PLATFORM == "windows":
            links.append((vimrc, Path(os.environ["LOCALAPPDATA"]) / "nvim/init.vim"))
        else:
            links.append((vimrc, HOME / ".vimrc"))
            links.append((vimrc, HOME / ".config/nvim/init.vim"))
        return links

    def detect(self):
        states = [link_state(link, target) for target, link in self._links()]
        if all(s == "ok" for s in states):
            return "ok", "linked"
        if any(s != "missing" for s in states):
            return "partial", "copied, not symlinked" if "copy" in states else "incomplete"
        return "missing", "not set up"

    def install(self):
        for target, link in self._links():
            ensure_symlink(target, link)


class NeovimPlugins:
    name = "nvim plugins + LSP servers"
    platforms = ("windows", "macos", "linux")

    PLUGGED = HOME / ".config/nvim/plugged"
    LSP_SERVERS = ["pyright", "lua-language-server"]

    def _autoload(self):
        base = Path(os.environ["LOCALAPPDATA"]) / "nvim" if PLATFORM == "windows" else HOME / ".config/nvim"
        return base / "autoload/plug.vim"

    def _mason_missing(self):
        mason = (Path(os.environ["LOCALAPPDATA"]) / "nvim-data" if PLATFORM == "windows"
                 else HOME / ".local/share/nvim") / "mason/packages"
        return [s for s in self.LSP_SERVERS if not (mason / s).exists()]

    def detect(self):
        if not shutil.which("nvim"):
            return "missing", "nvim not installed"
        if not self._autoload().exists():
            return "missing", "vim-plug not installed"
        if not self.PLUGGED.is_dir() or not any(self.PLUGGED.iterdir()):
            return "partial", "plugins not installed"
        missing = self._mason_missing()
        if missing and nvim_version() and nvim_version() >= (0, 11):
            return "partial", "LSP servers missing: " + ", ".join(missing)
        return "ok", f"{len(list(self.PLUGGED.iterdir()))} plugins"

    def install(self):
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
            if self._mason_missing():
                run(["nvim", "--headless", "+MasonInstall " + " ".join(self.LSP_SERVERS), "+qa"])
        else:
            console.print("  [yellow]nvim < 0.11: skipping LSP servers (vimrc skips LSP there too)[/]")


class WindowsTerminal:
    name = "Windows Terminal font + theme + keybinds"
    platforms = ("windows",)

    FONT_DIR = Path(os.environ.get("LOCALAPPDATA", "")) / "Microsoft/Windows/Fonts"
    FONT_FACES = ["Regular", "Bold", "Italic", "BoldItalic"]
    NVIM_CHORDS = [  # CSI-u encodings nvim parses natively; WT can't send Ctrl+Shift otherwise
        ("User.nvimFindInPath", "ctrl+shift+f", "\x1b[102;6u"),
        ("User.nvimGotoFile", "ctrl+shift+n", "\x1b[110;6u"),
    ]

    def _font_ok(self):
        return (self.FONT_DIR / "MesloLGMNerdFontMono-Regular.ttf").exists()

    def detect(self):
        settings_path = wt_settings_path()
        if not settings_path:
            return "missing", "Windows Terminal not installed"
        s = json.loads(settings_path.read_text(encoding="utf-8-sig"))
        theme_ok = any(sc.get("name") == "Material Design" for sc in s.get("schemes", []))
        chords_ok = all(any(a.get("id") == cid for a in s.get("actions", []))
                        for cid, _, _ in self.NVIM_CHORDS)
        if self._font_ok() and theme_ok and chords_ok:
            return "ok", "configured"
        if theme_ok or self._font_ok():
            return "partial", "incomplete"
        return "missing", "not configured"

    def install(self):
        if not self._font_ok():
            console.print("  downloading Meslo Nerd Font (~30 MB) ...")
            import zipfile
            zip_path = REPO / ".venv/Meslo.zip"
            download("https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip", zip_path)
            self.FONT_DIR.mkdir(parents=True, exist_ok=True)
            import winreg
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

        settings_path = wt_settings_path()
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


class ClaudeConfig:
    name = "claude config"
    platforms = ("windows", "macos", "linux")

    def _links(self):
        return [
            (REPO / "claude/settings.json", HOME / ".claude/settings.json"),
            (REPO / "claude/CLAUDE.md", HOME / ".claude/CLAUDE.md"),
        ]

    def detect(self):
        states = [link_state(link, target) for target, link in self._links()]
        if all(s == "ok" for s in states):
            return "ok", "linked"
        if any(s != "missing" for s in states):
            return "partial", "copied, not symlinked" if "copy" in states else "incomplete"
        return "missing", "not set up"

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


COMPONENTS = [c for c in (
    GitIdentity(), Packages(), ShellConfig(), EditorConfig(),
    NeovimPlugins(), WindowsTerminal(), ClaudeConfig(),
) if PLATFORM in c.platforms]


# --------------------------------------------------------------------------- #
# UI
# --------------------------------------------------------------------------- #

MARKS = {"ok": "[green]OK[/]", "partial": "[yellow]~[/]", "missing": "[red]X[/]"}


def gather_status():
    out = []
    for c in COMPONENTS:
        try:
            state, detail = c.detect()
        except Exception as e:  # a broken detect must not kill the menu
            state, detail = "missing", f"detect failed: {e}"
        out.append((c, state, detail))
    return out


def print_status(status):
    table = Table(title=f"dotfiles on {PLATFORM}", title_justify="left")
    table.add_column("")
    table.add_column("component")
    table.add_column("detail", style="dim")
    for c, state, detail in status:
        table.add_row(MARKS[state], c.name, detail)
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
        print_status(gather_status())
        return

    if args.install:
        status = gather_status()
        if args.install == "all":
            targets = [c for c, state, _ in status if state != "ok"]
        else:
            targets = [c for c, _, _ in status if args.install.lower() in c.name.lower()]
            if not targets:
                sys.exit(f"No component matches '{args.install}'. "
                         f"Components: {', '.join(c.name for c in COMPONENTS)}")
        ok = all([install_component(c) for c in targets])
        print_status(gather_status())
        sys.exit(0 if ok else 1)

    while True:
        console.clear()
        console.print("[bold]env_setup[/] - deploy the dev setup\n")
        status = gather_status()
        print_status(status)
        missing = [(c, state) for c, state, _ in status if state != "ok"]

        choices = []
        if missing:
            choices.append(f"Install everything missing ({len(missing)})")
        choices += ["Install one component ...", "Refresh", "Quit"]
        answer = questionary.select("What do you want to do?", choices=choices).ask()

        if answer is None or answer == "Quit":
            return
        if answer == "Refresh":
            continue
        if answer.startswith("Install everything"):
            for c, _ in missing:
                install_component(c)
        else:
            names = [c.name for c, _, _ in status]
            pick = questionary.select("Which component?", choices=names + ["Back"]).ask()
            if pick and pick != "Back":
                install_component(next(c for c in COMPONENTS if c.name == pick))
        questionary.press_any_key_to_continue().ask()


if __name__ == "__main__":
    main()
