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
MQTTUSER="$(jq --raw-output '.mqttUser' $CONFIG_PATH)"
MQTTPASSWORD="$(jq --raw-output '.mqttPassword' $CONFIG_PATH)"


export ZIGBEE2MQTT_DATA="$(bashio::config 'data_path')"
if ! bashio::fs.file_exists "$ZIGBEE2MQTT_DATA/weewx.conf"; then
    mkdir -p "$ZIGBEE2MQTT_DATA" || bashio::exit.nok "Could not create $ZIGBEE2MQTT_DATA"


/home/weewx/bin/wee_config --reconfigure --driver=$DRIVER --latitude=$LATITUDE --longitude=$LONGITUDE --altitude=$ALTITUDE,$ALTITUDEUNIT --location=$LOCATION --units=$UNITS --no-prompt --config=$DATA_PATH/weewx.conf

sed -i '/INSERT_SERVER_URL_HERE/ a \
\ \ \ \ \ \ \ \ topic = weather\
\ \ \ \ \ \ \ \ unit_system = US\
' /home/weewx/weewx.conf

sed -i 's/INSERT_SERVER_URL_HERE/mqtt:\/\/'$MQTTUSER':'$MQTTPASSWORD'@core-mosquitto:1883/g' /home/weewx/weewx.conf

sed -i 's/archive_interval = 300/archive_interval = 60/g' /home/weewx/weewx.conf

sed -i 's/log_success = True/log_success = False/g' /home/weewx/weewx.conf
sed -i 's/week_start = 6/week_start = 0/g' /home/weewx/weewx.conf

/home/weewx/bin/weewxd /home/weewx/weewx.conf
#sleep infinity
