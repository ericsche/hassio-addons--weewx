#!/usr/bin/env bashio
bashio::log.info "Preparing to start..."

CONFIG_PATH=/data/options.json

LATITUDE="$(jq --raw-output '.latitude' $CONFIG_PATH)"
LONGITUDE="$(jq --raw-output '.longitude' $CONFIG_PATH)"
ALTITUDE="$(jq --raw-output '.altitude' $CONFIG_PATH)"
ALTITUDEUNIT="$(jq --raw-output '.altitudeUnit' $CONFIG_PATH)"
LOCATION="$(jq --raw-output '.location' $CONFIG_PATH)"
UNITS="$(jq --raw-output '.units' $CONFIG_PATH)"

export WEEWX_DATA="$(bashio::config 'data_path')"

# Ensure PYTHONPATH includes the user module directory so weewxd can find user.* extensions
export PYTHONPATH="/root/weewx-data/bin:${PYTHONPATH:-}"

# --- Step 1: Create station config if it doesn't exist ---
if ! bashio::fs.file_exists "$WEEWX_DATA/weewx.conf"; then
    mkdir -p "$WEEWX_DATA" || bashio::exit.nok "Could not create $WEEWX_DATA"

    bashio::log.info "Create default config..."
    /opt/weewx-venv/bin/weectl station create \
        --driver=weewx.drivers.simulator \
        --latitude=$LATITUDE --longitude=$LONGITUDE \
        --altitude=$ALTITUDE,$ALTITUDEUNIT \
        --location="$LOCATION" --units=$UNITS \
        --no-prompt \
        --config=$WEEWX_DATA/weewx.conf \
        --sqlite-root=$WEEWX_DATA/archive \
        --html-root=$WEEWX_DATA/public_html \
        --skin-root=$WEEWX_DATA/skins
fi

# --- Step 2: Install extensions (idempotent, run every start) ---

# Install neowx-material skin
if ! grep -q "neowx-material" "$WEEWX_DATA/weewx.conf"; then
    bashio::log.info "Installing neowx-material skin..."
    /opt/weewx-venv/bin/weectl extension install \
        https://github.com/neoground/neowx-material/releases/download/1.11/neowx-material-1.11.zip \
        --yes --config=$WEEWX_DATA/weewx.conf
fi

# Copy EN and FR language files for neowx-material skin
if [ -d "$WEEWX_DATA/skins/neowx-material" ]; then
    mkdir -p "$WEEWX_DATA/skins/neowx-material/lang"
    cp -f /opt/weewx-lang/en.conf "$WEEWX_DATA/skins/neowx-material/lang/en.conf"
    cp -f /opt/weewx-lang/fr.conf "$WEEWX_DATA/skins/neowx-material/lang/fr.conf"
    bashio::log.info "Installed EN and FR language files for neowx-material skin"
fi

# Install ecowittcustom driver/extension
if ! grep -q "ecowittcustom" "$WEEWX_DATA/weewx.conf"; then
    bashio::log.info "Installing ecowittcustom extension..."
    /opt/weewx-venv/bin/weectl extension install \
        https://github.com/WernerKr/Ecowitt-or-DAVIS-stations-and-Season-skin/raw/refs/heads/main/weewx-ecowittcustom.zip \
        --yes --config=$WEEWX_DATA/weewx.conf
fi

# Ensure [Ecowittcustom] section exists in weewx.conf (the extension installer should add it,
# but if it didn't, add a minimal one so weewxd can find the driver config)
if ! grep -q '^\[Ecowittcustom\]' "$WEEWX_DATA/weewx.conf"; then
    bashio::log.info "Adding [Ecowittcustom] driver section to weewx.conf..."
    cat >> "$WEEWX_DATA/weewx.conf" <<'EOF'

[Ecowittcustom]
    # This section is for the network traffic ecowittcustom driver.
    driver = user.ecowittcustom
    device_type = ecowitt-client
    port = 8083
    iface = eth0
EOF
fi

# Install SeasonsEcowitt skin
if [ ! -d "$WEEWX_DATA/skins/SeasonsEcowitt" ]; then
    bashio::log.info "Installing SeasonsEcowitt skin..."
    curl -sL -o /tmp/SeasonsEcowitt.zip \
        https://github.com/WernerKr/Ecowitt-or-DAVIS-stations-and-Season-skin/raw/refs/heads/main/skins/SeasonsEcowitt.zip
    unzip -qo /tmp/SeasonsEcowitt.zip -d "$WEEWX_DATA/skins/"
    rm -f /tmp/SeasonsEcowitt.zip
fi

# Add SeasonsEcowitt report to weewx.conf
if ! grep -q "SeasonsEcowitt" "$WEEWX_DATA/weewx.conf"; then
    bashio::log.info "Adding SeasonsEcowitt report config..."
    sed -i '/\[\[SeasonsReport\]\]/i\    [[SeasonsEcowitt]]\n        skin = SeasonsEcowitt\n        enable = true\n        lang = en\n        HTML_ROOT = public_html/ecowitt\n' "$WEEWX_DATA/weewx.conf"
fi

# --- Step 3: Apply station settings via sed ---
sed -i "s/station_type = Simulator/station_type = Ecowittcustom/g" "$WEEWX_DATA/weewx.conf"
sed -i "s/latitude = .*/latitude = $LATITUDE/g" "$WEEWX_DATA/weewx.conf"
sed -i "s/longitude = .*/longitude = $LONGITUDE/g" "$WEEWX_DATA/weewx.conf"
sed -i "s/location = .*/location = $LOCATION/g" "$WEEWX_DATA/weewx.conf"
sed -i 's/archive_interval = 300/archive_interval = 60/g' "$WEEWX_DATA/weewx.conf"
sed -i 's/log_success = True/log_success = False/g' "$WEEWX_DATA/weewx.conf"
sed -i 's/week_start = 6/week_start = 0/g' "$WEEWX_DATA/weewx.conf"

# --- Step 4: Start WeeWX ---
bashio::log.info "Starting Weewx..."
/opt/weewx-venv/bin/weewxd --config=$WEEWX_DATA/weewx.conf