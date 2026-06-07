# The Savage Blocker

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Version: 2.0](https://img.shields.io/badge/Version-2.0-green.svg)
![Platform: Debian/Ubuntu](https://img.shields.io/badge/Platform-Debian%2FUbuntu-orange.svg)

The Savage Blocker is a powerful tool for Debian-based Linux systems (e.g., Debian/Ubuntu/Linux Mint) that blocks unwanted websites, including ads, malware, ransomware, tracking, pornography, gambling, social media, and Bitcoin miners. By updating `/etc/hosts` with curated blocklists, it enhances privacy, reduces distractions, saves bandwidth, and speeds up web browsing.

**Version 2.0** introduces a native Python 3 GUI with a modern dark/light theme, threaded downloads, real-time progress, a built-in log viewer, and improved reliability — alongside the original bash/Zenity version.

## Features

- **Block Websites by Category**:
  - Ads and Malware
  - Ransomware
  - Tracking
  - Pornography
  - Gambling
  - Social Media
  - Bitcoin Miners
- **Custom Blocking**: Add or remove specific domains.
- **Reset Blocking**: Remove all blocks with one click.
- **Modern Python GUI** (v2.0): Dark/light theme toggle, real-time progress bar, scrollable log output, threaded downloads.
- **Classic Bash GUI** (v1.3): Zenity-based menus for lightweight environments.
- **Easy Installation**: Available as a `.deb` package.

## Screenshots

![Menu 1](https://raw.githubusercontent.com/100savage/Savage-Blocker/main/images/menu1.png)
![Menu 2](https://raw.githubusercontent.com/100savage/Savage-Blocker/main/images/menu2.png)
<img src="https://raw.githubusercontent.com/100savage/Savage-Blocker/main/images/menu3.png" width="550">

## Installation

### Option 1: Install Python 2.0 via .deb Package (Recommended)

1. **Download the Package**:
   - Get `savage-blocker_2.0_all.deb` from the [repository](https://github.com/100savage/Savage-Blocker/blob/main/savage_blocker_2.0_all.deb).
2. **Install**:
   ```bash
   sudo dpkg -i savage-blocker_2.0_all.deb
   sudo apt-get install -f  # Resolve dependencies if needed
   ```
   The Savage Blocker app will appear in the "Internet section" of your menu.

### Option 2: Install Bash 1.3 via .deb Package

1. **Download the Package**:
   - Get `savage-blocker_1.3_all.deb` from the [repository](https://github.com/100savage/Savage-Blocker/blob/main/savage_blocker_1.3_all.deb).
2. **Install**:
   ```bash
   sudo dpkg -i savage-blocker_1.3_all.deb
   sudo apt-get install -f  # Resolve dependencies if needed
   ```

### Option 3: Manual Installation (Python 2.0)

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/100savage/Savage-Blocker.git
   cd Savage-Blocker/savage_blocker_2.0_all
   ```
2. **Install Dependencies**:
   ```bash
   sudo apt-get update
   sudo apt-get install python3 python3-tk
   ```
3. **Run**:
   ```bash
   sudo ./usr/bin/blocker.sh
   ```

### Option 4: Manual Installation (Bash 1.3)

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/100savage/Savage-Blocker.git
   cd Savage-Blocker
   ```
2. **Install Dependencies**:
   ```bash
   sudo apt-get update
   sudo apt-get install zenity wget
   ```
3. **Set Up Files**:
   ```bash
   sudo mkdir -p /usr/share/blocker
   sudo chmod -R u+w /usr/share/blocker
   echo "127.0.0.1 localhost" | sudo tee /usr/share/blocker/blank
   echo "# Hosts file header" | sudo tee /usr/share/blocker/header
   sudo touch /usr/share/blocker/extra
   ```
4. **Make Executable**:
   ```bash
   chmod +x usr/bin/blocker.sh
   ```

## Usage

### If using the Python GUI (v2.0)
```bash
sudo ./usr/bin/blocker.sh  # Launcher from manual install
```
Or launch from your start menu: Internet → Savage Blocker.

### If using the Bash Zenity GUI (v1.3)
```bash
sudo -E usr/bin/blocker.sh  # From manual install
```

### Screenshots
- **Main Menu**: Choose to launch, add/remove websites, reset blocking, or exit.
- **Blocklist Selection**: Select categories to block.
- **Downloading**: Real-time progress during updates.
- **Debug Log**: View `/tmp/savage-blocker.log` for details.

**Tip**: Run monthly to keep blocklists updated.

## Python 2.0 New Features

- **Native Python 3 GUI** — Built with tkinter for a polished, responsive interface.
- **Dark/Light Theme Toggle** — Switch between dark and light themes with one click.
- **Threaded Downloads** — Blocklist updates run in the background without freezing the UI.
- **Real-Time Progress** — Progress bar and status updates during downloads and processing.
- **Built-in Log Viewer** — Scrollable log output right in the main window.
- **Custom Dialog Styling** — All message boxes use the application's dark/light theme.
- **Automated Dependency Handling** — Checks for Python 3.6+ and tkinter, offers to install if missing.
- **CLI Mode** — Command-line interface available for headless or scripted use (`--update`, `--add`, `--remove`, `--reset`, `--gui`).
- **Improved Error Handling** — Graceful failure with clear error messages and logging.

## Changelog

### Version 2.0 (June 2026)
- **New Python 3 GUI**: Complete rewrite with native tkinter interface.
- **Dark/Light Theme**: Toggle between dark and light themes on the fly.
- **Threaded Operations**: Downloads and processing run in background threads.
- **Real-Time Progress**: Progress bar and status updates during all operations.
- **Built-in Log**: Scrollable log output integrated into the main window.
- **Custom Themed Dialogs**: All message boxes match the selected theme.
- **Improved Error Handling**: Comprehensive error handling with user-friendly messages.
- **CLI Support**: Full command-line interface for automation and scripting.
- **New .deb Package**: Simplified installation for the Python version.

### Version 1.3 (April 2026)
- **New .deb Package**: Simplifies installation with dependencies and file setup.
- **Improved Timestamp**: Enhanced date format in `/etc/hosts` for better tracking of updates.
- **Improved Code**: Enhanced speed and stability.

### Version 1.2 (October 2025)
- **Improved Zenity Detection**: Explicit `/usr/bin/zenity` check for reliability.
- **Better Display Handling**: Validates `$DISPLAY=:0` for consistent GUI performance.
- **Enhanced Logging**: Detailed logs and clear error messages. /tmp/savage-blocker.log
- **New .deb Package**: Simplifies installation with dependencies and file setup.
- **Remove duplicate entries**: Eliminates redundant domains from overlapping blocklist sources for a cleaner `/etc/hosts` file.
- **Sort entries**: Sorts blocked domains alphabetically in `/etc/hosts` for easier navigation.
- **Add timestamp to hosts file**: Includes the date of the last run as a comment in `/etc/hosts` for tracking updates.
- **Updated license to GNU GPL v3.0**

## Blocklist Sources

- [StevenBlack Hosts](https://github.com/StevenBlack/hosts)
- [Blocklist Project](https://blocklistproject.github.io/Lists)
- [NoCoin Adblock List](https://github.com/hoshsadiq/adblock-nocoin-list)
- [Anti-WebMiner](https://github.com/greatis/Anti-WebMiner)

## Contributing

Contributions are welcome! To contribute:
1. Fork the repository.
2. Create a branch (`git checkout -b feature-name`).
3. Commit changes (`git commit -m "Add feature"`).
4. Push to the branch (`git push origin feature-name`).
5. Open a pull request.

Report issues via [Issues](https://github.com/100savage/Savage-Blocker/issues). See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Licensed under the [GNU General Public License v3.0](LICENSE).

## Support

For issues, check `/tmp/savage-blocker.log` or run:
```bash
sudo ./usr/bin/blocker.sh 2>&1 | tee /tmp/savage-blocker-output.log
```

© 2025-2026 100savage
