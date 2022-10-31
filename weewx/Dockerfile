ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apt-get update \
    && apt-get install -y wget sudo gpg \
    python3-configobj python3-cheetah python3-pil python3-usb python3-setuptools python3-pip \
         supervisor tzdata jq

RUN wget -qO - https://weewx.com/keys.html | sudo gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg
RUN wget -qO - https://weewx.com/apt/weewx-python3.list | sudo tee /etc/apt/sources.list.d/weewx.list


RUN sudo apt-get update

RUN sudo apt-get install -y weewx

RUN sudo pip3 install paho-mqtt

RUN wget -O /tmp/weewx-mqtt.zip https://github.com/matthewwall/weewx-mqtt/archive/master.zip \
      cd /tmp && \
      /usr/bin/wee_extension --install weewx-mqtt.tgz


# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
