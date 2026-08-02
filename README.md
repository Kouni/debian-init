# debian-init

Debian post-installation initialization script.

## Features

- Disable automatic installation of recommended and suggested APT packages.
- Non-interactively configure system locales via `dpkg-reconfigure`:
  - Enable `zh_TW.UTF-8`, `en_US.UTF-8`, and `C.UTF-8`
  - Set default system locale to `C.UTF-8`
  - Purge unselected locales to minimize disk usage

## Usage

```bash
sudo bash setup.sh
```
