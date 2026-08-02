# debian-init

Debian post-installation initialization script.

## Features

- Disable automatic installation of recommended and suggested APT packages.
- Disable APT PDiffs to prevent delta patch index errors.
- Non-interactively configure system locales via `dpkg-reconfigure`:
  - Enable `zh_TW.UTF-8`, `en_US.UTF-8`, and `C.UTF-8`
  - Set default system locale to `C.UTF-8`
  - Purge unselected locales to minimize disk usage
- **Idempotent Execution**: Pre-checks settings and skips steps if already applied.
- **Status Summary Output**: Displays `[OK]` (applied) or `[SKIP]` (already satisfied).

## Quick Start (One-Line Execution)

### Recommended (`curl`)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Kouni/debian-init/main/init.sh)"
```

### Alternative (`wget`)

```bash
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/Kouni/debian-init/main/init.sh)"
```
