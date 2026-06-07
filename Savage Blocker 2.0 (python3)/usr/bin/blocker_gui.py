#!/usr/bin/env python3
"""
Savage Blocker - Python Edition
A powerful tool for Debian-based Linux systems to block ads, malware, tracking,
pornography, gambling, social media, and Bitcoin miners via /etc/hosts.

Original bash version: https://github.com/100savage/Savage-Blocker
Licensed under GNU GPL v3.0
"""

import os
import re
import sys
import time
import shutil
import socket
import logging
import platform
import threading
from datetime import datetime
from pathlib import Path
try:
    from tkinter import (
        Tk, Toplevel, Frame, Label, Button, Checkbutton,
        Entry, Text, Scrollbar, messagebox, BooleanVar
    )
    from tkinter.ttk import Progressbar, Style
except ImportError:
    Tk = Toplevel = Frame = Label = Button = Checkbutton = Entry = Text = Scrollbar = messagebox = BooleanVar = Progressbar = Style = None


def _reload_tkinter():
    global Tk, Toplevel, Frame, Label, Button, Checkbutton, Entry, Text, Scrollbar, messagebox, BooleanVar, Progressbar, Style
    if Tk is not None:
        return
    from tkinter import (
        Tk as _Tk, Toplevel as _Toplevel, Frame as _Frame,
        Label as _Label, Button as _Button, Checkbutton as _Checkbutton,
        Entry as _Entry, Text as _Text, Scrollbar as _Scrollbar,
        messagebox as _messagebox, BooleanVar as _BooleanVar,
    )
    from tkinter.ttk import Progressbar as _Progressbar, Style as _Style
    Tk, Toplevel, Frame, Label, Button, Checkbutton, Entry, Text, Scrollbar, messagebox, BooleanVar, Progressbar, Style = (
        _Tk, _Toplevel, _Frame, _Label, _Button, _Checkbutton,
        _Entry, _Text, _Scrollbar, _messagebox, _BooleanVar, _Progressbar, _Style,
    )


from urllib.request import urlopen, Request

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
BLOCKER_DIR = Path("/usr/share/blocker")
HOSTS_PATH = Path("/etc/hosts")
DEBUG_LOG = Path("/tmp/savage-blocker.log")
HEADER_FILE = BLOCKER_DIR / "header"
BLANK_FILE = BLOCKER_DIR / "blank"
EXTRA_FILE = BLOCKER_DIR / "extra"

TIMEOUT = 30
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) Savage-Blocker-Python/1.0"

BLOCKLIST_SOURCES = {
    "Ads and Malware": [
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
    ],
    "Ransomware": [
        "https://blocklistproject.github.io/Lists/ransomware.txt",
        "https://blocklistproject.github.io/Lists/piracy.txt",
    ],
    "Tracking": [
        "https://blocklistproject.github.io/Lists/tracking.txt",
    ],
    "Pornography": [
        "https://blocklistproject.github.io/Lists/porn.txt",
    ],
    "Gambling": [
        "https://blocklistproject.github.io/Lists/gambling.txt",
    ],
    "Social Media": [
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social-only/hosts",
    ],
    "Bitcoin Miners": [
        "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt",
        "https://raw.githubusercontent.com/greatis/Anti-WebMiner/master/hosts",
    ],
}

# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------
def is_linux():
    return platform.system() == "Linux"


def check_root():
    return os.geteuid() == 0


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
_log_initialized = False


def _init_logging():
    global _log_initialized
    if _log_initialized:
        return
    _log_initialized = True

    DEBUG_LOG.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        filename=str(DEBUG_LOG),
        level=logging.DEBUG,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    _l = logging.getLogger("SavageBlocker")
    _l.info("Script started at %s", datetime.now().strftime("%a %b %d %H:%M:%S %Z %Y"))
    _l.info("Platform: %s %s", platform.system(), platform.release())
    _l.info("Python: %s", sys.version)
    if is_linux():
        _l.info("EUID: %s", os.geteuid())


_init_logging()
log = logging.getLogger("SavageBlocker")


def internet_available():
    try:
        socket.gethostbyname("example.com")
        with urlopen(
            Request("http://example.com", headers={"User-Agent": USER_AGENT}),
            timeout=TIMEOUT,
        ) as _:
            return True
    except Exception as exc:
        log.warning(f"Internet check failed: {exc}")
        return False


def download_url(url):
    req = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(req, timeout=TIMEOUT) as resp:
        return resp.read().decode("utf-8", errors="replace")


def extract_domains(text):
    domains = set()
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        match = re.match(r"^(?:0\.0\.0\.0|127\.0\.0\.1)\s+(\S+)", line)
        if match:
            domain = match.group(1).lower()
            if domain not in (
                "localhost", "localhost.localdomain", "local",
                "0.0.0.0", "255.255.255.255",
            ) and not domain.startswith("::"):
                domains.add(domain)
    return sorted(domains)


# ---------------------------------------------------------------------------
# Dependency checker
# ---------------------------------------------------------------------------
MIN_PYTHON = (3, 6)
REQUIRED_PKGS = {
    "tkinter": {
        "apt": "python3-tk",
        "import": "tkinter",
        "check": lambda: __import__("tkinter"),
    },
}


def _run_apt_install(pkg):
    import subprocess
    try:
        subprocess.check_call(
            ["sudo", "apt-get", "install", "-y", pkg],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except Exception:
        return False


def check_dependencies():
    if sys.version_info < MIN_PYTHON:
        print(
            f"Error: Python {MIN_PYTHON[0]}.{MIN_PYTHON[1]} or later required. "
            f"You have {sys.version_info[0]}.{sys.version_info[1]}."
        )
        sys.exit(1)

    missing = []
    for name, info in REQUIRED_PKGS.items():
        try:
            info["check"]()
        except ImportError:
            missing.append((name, info))

    if missing:
        print("The following required packages are missing:")
        for name, info in missing:
            print(f"  - {name}  (install: sudo apt-get install {info['apt']})")
        print()

        try:
            choice = input(
                "Attempt to install missing packages with apt? [Y/n]: "
            ).strip().lower()
        except (EOFError, OSError):
            choice = "n"

        if choice in ("", "y", "yes"):
            all_ok = True
            for name, info in missing:
                print(f"Installing {info['apt']}...")
                if _run_apt_install(info["apt"]):
                    print(f"  {info['apt']} installed successfully.")
                else:
                    print(f"  Failed to install {info['apt']}.")
                    all_ok = False
            if not all_ok:
                print("\nPlease install missing packages manually and try again.")
                sys.exit(1)
            _reload_tkinter()
        else:
            print("\nPlease install missing packages manually and try again.")
            sys.exit(1)

    if is_linux():
        try:
            from tkinter import Tcl
            Tcl()
        except Exception:
            pass


# ---------------------------------------------------------------------------
# Core blocking logic
# ---------------------------------------------------------------------------
class BlockerEngine:
    def __init__(self, status_callback=None, progress_callback=None):
        self.status_callback = status_callback
        self.progress_callback = progress_callback
        self._stop_flag = False

    def _status(self, msg):
        log.info(msg)
        if self.status_callback:
            self.status_callback(msg)

    def _progress(self, value, msg=""):
        if self.progress_callback:
            self.progress_callback(value, msg)

    def ensure_dirs(self):
        BLOCKER_DIR.mkdir(parents=True, exist_ok=True)

        if not HEADER_FILE.exists():
            content = """\
###############################################################################
#                                                                             #
#                       The Savage Blocker Hosts File                         #
#                                                                             #
#   This file is automatically generated by The Savage Blocker.               #
#   It contains a merged collection of block lists from reputable sources     #
#   to protect your system from ads, malware, tracking, and more.             #
#                                                                             #
#   Project: https://github.com/100savage/Savage-Blocker                      #
#   License: GNU GPL v3.0                                                     #
#                                                                             #
###############################################################################

127.0.0.1 localhost
127.0.0.1 localhost.localdomain
127.0.0.1 local
255.255.255.255 broadcasthost
::1 localhost
::1 ip6-localhost
::1 ip6-loopback
fe80::1%lo0 localhost
ff00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
0.0.0.0 0.0.0.0

##############################################
{{TIMESTAMP}}
##############################################
"""
            HEADER_FILE.write_text(content)

        if not BLANK_FILE.exists():
            content = """\
###############################################################################
#                                                                             #
#                       The Savage Blocker Hosts File                         #
#                                                                             #
#   This is a clean hosts file with no blocking enabled.                      #
#                                                                             #
###############################################################################

127.0.0.1 localhost
127.0.0.1 localhost.localdomain
127.0.0.1 local
255.255.255.255 broadcasthost
::1 localhost
::1 ip6-localhost
::1 ip6-loopback
fe80::1%lo0 localhost
ff00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

##############################################
{{TIMESTAMP}}
##############################################
"""
            BLANK_FILE.write_text(content)

        if not EXTRA_FILE.exists():
            EXTRA_FILE.touch()

    def update_blocklists(self, categories):
        if not internet_available():
            raise RuntimeError(
                "No internet connection detected. "
                "Please check your network and try again."
            )

        self._status("Downloading blocklists...")
        temp_dir = Path("/tmp/savage-blocker-tmp")
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
        temp_dir.mkdir(parents=True, exist_ok=True)

        total_steps = sum(len(BLOCKLIST_SOURCES[c]) for c in categories)
        if total_steps == 0:
            raise RuntimeError("No categories selected.")
        step = 0

        for cat in categories:
            if self._stop_flag:
                return
            urls = BLOCKLIST_SOURCES.get(cat, [])
            for url in urls:
                if self._stop_flag:
                    return
                self._status(f"Downloading: {cat} ({url.split('/')[-1]})")
                try:
                    data = download_url(url)
                    fname = re.sub(r"[^a-zA-Z0-9]", "_", url)
                    (temp_dir / fname).write_text(data, encoding="utf-8")
                    time.sleep(1)
                except Exception as exc:
                    log.warning(f"Failed to download {url}: {exc}")
                step += 1
                pct = int((step / total_steps) * 85)
                self._progress(pct, f"Downloaded {step}/{total_steps}")

        self._status("Processing and merging blocklists...")
        all_domains = set()

        for fpath in temp_dir.iterdir():
            if self._stop_flag:
                return
            if fpath.is_file():
                text = fpath.read_text(encoding="utf-8", errors="replace")
                all_domains.update(extract_domains(text))

        if EXTRA_FILE.exists():
            extra_text = EXTRA_FILE.read_text(encoding="utf-8", errors="replace")
            all_domains.update(extract_domains(extra_text))

        self._progress(90, "Writing hosts file...")
        sorted_domains = sorted(all_domains)
        timestamp = f"# Updated on {datetime.now().strftime('%a %b %d %H:%M:%S %Z %Y')} #"
        header_content = HEADER_FILE.read_text(encoding="utf-8")
        header_content = header_content.replace("{{TIMESTAMP}}", timestamp)

        lines = [header_content]
        for domain in sorted_domains:
            lines.append(f"0.0.0.0 {domain}")

        merged = BLOCKER_DIR / "hosts"
        merged.write_text("\n".join(lines) + "\n", encoding="utf-8")
        shutil.copy2(merged, HOSTS_PATH)

        self._progress(100, "Blocklists updated successfully!")
        self._status("Blocklists applied to /etc/hosts")

        shutil.rmtree(temp_dir)

    def reset_hosts(self):
        if not BLANK_FILE.exists():
            raise RuntimeError(f"{BLANK_FILE} does not exist. Run setup first.")
        timestamp = f"# Updated on {datetime.now().strftime('%a %b %d %H:%M:%S %Z %Y')} #"
        content = BLANK_FILE.read_text(encoding="utf-8")
        content = content.replace("{{TIMESTAMP}}", timestamp)
        HOSTS_PATH.write_text(content, encoding="utf-8")
        self._status("Hosts file reset to default (no blocking)")

    def add_domain(self, domain):
        domain = domain.strip().lower()
        if not domain:
            raise ValueError("No domain entered.")
        with EXTRA_FILE.open("a", encoding="utf-8") as f:
            f.write(f"0.0.0.0 {domain}\n")
        self._status(f"Domain '{domain}' added to custom block list")

    def remove_domain(self, domain):
        domain = domain.strip().lower()
        if not domain:
            raise ValueError("No domain entered.")

        if not os.access(str(HOSTS_PATH), os.W_OK):
            raise PermissionError(
                "/etc/hosts is not writable. Please run with sudo."
            )

        hosts_text = HOSTS_PATH.read_text(encoding="utf-8", errors="replace")
        escaped = re.escape(domain)
        pattern = re.compile(
            rf"^.*(?:^|\s){escaped}(?:\s|$).*$", re.MULTILINE
        )
        if not pattern.search(hosts_text):
            raise ValueError(
                f"The domain '{domain}' was not found in /etc/hosts."
            )

        def _remove_from_file(fpath):
            if fpath.exists():
                text = fpath.read_text(encoding="utf-8", errors="replace")
                new_text = pattern.sub("", text)
                new_text = re.sub(r"\n{2,}", "\n", new_text)
                fpath.write_text(new_text, encoding="utf-8")

        _remove_from_file(HOSTS_PATH)
        _remove_from_file(EXTRA_FILE)
        self._status(f"Domain '{domain}' has been unblocked.")

    def stop(self):
        self._stop_flag = True


# ---------------------------------------------------------------------------
# GUI Application
# ---------------------------------------------------------------------------
class SavageBlockerApp:
    THEMES = {
        "dark": {
            "BG": "#1e1e2e",
            "FG": "#cdd6f4",
            "ACCENT": "#89b4fa",
            "BTN_BG": "#313244",
            "BTN_HOVER": "#45475a",
            "RED": "#f38ba8",
            "CARD_BG": "#2a2a3c",
            "LOG_BG": "#11111b",
        },
        "light": {
            "BG": "#f5f5f5",
            "FG": "#1e1e2e",
            "ACCENT": "#1e66f5",
            "BTN_BG": "#e0e0e0",
            "BTN_HOVER": "#d0d0d0",
            "RED": "#d20f39",
            "CARD_BG": "#ffffff",
            "LOG_BG": "#e8e8e8",
        },
    }

    def __init__(self):
        _reload_tkinter()
        self._theme = "dark"
        self._apply_theme()
        self.root = Tk()
        self.root.title("Savage Blocker")
        self.root.geometry("680x640")
        self.root.minsize(580, 540)
        self.root.configure(bg=self.BG)

        if is_linux():
            try:
                self.root.iconname("savage-blocker")
            except Exception:
                pass

        self.engine = BlockerEngine(
            status_callback=self._safe_status,
            progress_callback=self._safe_progress,
        )
        self._build_ui()
        self._check_environment()

    def _apply_theme(self):
        for key, val in self.THEMES[self._theme].items():
            setattr(self, key, val)

    def _toggle_theme(self):
        self._theme = "light" if self._theme == "dark" else "dark"
        self._apply_theme()
        self.root.configure(bg=self.BG)
        self.main.destroy()
        self._build_ui()

    def _check_environment(self):
        if not is_linux():
            self._show_message(
                "Unsupported OS",
                "This tool is designed for Debian-based Linux systems.\n"
                "Some features may not work on other platforms.",
                "warning",
            )
        if is_linux() and not check_root():
            self._show_message(
                "Not Root",
                "This script should be run with sudo/root privileges\n"
                "to modify /etc/hosts.",
                "warning",
            )

    def _build_ui(self):
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)

        self.main = Frame(self.root, bg=self.BG)
        self.main.grid(row=0, column=0, sticky="nsew", padx=20, pady=20)
        self.main.columnconfigure(0, weight=1)

        title = Label(
            self.main,
            text="Savage Blocker",
            font=("Segoe UI", 22, "bold"),
            bg=self.BG, fg=self.ACCENT,
        )
        title.grid(row=0, column=0, pady=(0, 5))

        desc = (
            "This tool is more than just an ad-blocking tool. It is a privacy and security tool to block unwanted\n"
            "websites and enhances privacy and security on Debian-based Linux systems at the DNS level.\n\n"
            "New threats appear daily. Run this tool once a month to keep your block lists current."
        )
        subtitle = Label(
            self.main,
            text=desc,
            font=("Segoe UI", 9),
            bg=self.BG, fg=self.FG, justify="left",
        )
        subtitle.grid(row=1, column=0, pady=(0, 20))

        self._btn_frame = Frame(self.main, bg=self.BG)
        self._btn_frame.grid(row=2, column=0, sticky="ew")
        self._btn_frame.columnconfigure(0, weight=1)

        buttons = [
            ("Update Block Lists", self._on_update, self.ACCENT),
            ("Add a Website to Block", self._on_add, self.FG),
            ("Unblock a Website", self._on_remove, self.FG),
            ("Disable All Blocking", self._on_reset, self.RED),
        ]
        self._buttons = {}
        for i, (text, cmd, color) in enumerate(buttons):
            card = Frame(self._btn_frame, bg=self.CARD_BG, padx=12, pady=6)
            card.grid(row=i, column=0, sticky="ew", pady=4)
            card.columnconfigure(0, weight=1)
            btn = Button(
                card, text=text, command=cmd,
                font=("Segoe UI", 11),
                bg=self.CARD_BG, fg=color,
                activebackground=self.BTN_HOVER, activeforeground=color,
                relief="flat", bd=0, padx=20, pady=10,
                cursor="hand2",
            )
            btn.grid(row=0, column=0, sticky="ew")
            self._buttons[text] = btn

        sep = Frame(self.main, bg=self.BTN_BG, height=1)
        sep.grid(row=3, column=0, sticky="ew", pady=(20, 10))

        status_frame = Frame(self.main, bg=self.BG)
        status_frame.grid(row=4, column=0, sticky="ew")
        status_frame.columnconfigure(0, weight=1)

        self._status_label = Label(
            status_frame, text="Ready",
            font=("Segoe UI", 9),
            bg=self.BG, fg=self.FG, anchor="w",
        )
        self._status_label.grid(row=0, column=0, sticky="ew")

        style = Style()
        style.configure("TProgressbar", background=self.ACCENT, troughcolor=self.BTN_BG, bordercolor=self.BG, lightcolor=self.ACCENT, darkcolor=self.ACCENT)

        self._progress = Progressbar(
            status_frame, mode="determinate",
            length=400, style="TProgressbar",
        )
        self._progress.grid(row=1, column=0, sticky="ew", pady=(5, 0))

        self.main.rowconfigure(5, weight=1)
        self._log_text = Text(
            self.main,
            font=("Consolas", 8),
            bg=self.LOG_BG, fg=self.FG,
            insertbackground=self.FG,
            relief="flat", bd=0,
        )
        self._log_text.grid(row=5, column=0, sticky="nsew", pady=(10, 5))

        log_scroll = Scrollbar(self.main, orient="vertical", command=self._log_text.yview)
        log_scroll.grid(row=5, column=1, sticky="ns", pady=(10, 5))
        self._log_text.configure(yscrollcommand=log_scroll.set)

        bottom_frame = Frame(self.main, bg=self.BG)
        bottom_frame.grid(row=6, column=0, sticky="ew", pady=(10, 0))
        bottom_frame.columnconfigure(0, weight=1)
        bottom_frame.columnconfigure(1, weight=1)

        theme_label = "☀ Light" if self._theme == "dark" else "☁ Dark"
        theme_card = Frame(bottom_frame, bg=self.CARD_BG, padx=12, pady=4)
        theme_card.grid(row=0, column=0, sticky="ew", padx=(0, 5))
        theme_btn = Button(
            theme_card, text=f"Switch to {theme_label} mode", command=self._toggle_theme,
            font=("Segoe UI", 10),
            bg=self.CARD_BG, fg=self.FG,
            activebackground=self.BTN_HOVER, activeforeground=self.FG,
            relief="flat", bd=0, padx=15, pady=6,
            cursor="hand2",
        )
        theme_btn.pack(fill="x")

        exit_card = Frame(bottom_frame, bg=self.CARD_BG, padx=12, pady=4)
        exit_card.grid(row=0, column=1, sticky="ew", padx=(5, 0))
        exit_btn = Button(
            exit_card, text="Exit", command=self.root.destroy,
            font=("Segoe UI", 10),
            bg=self.CARD_BG, fg=self.FG,
            activebackground=self.BTN_HOVER, activeforeground=self.FG,
            relief="flat", bd=0, padx=15, pady=6,
            cursor="hand2",
        )
        exit_btn.pack(fill="x")

        self._log("Savage Blocker started")
        self._log(f"Platform: {platform.system()} {platform.release()}")

    def _log(self, msg):
        ts = datetime.now().strftime("%H:%M:%S")
        self._log_text.insert("end", f"[{ts}] {msg}\n")
        self._log_text.see("end")
        self.root.update_idletasks()

    def _on_status(self, msg):
        self._status_label.configure(text=msg)
        self._log(msg)

    def _on_progress(self, value, msg=""):
        self._progress["value"] = value
        if msg:
            self._status_label.configure(text=msg)
        self.root.update_idletasks()

    def _safe_status(self, msg):
        self.root.after(0, self._on_status, msg)

    def _safe_progress(self, value, msg=""):
        self.root.after(0, self._on_progress, value, msg)

    def _set_buttons(self, enabled):
        state = "normal" if enabled else "disabled"
        for btn in self._buttons.values():
            btn.configure(state=state)

    def _run_in_thread(self, target, args=(), on_success=None):
        self._set_buttons(False)
        self._progress["value"] = 0
        t = threading.Thread(
            target=self._thread_wrapper,
            args=(target, args, on_success),
            daemon=True,
        )
        t.start()

    def _thread_wrapper(self, target, args, on_success):
        try:
            target(*args)
            if on_success:
                self.root.after(0, on_success)
        except Exception as exc:
            err_msg = str(exc)
            log.error(err_msg)
            self.root.after(0, lambda m=err_msg: self._on_error(m))
        finally:
            self.root.after(0, lambda: self._set_buttons(True))

    def _on_error(self, msg):
        self._show_message("Error", msg, "error")
        self._log(f"ERROR: {msg}")

    # --- Menu actions ---

    def _on_update(self):
        dialog = CategoryDialog(self.root, self.BG, self.FG, self.ACCENT, self.BTN_BG, self.BTN_HOVER)
        self.root.wait_window(dialog.dialog)
        if dialog.result:
            self._run_in_thread(
                self.engine.update_blocklists,
                (dialog.result,),
                on_success=self._show_update_success,
            )

    def _on_add(self):
        dialog = InputDialog(
            self.root, "Add a Website to Block",
            "Enter the domain name to block (e.g., example.com):",
            self.BG, self.FG, self.ACCENT, self.BTN_BG, self.BTN_HOVER,
        )
        self.root.wait_window(dialog.dialog)
        if dialog.result:
            try:
                self.engine.add_domain(dialog.result)
                self._log(f"Added '{dialog.result}' to block list")
                self._show_message(
                    "The Savage Blocker",
                    f"Domain '{dialog.result}' added to block list.",
                )
            except Exception as exc:
                self._on_error(str(exc))
                return
            self._on_update()

    def _on_remove(self):
        dialog = InputDialog(
            self.root, "Unblock a Website",
            "Enter the domain name to unblock (e.g., example.com):",
            self.BG, self.FG, self.ACCENT, self.BTN_BG, self.BTN_HOVER,
        )
        self.root.wait_window(dialog.dialog)
        if dialog.result:
            domain = dialog.result
            self._log(f"Removing '{domain}' from block lists. Please wait...")
            self._status_label.configure(text=f"Removing '{domain}'...")
            self._run_in_thread(
                self.engine.remove_domain,
                (domain,),
                on_success=lambda: self._show_remove_success(domain),
            )

    def _show_update_success(self):
        self._show_message(
            "The Savage Blocker",
            "Block lists have been updated. Your system is now more secure.\n\n"
            "Run this tool monthly to stay up-to-date with the latest block lists.",
        )

    def _show_remove_success(self, domain):
        self._show_message(
            "The Savage Blocker",
            f"The domain '{domain}' has been unblocked.",
        )

    def _on_reset(self):
        if not self._show_message(
            "Confirm Reset",
            "This will remove ALL blocking and reset /etc/hosts to default.\n\n"
            "Are you sure?",
            "question",
        ):
            return
        self._run_in_thread(
            self.engine.reset_hosts,
            (),
            on_success=self._show_reset_success,
        )

    def _show_reset_success(self):
        self._show_message(
            "The Savage Blocker",
            "Website blocking has been disabled. Your hosts file has been reset.",
            "warning",
        )

    def _show_message(self, title, message, mode="info", parent=None):
        d = MessageDialog(parent or self.root, title, message, mode, self.BG, self.FG, self.ACCENT, self.BTN_BG, self.BTN_HOVER)
        self.root.wait_window(d.dialog)
        return d.result

    def run(self):
        self.root.mainloop()


# ---------------------------------------------------------------------------
# Custom dialogs
# ---------------------------------------------------------------------------
class MessageDialog:
    CARD_BG = "#2a2a3c"

    def __init__(self, parent, title, message, mode="info", bg="#1e1e2e", fg="#cdd6f4", accent="#89b4fa", btn_bg="#313244", btn_hover="#45475a"):
        _reload_tkinter()
        self.dialog = Toplevel(parent)
        self.dialog.title("")
        self.dialog.configure(bg=bg)
        self.dialog.resizable(False, False)
        self.result = None
        self.dialog.transient(parent)
        self.dialog.grab_set()

        if mode == "error":
            title_fg = "#f38ba8"
        elif mode == "warning":
            title_fg = "#f9e2af"
        else:
            title_fg = accent

        w = Frame(self.dialog, bg=bg, padx=20, pady=20)
        w.pack(fill="both", expand=True)

        Label(
            w, text=title,
            font=("Segoe UI", 12, "bold"),
            bg=bg, fg=title_fg,
        ).pack(anchor="w")

        sep = Frame(w, bg=btn_bg, height=1)
        sep.pack(fill="x", pady=(10, 15))

        Label(
            w, text=message,
            font=("Segoe UI", 10),
            bg=bg, fg=fg, justify="left", wraplength=620,
        ).pack(anchor="w")

        btn_frame = Frame(w, bg=bg)
        btn_frame.pack(pady=(20, 0))

        if mode == "question":
            no_card = Frame(btn_frame, bg=self.CARD_BG, padx=12, pady=4)
            no_card.pack(side="left", padx=(0, 10))
            Button(
                no_card, text="Cancel",
                font=("Segoe UI", 10),
                bg=self.CARD_BG, fg=fg,
                activebackground=btn_hover, activeforeground=fg,
                relief="flat", bd=0, padx=20, pady=6,
                cursor="hand2",
                command=lambda: self._finish(False),
            ).pack(fill="x")

            yes_card = Frame(btn_frame, bg=self.CARD_BG, padx=12, pady=4)
            yes_card.pack(side="left")
            Button(
                yes_card, text="Yes, Reset",
                font=("Segoe UI", 10),
                bg=self.CARD_BG, fg=accent,
                activebackground=btn_hover, activeforeground=accent,
                relief="flat", bd=0, padx=20, pady=6,
                cursor="hand2",
                command=lambda: self._finish(True),
            ).pack(fill="x")
        else:
            ok_card = Frame(btn_frame, bg=self.CARD_BG, padx=12, pady=4)
            ok_card.pack()
            Button(
                ok_card, text="OK",
                font=("Segoe UI", 10),
                bg=self.CARD_BG, fg=accent,
                activebackground=btn_hover, activeforeground=accent,
                relief="flat", bd=0, padx=20, pady=6,
                cursor="hand2",
                command=self._finish,
            ).pack(fill="x")

        self.dialog.minsize(680, 120)
        self.dialog.geometry(f"+{parent.winfo_x()+50}+{parent.winfo_y()+50}")

    def _finish(self, result=None):
        if result is not None:
            self.result = result
        self.dialog.destroy()


class CategoryDialog:
    CARD_BG = "#2a2a3c"

    def __init__(self, parent, bg, fg, accent, btn_bg, btn_hover):
        _reload_tkinter()
        self.dialog = Toplevel(parent)
        self.dialog.title("Select Categories")
        self.dialog.configure(bg=bg)
        self.dialog.resizable(False, False)
        self.result = None
        self.dialog.transient(parent)
        self.dialog.grab_set()
        self.bg = bg
        self.fg = fg
        self.accent = accent
        self.btn_bg = btn_bg
        self.btn_hover = btn_hover

        w = Frame(self.dialog, bg=bg, padx=20, pady=20)
        w.pack(fill="both", expand=True)

        Label(
            w, text="Select categories to block:",
            font=("Segoe UI", 12, "bold"),
            bg=bg, fg=accent,
        ).pack(anchor="w", pady=(0, 15))

        self.vars = {}
        default_cats = [
            "Ads and Malware", "Ransomware", "Tracking",
            "Pornography", "Gambling", "Social Media", "Bitcoin Miners",
        ]
        for cat in default_cats:
            var = BooleanVar(value=True)
            self.vars[cat] = var

            card = Frame(w, bg=self.CARD_BG, padx=10, pady=6)
            card.pack(fill="x", pady=3)

            cb = Checkbutton(
                card, text=cat, variable=var,
                font=("Segoe UI", 10),
                bg=self.CARD_BG, fg=fg,
                selectcolor=btn_bg,
                activebackground=self.CARD_BG, activeforeground=fg,
                relief="flat",
            )
            cb.pack(anchor="w", fill="x")

        btn_frame = Frame(w, bg=bg)
        btn_frame.pack(pady=(20, 0))

        Button(
            btn_frame, text="Cancel",
            font=("Segoe UI", 10),
            bg=btn_bg, fg=fg,
            activebackground=btn_hover, activeforeground=fg,
            relief="flat", bd=0, padx=20, pady=6,
            cursor="hand2",
            command=self.dialog.destroy,
        ).pack(side="left", padx=(0, 10))

        Button(
            btn_frame, text="Start Blocking",
            font=("Segoe UI", 10),
            bg=btn_bg, fg=accent,
            activebackground=btn_hover, activeforeground=accent,
            relief="flat", bd=0, padx=20, pady=6,
            cursor="hand2",
            command=self._on_confirm,
        ).pack(side="left")

        self.dialog.minsize(680, 200)
        self.dialog.geometry(f"+{parent.winfo_x()+50}+{parent.winfo_y()+50}")

    def _on_confirm(self):
        self.result = [cat for cat, var in self.vars.items() if var.get()]
        if not self.result:
            d = MessageDialog(self.dialog, "No Selection", "Please select at least one category.", "warning", self.bg, self.fg, self.accent, self.btn_bg, self.btn_hover)
            self.dialog.wait_window(d.dialog)
            return
        self.dialog.destroy()


class InputDialog:
    CARD_BG = "#2a2a3c"

    def __init__(self, parent, title, prompt, bg, fg, accent, btn_bg, btn_hover):
        _reload_tkinter()
        self.dialog = Toplevel(parent)
        self.dialog.title(title)
        self.dialog.configure(bg=bg)
        self.dialog.resizable(False, False)
        self.result = None
        self.dialog.transient(parent)
        self.dialog.grab_set()
        self.bg = bg
        self.fg = fg
        self.accent = accent
        self.btn_bg = btn_bg
        self.btn_hover = btn_hover

        w = Frame(self.dialog, bg=bg, padx=20, pady=20)
        w.pack(fill="both", expand=True)

        Label(
            w, text=prompt,
            font=("Segoe UI", 10),
            bg=bg, fg=fg,
        ).pack(anchor="w", pady=(0, 10))

        entry_card = Frame(w, bg=self.CARD_BG, padx=10, pady=6)
        entry_card.pack(fill="x", pady=(0, 15))

        self.entry = Entry(
            entry_card, font=("Segoe UI", 11),
            bg=self.CARD_BG, fg=fg,
            insertbackground=fg,
            relief="flat", bd=0,
        )
        self.entry.pack(fill="x")
        self.entry.focus_set()

        btn_frame = Frame(w, bg=bg)
        btn_frame.pack()

        cancel_card = Frame(btn_frame, bg=self.CARD_BG, padx=12, pady=4)
        cancel_card.pack(side="left", padx=(0, 10))
        Button(
            cancel_card, text="Cancel",
            font=("Segoe UI", 10),
            bg=self.CARD_BG, fg=fg,
            activebackground=btn_hover, activeforeground=fg,
            relief="flat", bd=0, padx=20, pady=6,
            cursor="hand2",
            command=self.dialog.destroy,
        ).pack(fill="x")

        ok_card = Frame(btn_frame, bg=self.CARD_BG, padx=12, pady=4)
        ok_card.pack(side="left")
        Button(
            ok_card, text="OK",
            font=("Segoe UI", 10),
            bg=self.CARD_BG, fg=accent,
            activebackground=btn_hover, activeforeground=accent,
            relief="flat", bd=0, padx=20, pady=6,
            cursor="hand2",
            command=self._on_ok,
        ).pack(fill="x")

        self.dialog.bind("<Return>", lambda e: self._on_ok())
        self.dialog.geometry(f"+{parent.winfo_x()+50}+{parent.winfo_y()+50}")

    def _on_ok(self):
        val = self.entry.get().strip()
        if not val:
            d = MessageDialog(self.dialog, "Empty", "Please enter a domain.", "warning", self.bg, self.fg, self.accent, self.btn_bg, self.btn_hover)
            self.dialog.wait_window(d.dialog)
            return
        self.result = val
        self.dialog.destroy()


# ---------------------------------------------------------------------------
# CLI fallback
# ---------------------------------------------------------------------------
def cli_main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Savage Blocker - Block ads, malware, and more."
    )
    parser.add_argument(
        "--update", "-u", nargs="*",
        help="Update blocklists for given categories (default: all). "
             "Options: ads, ransomware, tracking, porn, gambling, social, bitcoin",
    )
    parser.add_argument("--add", "-a", metavar="DOMAIN", help="Add a domain to block")
    parser.add_argument("--remove", "-r", metavar="DOMAIN", help="Remove a domain from block")
    parser.add_argument("--reset", action="store_true", help="Disable all blocking")
    parser.add_argument("--setup", action="store_true", help="Create data directory and files")
    parser.add_argument("--gui", action="store_true", help="Launch GUI")
    args = parser.parse_args()

    if not is_linux():
        print("Warning: This tool is designed for Debian-based Linux.")

    engine = BlockerEngine(
        status_callback=lambda m: print(f"[*] {m}"),
        progress_callback=lambda v, m: print(f"[{v}%] {m}"),
    )
    engine.ensure_dirs()
    log.info("Savage Blocker CLI started")

    CAT_MAP = {
        "ads": "Ads and Malware",
        "ransomware": "Ransomware",
        "tracking": "Tracking",
        "porn": "Pornography",
        "gambling": "Gambling",
        "social": "Social Media",
        "bitcoin": "Bitcoin Miners",
    }

    try:
        if args.setup:
            engine.ensure_dirs()
            print("Setup complete. Directory and files created.")
        elif args.add:
            engine.add_domain(args.add)
            print(f"Added '{args.add}' to block list.")
        elif args.remove:
            engine.remove_domain(args.remove)
            print(f"Removed '{args.remove}' from block list.")
        elif args.reset:
            engine.reset_hosts()
            print("Blocking disabled. Hosts file reset.")
        elif args.update is not None:
            categories = [CAT_MAP[c] for c in args.update] if args.update else list(
                BLOCKLIST_SOURCES.keys()
            )
            engine.update_blocklists(categories)
            print("Done.")
        elif args.gui:
            check_dependencies()
            log.info("Savage Blocker GUI started from CLI")
            app = SavageBlockerApp()
            app.run()
        else:
            parser.print_help()
    except Exception as exc:
        print(f"Error: {exc}")
        sys.exit(1)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def main():
    if len(sys.argv) > 1:
        cli_main()
        return

    check_dependencies()

    if not is_linux():
        print("Warning: This tool is designed for Debian-based Linux.\n")

    BlockerEngine().ensure_dirs()
    log.info("Savage Blocker started")
    app = SavageBlockerApp()
    app.run()


if __name__ == "__main__":
    main()
