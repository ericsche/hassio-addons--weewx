#!/usr/bin/env bashio
bashio::log.info "Preparing to start..."

CONFIG_PATH=/data/options.json
DATA_PATH=$(bashio::config 'data_path')




DRIVER="$(jq --raw-output '.driver' $CONFIG_PATH)"
LATITUDE="$(jq --raw-output '.latitude' $CONFIG_PATH)"
LONGITUDE="$(jq --raw-output '.longitude' $CONFIG_PATH)"
ALTITUDE="$(jq --raw-output '.altitude' $CONFIG_PATH)"
ALTITUDEUNIT="$(jq --raw-output '.altitudeUnit' $CONFIG_PATH)"
LOCATION="$(jq --raw-output '.location' $CONFIG_PATH)"
UNITS="$(jq --raw-output '.units' $CONFIG_PATH)"


export WEEWX_DATA="$(bashio::config 'data_path')"
if ! bashio::fs.file_exists "$WEEWX_DATA/weewx.conf"; then
    mkdir -p "$WEEWX_DATA" || bashio::exit.nok "Could not create $WEEWX_DATA"

bashio::log.info "Create default config..."
/opt/weewx-venv/bin/weectl station create --driver=$DRIVER --latitude=$LATITUDE --longitude=$LONGITUDE --altitude=$ALTITUDE,$ALTITUDEUNIT --location=$LOCATION --units=$UNITS --no-prompt --config=$WEEWX_DATA/weewx.conf --sqlite-root=$WEEWX_DATA/archive --html-root=$WEEWX_DATA/public_html  --skin-root=$WEEWX_DATA/skins  --no-prompt

    # Install interceptor extension only if not already installed
    if ! grep -q "interceptor" "$WEEWX_DATA/weewx.conf"; then
        bashio::log.info "Installing interceptor extension..."
        /opt/weewx-venv/bin/weectl extension install https://github.com/matthewwall/weewx-interceptor/archive/master.zip --config=$WEEWX_DATA/weewx.conf
    fi

    # Install neowx-material skin only if not already installed
    if ! grep -q "neowx-material" "$WEEWX_DATA/weewx.conf"; then
        bashio::log.info "Installing neowx-material skin..."
        /opt/weewx-venv/bin/weectl extension install https://github.com/neoground/neowx-material/archive/master.zip --config=$WEEWX_DATA/weewx.conf
    fi

    # Copy EN and FR language files for neowx-material skin
    if [ -d "$WEEWX_DATA/skins/neowx-material" ]; then
        mkdir -p "$WEEWX_DATA/skins/neowx-material/lang"
        cp -f /opt/weewx-lang/en.conf "$WEEWX_DATA/skins/neowx-material/lang/en.conf"
        cp -f /opt/weewx-lang/fr.conf "$WEEWX_DATA/skins/neowx-material/lang/fr.conf"
        bashio::log.info "Installed EN and FR language files for neowx-material skin"
    fi

    # Install ecowittcustom driver/extension only if not already installed
    if ! grep -q "ecowittcustom" "$WEEWX_DATA/weewx.conf"; then
        bashio::log.info "Installing ecowittcustom extension..."
        /opt/weewx-venv/bin/weectl extension install https://github.com/WernerKr/Ecowitt-or-DAVIS-stations-and-Season-skin/raw/refs/heads/main/weewx-ecowittcustom.zip --config=$WEEWX_DATA/weewx.conf
    fi

    # Install SeasonsEcowitt skin only if not already installed
    if [ ! -d "$WEEWX_DATA/skins/SeasonsEcowitt" ]; then
        bashio::log.info "Installing SeasonsEcowitt skin..."
        curl -sL -o /tmp/SeasonsEcowitt.zip https://github.com/WernerKr/Ecowitt-or-DAVIS-stations-and-Season-skin/raw/refs/heads/main/skins/SeasonsEcowitt.zip
        unzip -qo /tmp/SeasonsEcowitt.zip -d "$WEEWX_DATA/skins/"
        rm -f /tmp/SeasonsEcowitt.zip
    fi

    # Add SeasonsEcowitt report to weewx.conf if not already present
    if ! grep -q "SeasonsEcowitt" "$WEEWX_DATA/weewx.conf"; then
        bashio::log.info "Adding SeasonsEcowitt report config..."
        sed -i '/\[\[SeasonsReport\]\]/i\    [[SeasonsEcowitt]]\n        skin = SeasonsEcowitt\n        enable = true\n        lang = en\n        HTML_ROOT = public_html/ecowitt\n' "$WEEWX_DATA/weewx.conf"
    fi

fi
/opt/weewx-venv/bin/weectl station reconfigure --driver=$DRIVER --latitude=$LATITUDE --longitude=$LONGITUDE --altitude=$ALTITUDE,$ALTITUDEUNIT --location=$LOCATION --units=$UNITS --no-prompt --config=$WEEWX_DATA/weewx.conf --sqlite-root=$WEEWX_DATA/archive --html-root=$WEEWX_DATA/public_html  --skin-root=$WEEWX_DATA/skins  --no-prompt

sed -i 's/archive_interval = 300/archive_interval = 60/g' $WEEWX_DATA/weewx.conf

sed -i 's/log_success = True/log_success = False/g' $WEEWX_DATA/weewx.conf
sed -i 's/week_start = 6/week_start = 0/g' $WEEWX_DATA/weewx.conf


bashio::log.info "Starting Weewx..."

/opt/weewx-venv/bin/weewxd --config=$WEEWX_DATA/weewx.conf