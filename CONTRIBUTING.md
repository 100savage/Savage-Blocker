# Contributing to The Savage Blocker

Thank you for considering contributing to The Savage Blocker, an ad-blocking tool for Debian-like systems! We welcome contributions that improve reliability, add features, or fix bugs while preserving `/usr/share/blocker` files.

## How to Contribute

1. **Report Issues**:
   - Use GitHub Issues for bugs, feature requests, or questions.
   - Provide:
     - Version (e.g., 1.2).
     - OS (e.g., Ubuntu 22.04).
     - Steps to reproduce.
     - Debug log (`/tmp/savage-blocker-$USER.log`).
     - Terminal output (`sudo -E ./savage_blocker.sh 2>&1 | tee /tmp/output.log`).
   - Search existing issues first.

2. **Submit Pull Requests**:
   - Fork the repository and create a branch (`git checkout -b fix-bug`).
   - Make changes, test thoroughly (e.g., run with `sudo -E`, check logs).
   - Ensure no files in `/usr/share/blocker` are deleted.
   - Commit with clear messages (`git commit -m "Fix permission error in data_pull"`).
   - Push and open a pull request (PR) describing changes and tests.
   - PRs are reviewed within 1-2 weeks; ping if needed.

3. **Code Style**:
   - Follow the existing bash style (e.g., use explicit paths like `/usr/bin/zenity`).
   - Add comments for new features.
   - Update README, CHANGELOG.md, or .deb control if relevant.

4. **Testing**:
   - Test on Debian/Ubuntu with Zenity.
   - Verify all menu options (launch, add/remove, reset).
   - Check file preservation (`ls -l /usr/share/blocker` before/after).
   - Run with `sudo -E` in a graphical session.

## Code of Conduct
We follow the Contributor Covenant Code of Conduct. Harassment-free participation is expected. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.

Contributions are licensed under GPL-3.0. Thank you for helping improve The Savage Blocker!
