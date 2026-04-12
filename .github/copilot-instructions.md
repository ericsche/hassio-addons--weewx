# WeeWX Home Assistant Add-on — Copilot Instructions

## Project overview

Home Assistant add-on for WeeWX weather station software, running inside a Docker container with s6-overlay on debian-base.

- **WeeWX 5.x** installed in `/opt/weewx-venv` (Python venv)
- **WEEWX_ROOT**: `/root/weewx-data` (inside image)
- **Persistent config**: `/config/weewx/` (mapped from HA)
- **Driver**: ecowittcustom (Ecowitt HTTP protocol on port 8083)
- **Skin**: neowx-material (seehase fork)

## Key files

| File | Purpose |
|------|---------|
| `weewx/Dockerfile` | Docker build — installs weewx, extensions, skins at **build time** |
| `weewx/run.sh` | Runtime startup — copies config on first run, applies settings, starts weewxd |
| `weewx/config.json` | HA add-on metadata — version, ports, options schema |
| `weewx/build.yaml` | HA build config |

## Rules

- **Every commit must bump the version** in `weewx/config.json` (field `"version"`). Increment the patch number (e.g. `1.0.35` → `1.0.36`). After bumping, always `git add -A`, `git commit`, and `git push`.
- Extensions and skins are installed at Docker **build time**, not at runtime.
- The `ecowittcustom.py` driver is installed via the official `weewx-ecowittcustom.zip` package using `weectl extension install`.
- No syslog in the container — use console logging (`logging.StreamHandler` to stdout).
- Database and HTML output persist in `/config/weewx/` via symlinks; skins and user modules live in the image.
- Use `sed` for config patching at runtime, not `weectl station reconfigure` (avoids driver import issues).

## Architecture notes

- Container filesystem is **ephemeral** — everything in `/root/weewx-data/` resets on rebuild.
- `/config/weewx/` is persistent HA storage (mapped via `config:rw`).
- `PYTHONPATH="/root/weewx-data/bin"` is set so weewxd can find `user.*` modules.
