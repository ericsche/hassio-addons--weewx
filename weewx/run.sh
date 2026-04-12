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

# --- Config persistence ---
# weewxd always runs from /root/weewx-data/ so WEEWX_ROOT stays correct
# and bin/user/ modules are found. Persistent copy lives in /config/weewx/.
if bashio::fs.file_exists "$WEEWX_DATA/weewx.conf"; then
    bashio::log.info "Restoring persistent configuration..."
    cp "$WEEWX_DATA/weewx.conf" "$WEEWX_CONF"
else
    bashio::log.info "First run: initializing persistent configuration..."
fi

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

# --- Ensure neowx-material skin report is configured ---
if ! grep -q 'neowx-material' "$WEEWX_CONF"; then
    bashio::log.info "Adding neowx-material report section..."
    sed -i '/^\[StdReport\]/,/^\[/{
        /^\[StdReport\]/a\
\    [[neowx-material]]\
\        skin = neowx-material\
\        enable = true\
\        lang = fr\
\        unit_system = metricwx
    }' "$WEEWX_CONF"
fi

# --- Apply station settings ---
sed -i "s/station_type = Simulator/station_type = Ecowittcustom/g" "$WEEWX_CONF"
sed -i "s/latitude = .*/latitude = $LATITUDE/g" "$WEEWX_CONF"
sed -i "s/longitude = .*/longitude = $LONGITUDE/g" "$WEEWX_CONF"
sed -i "s/location = .*/location = $LOCATION/g" "$WEEWX_CONF"
sed -i 's/archive_interval = 300/archive_interval = 60/g' "$WEEWX_CONF"
sed -i 's/log_success = True/log_success = False/g' "$WEEWX_CONF"
sed -i 's/week_start = 6/week_start = 0/g' "$WEEWX_CONF"

# --- Save patched config to persistent storage ---
cp "$WEEWX_CONF" "$WEEWX_DATA/weewx.conf"

# --- Start nginx to serve reports via HA ingress ---
nginx

# --- Start WeeWX (from image path — WEEWX_ROOT = /root/weewx-data) ---
bashio::log.info "Starting Weewx..."
exec /opt/weewx-venv/bin/weewxd --config="$WEEWX_CONF"