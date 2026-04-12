#!/usr/bin/env bashio
bashio::log.info "Preparing to start..."

CONFIG_PATH=/data/options.json
WEEWX_CONF=/root/weewx-data/weewx.conf

LATITUDE="$(jq --raw-output '.latitude' $CONFIG_PATH)"
LONGITUDE="$(jq --raw-output '.longitude' $CONFIG_PATH)"
ALTITUDE="$(jq --raw-output '.altitude' $CONFIG_PATH)"
ALTITUDEUNIT="$(jq --raw-output '.altitudeUnit' $CONFIG_PATH)"
LOCATION="$(jq --raw-output '.location' $CONFIG_PATH)"
UNITS="$(jq --raw-output '.units' $CONFIG_PATH)"

WEEWX_DATA="$(bashio::config 'data_path')"
mkdir -p "$WEEWX_DATA"

# --- Config: always start from the image's fresh config ---
# The image config has all extensions, skins, SKIN_ROOT etc. correctly set
# from build time. run.sh applies user settings on top. No need to persist
# weewx.conf — only database (archive/) and reports (public_html/) persist.

# --- Symlink persistent data dirs into WEEWX_ROOT ---
mkdir -p "$WEEWX_DATA/archive" "$WEEWX_DATA/public_html"
rm -rf /root/weewx-data/archive /root/weewx-data/public_html
ln -sf "$WEEWX_DATA/archive" /root/weewx-data/archive
ln -sf "$WEEWX_DATA/public_html" /root/weewx-data/public_html

# --- Fix logging: use console instead of syslog ---
python3 /opt/logging-patch.py "$WEEWX_CONF"

# --- Ensure [Ecowittcustom] section exists ---
if ! grep -q '^\[Ecowittcustom\]' "$WEEWX_CONF"; then
    bashio::log.info "Adding [Ecowittcustom] driver section..."
    cat >> "$WEEWX_CONF" <<'EOF'

[Ecowittcustom]
    driver = user.ecowittcustom
    device_type = ecowitt-client
    port = 8083
    iface = eth0
EOF
fi

# Force correct port in [Ecowittcustom] (persistent config may have old value)
sed -i '/^\[Ecowittcustom\]/,/^\[/{s/port = .*/port = 8083/}' "$WEEWX_CONF"

# --- Apply station settings ---
sed -i "s/station_type = Simulator/station_type = Ecowittcustom/g" "$WEEWX_CONF"
sed -i "s/latitude = .*/latitude = $LATITUDE/g" "$WEEWX_CONF"
sed -i "s/longitude = .*/longitude = $LONGITUDE/g" "$WEEWX_CONF"
sed -i "s/location = .*/location = $LOCATION/g" "$WEEWX_CONF"
sed -i 's/archive_interval = 300/archive_interval = 60/g' "$WEEWX_CONF"
sed -i 's/log_success = True/log_success = False/g' "$WEEWX_CONF"
sed -i 's/week_start = 6/week_start = 0/g' "$WEEWX_CONF"

# --- Disable default skins, keep only neowx-material ---
sed -i '/^\[\[SeasonsReport\]\]/,/^\[\[/{s/enable = true/enable = false/}' "$WEEWX_CONF"
sed -i '/^\[\[SmartphoneReport\]\]/,/^\[\[/{s/enable = true/enable = false/}' "$WEEWX_CONF"
sed -i '/^\[\[MobileReport\]\]/,/^\[\[/{s/enable = true/enable = false/}' "$WEEWX_CONF"
sed -i '/^\[\[StandardReport\]\]/,/^\[\[/{s/enable = true/enable = false/}' "$WEEWX_CONF"

# --- Ensure neowx-material generates to public_html root ---
# neowx-material uses lang=fr and metricwx units
sed -i '/^\[\[neowx-material\]\]/,/^\[\[/{s/enable = false/enable = true/}' "$WEEWX_CONF"

# --- Clean stale reports from persistent storage ---
# Only on first run with this version — remove old 2025 reports
if [ ! -f "$WEEWX_DATA/.reports_cleaned" ]; then
    bashio::log.info "Cleaning old reports from persistent storage..."
    find "$WEEWX_DATA/public_html" -type f -delete 2>/dev/null || true
    touch "$WEEWX_DATA/.reports_cleaned"
fi

# --- Log active report skins for debugging ---
bashio::log.info "Active report skins:"
grep -A2 '^\[\[.*\]\]' "$WEEWX_CONF" | grep -B1 'enable = true' | grep '^\[\[' || true

# --- Start nginx to serve reports via HA ingress ---
nginx

# --- Start WeeWX (from image path — WEEWX_ROOT = /root/weewx-data) ---
bashio::log.info "Starting Weewx..."
exec /opt/weewx-venv/bin/weewxd --config="$WEEWX_CONF"