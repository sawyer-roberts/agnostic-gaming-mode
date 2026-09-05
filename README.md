# Agnostic Gaming Mode (AGM)
Agnostic Gaming Mode uses a custom Gamescope Session that spoofs SteamOS to allow access to all features of Gaming Mode on CachyOS.

Agnostic Gaming Mode is designed to work on any flavor of CachyOS but can work on other distributions.
Improved support for other distributions will be added in the future but manual configuration may be required in the meantime depending on the distribution.

## Online Installation:

Download and extract the newest version from Releases and run the install script for your package manager:

pacman:
```
cd agnostic-gaming-mode
chmod 755 install-pacman.sh
./install-pacman.sh
```

apt:
```
cd agnostic-gaming-mode
chmod 755 install-apt.sh
./install-apt.sh
```

**After Installation, Agnostic Gaming Mode will appear as a new session option on your log-in screen.**

### Important Notes:
All features of AGM may not work on Stable Release Distributions (Old, Stable Packages) as some features rely on the latest versions of packages. This not affect the core functions of AGM but it is important to be aware of it.
