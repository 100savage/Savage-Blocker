# The Savage Blocker

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Version: 1.2](https://img.shields.io/badge/Version-1.2-green.svg)
![Platform: Debian/Ubuntu](https://img.shields.io/badge/Platform-Debian%2FUbuntu-orange.svg)

The Savage Blocker is a powerful tool for Debian-based Linux systems (e.g., Debian/Ubuntu/Linux Mint) that blocks unwanted websites, including ads, malware, ransomware, tracking, pornography, gambling, social media, and Bitcoin miners. By updating `/etc/hosts` with curated blocklists, it enhances privacy, reduces distractions, saves bandwidth, and speeds up web browsing. Version 1.2 introduces significant reliability improvements, and a new `.deb` package simplifies installation.

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
- **User-Friendly GUI**: Zenity-based menus for easy interaction.
- **Easy Installation**: Available as a `.deb` package.

## Screenshots


![Menu 1](https://raw.githubusercontent.com/100savage/Savage-Blocker/main/images/menu1.png)
![Menu 2](https://raw.githubusercontent.com/100savage/Savage-Blocker/main/images/menu2.png)
![Menu 3](https://raw.githubusercontent.com/100savage/Savage-Blocker/main/images/menu3.png)

## Installation

### Option 1: Install via .deb Package (Recommended)
1. **Download the Package**:
   - Get `savage-blocker_1.2_all.deb` from [Releases](https://github.com/100savage/Savage-Blocker/blob/main/savage_blocker_1.2_all.deb).
2. **Install**:
   ```bash
   sudo dpkg -i savage-blocker_1.2_all.deb
   sudo apt-get install -f  # Resolve dependencies if needed
   ```
   The Savage Blocker app will appear in the "Internet section" of your menu
  
### Option 2: Manual Installation
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
   chmod +x savage_blocker.sh
   ```

## If using a terminal
```bash
sudo -E savage_blocker.sh  # If installed manually
```
## If installed via .deb package 
select Menu -> Internet -> Savage Blocker 

## Run the code
- **Main Menu**: Choose to launch, add/remove websites, reset blocking, or exit.
- **Blocklist Selection**: Select categories to block.
- **Debug Log**: View `/tmp/savage-blocker-$USER.log` for details.

**Tip**: If dialogs don’t appear, verify Zenity is installed and check the /tmp/savage-blocker.log for errors

Run monthly to keep blocklists updated.

## Changelog

### Version 1.2 (October 2025)
- **Improved Zenity Detection**: Explicit `/usr/bin/zenity` check for reliability.
- **Better Display Handling**: Validates `$DISPLAY=:0` for consistent GUI performance.
- **Preserved Files**: No deletion in `/usr/share/blocker`, using `/tmp` for temporary files.
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

For issues, check `/tmp/savage-blocker-$USER.log` or run:
```bash
sudo -E savage_blocker.sh 2>&1 | tee /tmp/savage-blocker-output.log
```

© 2025 100savage







