ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# prereq for Docker and install
RUN apt-get update
RUN apt-get install -y wget sudo gpg \
         supervisor tzdata jq

RUN sudo apt-get install -y python3-configobj python3-cheetah python3-pil python3-usb python3-setuptools python3-pip 

# Add Weewx repo for intall
RUN wget -qO - https://weewx.com/keys.html | sudo gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg
RUN wget -qO - https://weewx.com/apt/weewx-python3.list | sudo tee /etc/apt/sources.list.d/weewx.list
RUN sudo apt-get update

# Install Weewx
RUN sudo apt-get install -y weewx


# Install MQTT Addin
RUN sudo pip3 install paho-mqtt
RUN wget -O /tmp/weewx-mqtt.zip https://github.com/matthewwall/weewx-mqtt/archive/master.zip \
      cd /tmp && \
      /usr/bin/wee_extension --install weewx-mqtt.tgz


# Install addons Interceptor, WCould, OWM
RUN wget -O /tmp/weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip \
      cd /tmp && \
      /usr/bin/wee_extension --install weewx-interceptor.zip

RUN wget -O /tmp/weewx-wcloud.zip https://github.com/matthewwall/weewx-wcloud/archive/master.zip \
      cd /tmp && \
      /usr/bin/wee_extension --install weewx-wcloud.zip

RUN wget -O /tmp/weewx-owm.zip https://github.com/matthewwall/weewx-owm/archive/master.zip \
      cd /tmp && \
      /usr/bin/wee_extension --install weewx-owm.zip



# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
