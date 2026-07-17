# The Savage Blocker

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Version: 2.0](https://img.shields.io/badge/Version-2.0-green.svg)
![Platform: Debian/Ubuntu](https://img.shields.io/badge/Platform-Debian%2FUbuntu-orange.svg)

The Savage Blocker is a powerful tool for Debian-based Linux systems (e.g., Debian/Ubuntu/Linux Mint) that blocks unwanted websites, including ads, malware, ransomware, tracking, pornography, gambling, social media, and Bitcoin miners. By updating `/etc/hosts` with curated blocklists, it enhances privacy, reduces distractions, saves bandwidth, and speeds up web browsing.

**Version 2.0** introduces a native Python 3 GUI with a modern dark/light theme, threaded downloads, real-time progress, a built-in log viewer, monthly auto-update, and comprehensive CLI support.

## Features

- **Block Websites by Category**:
  - Ads and Malware
  - Ransomware
  - Tracking
  - Pornography
  - Gambling
  - Social Media
  - Bitcoin Miners
- **Custom Domain Blocking**: Add or remove specific domains from the block list.
- **Custom Extra Block List**: Domains added manually persist in `/usr/share/blocker/extra` and are included in all future updates.
- **Reset Blocking**: Remove all blocks and restore the default hosts file with one click.
- **Monthly Auto-Update**: Enable scheduled updates via cron.monthly — choose exactly which categories to include.
- **Dark/Light Theme**: Toggle between dark and light themes on the fly. All dialogs and popups match the selected theme.
- **Real-Time Progress**: Progress bar and status updates during downloads and processing.
- **Built-in Log Viewer**: Scrollable log output integrated into the main window.
- **Threaded Operations**: Downloads and processing run in background threads without freezing the UI.
- **Environment Checks**: Warnings for unsupported operating systems and missing root privileges.
- **Internet Connectivity Check**: Verifies network access before attempting downloads.
- **Deduplication**: Automatically removes duplicate entries across overlapping blocklist sources.
- **Debug Logging**: Detailed logs written to `/tmp/savage-blocker.log` for troubleshooting.
- **CLI Mode**: Full command-line interface for headless or scripted use.
- **Easy Installation**: Available as a `.deb` package.

## Screenshot Main Menu Dark Mode


![Menu 1](https://raw.githubusercontent.com/100savage/Savage-Blocker/main/images/menu1.png)

## Screenshot Main Menu Light mode

![Menu 2](https://raw.githubusercontent.com/100savage/Savage-Blocker/main/images/menu2.png)

## Installation

### Option 1: Install via .deb Package (Recommended)

1. **Download the Package**:
   - Get `savage-blocker_2.0_all.deb` from the [repository](https://github.com/100savage/Savage-Blocker/blob/main/savage_blocker_2.0_all.deb).
2. **Install**:
   ```bash
   sudo dpkg -i savage-blocker_2.0_all.deb
   sudo apt-get install -f  # Resolve dependencies if needed
   ```
   The Savage Blocker app will appear in the "Internet" section of your application menu.

### Option 2: Manual Installation

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
3. **Run the Python Script Directly**:
   ```bash
    sudo python3 usr/bin/blocker_gui.py
    ```

## Usage

### GUI Mode (Default)
```bash
sudo python3 /usr/bin/blocker_gui.py
```
Or launch from your start menu: Internet → Savage Blocker.

The main window shows four action buttons:
- **Update Block Lists** — Choose categories and download the latest blocklists.
- **Add a Website to Block** — Enter a domain to add to your custom block list.
- **Unblock a Website** — Remove a domain from the block list.
- **Disable All Blocking** — Reset `/etc/hosts` to default (no blocking).

Bottom bar controls:
- **Switch to Light/Dark mode** — Toggle the theme.
- **Enable/Disable Monthly Auto-Update** — Activate scheduled updates. You will be prompted to select which categories to include.
- **Exit** — Close the application.

### CLI Mode
```bash
sudo python3 /usr/bin/blocker_gui.py --update              # Update all categories
sudo python3 /usr/bin/blocker_gui.py --update ads porn      # Update specific categories
sudo python3 /usr/bin/blocker_gui.py --add example.com      # Block a domain
sudo python3 /usr/bin/blocker_gui.py --remove example.com   # Unblock a domain
sudo python3 /usr/bin/blocker_gui.py --reset                # Disable all blocking
sudo python3 /usr/bin/blocker_gui.py --setup                # Create data directory and files
sudo python3 /usr/bin/blocker_gui.py --gui                  # Launch GUI from CLI
```

Available categories for `--update`:
`ads`, `ransomware`, `tracking`, `porn`, `gambling`, `social`, `bitcoin`

**Tip**: Run monthly to keep blocklists updated. Enable **Monthly Auto-Update** in the GUI to automate this.

## Auto-Update Details

When you enable **Monthly Auto-Update** from the GUI:
1. A category selection dialog appears — choose exactly which categories to include.
2. Your selections are saved to `/usr/share/blocker/auto-update-categories`.
3. A cron script is installed at `/etc/cron.monthly/savage-blocker`.
4. Cron runs the script automatically once per month with your chosen categories.

To change categories later, disable auto-update and re-enable it — the category dialog will appear again.

Disabling auto-update removes the cron script but preserves your category selection file in case you re-enable it later.

## Blocklist Sources

- [StevenBlack Hosts](https://github.com/StevenBlack/hosts)
- [Blocklist Project](https://blocklistproject.github.io/Lists)
- [NoCoin Adblock List](https://github.com/hoshsadiq/adblock-nocoin-list)
- [Anti-WebMiner](https://github.com/greatis/Anti-WebMiner)

## Logging and Troubleshooting

- **GUI Log Viewer**: Scrollable log output is shown in the main window.
- **Debug Log**: All operations are logged to `/tmp/savage-blocker.log`.
- **CLI Troubleshooting**:
  ```bash
  sudo python3 /usr/bin/blocker_gui.py --update 2>&1 | tee /tmp/savage-blocker-output.log
  ```

## Changelog

### Version 2.0 (June 2026)
- **New Python 3 GUI**: Complete rewrite with native tkinter interface.
- **Dark/Light Theme**: Toggle between dark and light themes on the fly. All dialogs and popups match the selected theme.
- **Monthly Auto-Update**: Enable scheduled cron.monthly updates with per-category selection.
- **Custom Extra Block List**: Persisted custom domains at `/usr/share/blocker/extra`.
- **Threaded Operations**: Downloads and processing run in background threads.
- **Real-Time Progress**: Progress bar and status updates during all operations.
- **Built-in Log Viewer**: Scrollable log output integrated into the main window.
- **Internet Connectivity Check**: Verifies network before downloading.
- **Environment Checks**: Warnings for unsupported OS and missing root privileges.
- **Deduplication**: Removes duplicate domains across overlapping blocklist sources.
- **Improved Error Handling**: Comprehensive error handling with user-friendly dialog messages.
- **CLI Support**: Full command-line interface with `--update`, `--add`, `--remove`, `--reset`, `--setup`, and `--gui` flags.
- **Header File Management**: Formatted header with timestamp in `/etc/hosts`.
- **Debug Logging**: Detailed logging to `/tmp/savage-blocker.log`.
- **New .deb Package**: Simplified installation with automatic dependency resolution.

### Version 1.3 (April 2026)
- **New .deb Package**: Simplifies installation with dependencies and file setup.
- **Improved Timestamp**: Enhanced date format in `/etc/hosts` for better tracking of updates.
- **Improved Code**: Enhanced speed and stability.

### Version 1.2 (October 2025)
- **Improved Zenity Detection**: Explicit `/usr/bin/zenity` check for reliability.
- **Better Display Handling**: Validates `$DISPLAY=:0` for consistent GUI performance.
- **Enhanced Logging**: Detailed logs and clear error messages to `/tmp/savage-blocker.log`.
- **Remove duplicate entries**: Eliminates redundant domains from overlapping blocklist sources.
- **Sort entries**: Sorts blocked domains alphabetically in `/etc/hosts`.
- **Add timestamp to hosts file**: Includes the date of the last run as a comment.
- **Updated license to GNU GPL v3.0**.

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

© 2025-2026 100savage
