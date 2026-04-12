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

fi
/opt/weewx-venv/bin/weectl station reconfigure --driver=$DRIVER --latitude=$LATITUDE --longitude=$LONGITUDE --altitude=$ALTITUDE,$ALTITUDEUNIT --location=$LOCATION --units=$UNITS --no-prompt --config=$WEEWX_DATA/weewx.conf --sqlite-root=$WEEWX_DATA/archive --html-root=$WEEWX_DATA/public_html  --skin-root=$WEEWX_DATA/skins  --no-prompt

sed -i 's/archive_interval = 300/archive_interval = 60/g' $WEEWX_DATA/weewx.conf

sed -i 's/log_success = True/log_success = False/g' $WEEWX_DATA/weewx.conf
sed -i 's/week_start = 6/week_start = 0/g' $WEEWX_DATA/weewx.conf


bashio::log.info "Starting Weewx..."

/opt/weewx-venv/bin/weewxd --config=$WEEWX_DATA/weewx.conf