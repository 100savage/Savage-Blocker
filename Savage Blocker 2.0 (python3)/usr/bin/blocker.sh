#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Savage Blocker - Bash Launcher
# Checks and installs all prerequisites for the Python blocker script,
# then hands off execution.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/blocker_gui.py"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

err() { echo -e "${RED}[!]${NC} $*" >&2; }
ok()  { echo -e "${GREEN}[*]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }

# -- Root check -----------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root (sudo) to modify /etc/hosts."
    exit 1
fi

# -- OS check -------------------------------------------------------------
if [[ ! -f /etc/debian_version ]]; then
    warn "This tool is designed for Debian-based Linux systems."
fi

# -- Python 3 check -------------------------------------------------------
PYTHON=""
if command -v python3 &>/dev/null; then
    ver=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    if printf '%s\n' "3.6" "$ver" | sort -V -C; then
        PYTHON="python3"
    fi
fi

if [[ -z "$PYTHON" ]]; then
    warn "Python 3.6+ is not installed."
    echo -n "[?] Install python3 with apt? [Y/n]: "
    read -r yn
    if [[ "$yn" =~ ^[Yy]([Ee][Ss])?$|^$ ]]; then
        ok "Installing python3..."
        apt-get update -qq && apt-get install -y -qq python3 || {
            err "Failed to install python3. Install manually: sudo apt-get install python3"
            exit 1
        }
        PYTHON="python3"
    else
        err "Python 3.6+ is required. Install it: sudo apt-get install python3"
        exit 1
    fi
fi

ok "Using $("$PYTHON" --version 2>&1)"

# -- Tkinter check --------------------------------------------------------
if ! "$PYTHON" -c "import tkinter" &>/dev/null; then
    warn "Tkinter (python3-tk) is not installed."
    echo -n "[?] Install python3-tk with apt? [Y/n]: "
    read -r yn
    if [[ "$yn" =~ ^[Yy]([Ee][Ss])?$|^$ ]]; then
        ok "Installing python3-tk..."
        apt-get install -y -qq python3-tk || {
            err "Failed to install python3-tk. Install: sudo apt-get install python3-tk"
            exit 1
        }
    else
        err "Tkinter is required for the GUI. Install: sudo apt-get install python3-tk"
        err "You can still use CLI mode: sudo ./blocker.sh --update"
        exit 1
    fi
fi

# -- Handoff to Python script ---------------------------------------------
ok "Launching Savage Blocker..."
exec "$PYTHON" "$PYTHON_SCRIPT" "$@"
