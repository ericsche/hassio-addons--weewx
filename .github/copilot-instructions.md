# WeeWX Home Assistant Add-on — Copilot Instructions

## Project overview

Home Assistant add-on for WeeWX weather station software, running inside a Docker container with s6-overlay on debian-base.

- **WeeWX 5.x** installed in `/opt/weewx-venv` (Python venv)
- **WEEWX_ROOT**: `/root/weewx-data` (inside image)
- **Persistent config**: `/config/weewx/` (mapped from HA)
- **Driver**: ecowittcustom (Ecowitt HTTP protocol on port 8083)
- **Skin**: neowx-material (seehase fork)
- **Locale**: `fr_FR.UTF-8` (French date/time formatting)
- **Station**: Ecowitt GW1200A gateway

## Key files

| File | Purpose |
|------|---------|
| `weewx/Dockerfile` | Docker build — installs weewx, extensions, skins, locale at **build time** |
| `weewx/run.sh` | Runtime startup — symlinks persistent dirs, patches config, starts nginx + weewxd |
| `weewx/config.json` | HA add-on metadata — version, ports, options schema |
| `weewx/build.yaml` | HA build config |
| `weewx/logging-patch.py` | ConfigObj script — creates `[Logging]` section with console handler |
| `weewx/report-patch.py` | ConfigObj script — forces neowx-material skin, lang=fr, metricwx units |
| `weewx/nginx.conf` | Serves reports via HA ingress on port 8099 |

## Rules

- **Every commit must bump the version** in `weewx/config.json` (field `"version"`). Increment the patch number (e.g. `1.0.35` → `1.0.36`). After bumping, always `git add -A`, `git commit`, and `git push`.
- Extensions and skins are installed at Docker **build time**, not at runtime.
- The `ecowittcustom.py` driver is installed via the official `weewx-ecowittcustom.zip` package using `weectl extension install`.
- No syslog in the container — use console logging (`logging.StreamHandler` to stdout).
- Database and HTML output persist in `/config/weewx/` via symlinks; skins and user modules live in the image.
- **Use ConfigObj (Python) for config patching**, not sed, for anything inside nested `[[sections]]` — sed fails on indented ConfigObj headers.
- `sed` is fine for flat top-level values (e.g. `station_type`, `latitude`, `debug`).

## Architecture notes

- Container filesystem is **ephemeral** — everything in `/root/weewx-data/` resets on rebuild.
- `/config/weewx/` is persistent HA storage (mapped via `config:rw`).
- `PYTHONPATH="/root/weewx-data/bin"` is set so weewxd can find `user.*` modules.
- **weewx.conf is NOT persisted** — always starts fresh from the image. Only `archive/` (database) and `public_html/` (reports) persist via symlinks.
- weewxd runs with `--config=/root/weewx-data/weewx.conf` so WEEWX_ROOT resolves correctly.

## Lessons learned (hard-won debugging insights)

### ConfigObj and weewx.conf
- `logging-patch.py` uses ConfigObj to rewrite `weewx.conf` — this **destroys** changes made by `weectl extension install` (e.g. neowx-material's `skin = neowx-material` reverts to `skin = Standard`). Solution: `report-patch.py` runs after and re-applies skin settings.
- ConfigObj reorders sections when rewriting — don't assume section order is preserved.
- The `[Logging]` section does NOT exist in default weewx.conf. It must be CREATED, not edited. WeeWX's `logger.py` merges it on top of hardcoded defaults.
- `handlers` in `[Logging]` must be a Python list `['console']`, not a string `'console,'` — ConfigObj iterates strings char-by-char.

### neowx-material skin
- The extension installer sets `config={"StdReport": {"StandardReport": {"skin": "neowx-material"}}}` — it **overwrites `[[StandardReport]]`**, it does NOT create a `[[neowx-material]]` section.
- Therefore `[[StandardReport]]` must be ENABLED — it IS the neowx-material skin.
- `historygenerator3` INFO messages about `sunshineDur`/`rainDur` not found are normal — these are optional observation types.

### sed pitfalls in weewx.conf
- Section headers like `[[SeasonsReport]]` are indented (4 spaces). Using `^` anchor in sed patterns will never match.
- Piping sed through `head` causes SIGPIPE; bashio's `set -e` kills the script. Always add `|| true`.

### s6-overlay / bashio
- `run.sh` runs with `set -e` via bashio — any nonzero exit kills the container.
- Pipes like `cmd | head` can trigger SIGPIPE on the left side → script death. Always `|| true`.
- The container restarts in a loop on crash (s6-overlay), so check for "successfully stopped" messages in logs to detect startup crashes.

### Docker / HA add-on
- No `/dev/log` in the container — syslog handler fails with "Bad file descriptor".
- `nginx` needs `user root;` because it follows symlinks into `/config/weewx/` which is root-owned.
- `locale-gen` is needed for French date formatting — install `locales` package and set `LANG=fr_FR.UTF-8`.
- `log_success = False` hides ALL success log messages including report generation — don't set it when debugging.
