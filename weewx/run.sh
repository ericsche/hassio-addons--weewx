#!/usr/bin/env bashio
bashio::log.info "Preparing to start..."

CONFIG_PATH=/data/options.json

LATITUDE="$(jq --raw-output '.latitude' $CONFIG_PATH)"
LONGITUDE="$(jq --raw-output '.longitude' $CONFIG_PATH)"
ALTITUDE="$(jq --raw-output '.altitude' $CONFIG_PATH)"
ALTITUDEUNIT="$(jq --raw-output '.altitudeUnit' $CONFIG_PATH)"
LOCATION="$(jq --raw-output '.location' $CONFIG_PATH)"
UNITS="$(jq --raw-output '.units' $CONFIG_PATH)"

WEEWX_DATA="$(bashio::config 'data_path')"

# --- First run: copy pre-built config from image ---
if ! bashio::fs.file_exists "$WEEWX_DATA/weewx.conf"; then
    mkdir -p "$WEEWX_DATA"
    bashio::log.info "First run: copying pre-built configuration..."
    cp /root/weewx-data/weewx.conf "$WEEWX_DATA/weewx.conf"
fi

# --- Force WEEWX_ROOT to the image path (where bin/user/ and skins/ live) ---
sed -i 's|^WEEWX_ROOT =.*|WEEWX_ROOT = /root/weewx-data|' "$WEEWX_DATA/weewx.conf"

# --- Symlink persistent storage into WEEWX_ROOT ---
# Database and HTML output persist in /config/weewx/ via symlinks
mkdir -p "$WEEWX_DATA/archive" "$WEEWX_DATA/public_html"
rm -rf /root/weewx-data/archive /root/weewx-data/public_html
ln -sf "$WEEWX_DATA/archive" /root/weewx-data/archive
ln -sf "$WEEWX_DATA/public_html" /root/weewx-data/public_html

# --- Fix logging: use console instead of syslog (no /dev/log in container) ---
python3 /opt/logging-patch.py "$WEEWX_DATA/weewx.conf"

# --- Ensure [Ecowittcustom] section exists ---
if ! grep -q '^\[Ecowittcustom\]' "$WEEWX_DATA/weewx.conf"; then
    bashio::log.info "Adding [Ecowittcustom] driver section..."
    cat >> "$WEEWX_DATA/weewx.conf" <<'EOF'

[Ecowittcustom]
    driver = user.ecowittcustom
    device_type = ecowitt-client
    port = 8083
    iface = eth0
EOF
fi

# --- Apply station settings ---
sed -i "s/station_type = Simulator/station_type = Ecowittcustom/g" "$WEEWX_DATA/weewx.conf"
sed -i "s/latitude = .*/latitude = $LATITUDE/g" "$WEEWX_DATA/weewx.conf"
sed -i "s/longitude = .*/longitude = $LONGITUDE/g" "$WEEWX_DATA/weewx.conf"
sed -i "s/location = .*/location = $LOCATION/g" "$WEEWX_DATA/weewx.conf"
sed -i 's/archive_interval = 300/archive_interval = 60/g' "$WEEWX_DATA/weewx.conf"
sed -i 's/log_success = True/log_success = False/g' "$WEEWX_DATA/weewx.conf"
sed -i 's/week_start = 6/week_start = 0/g' "$WEEWX_DATA/weewx.conf"

# --- Start WeeWX ---
bashio::log.info "Starting Weewx..."
exec /opt/weewx-venv/bin/weewxd --config="$WEEWX_DATA/weewx.conf"