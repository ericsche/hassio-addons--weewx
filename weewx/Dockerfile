ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y sqlite3 wget gnupg2 python-is-python3 python3-pip python3-configobj python3-cheetah python3-pil python3-usb python3-setuptools

RUN wget -qO - https://weewx.com/keys.html | gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg
RUN wget -qO - https://weewx.com/apt/weewx-python3.list |  tee /etc/apt/sources.list.d/weewx.list


RUN apt-get update && apt-get install -y weewx

         
RUN pip3 install pyserial
RUN pip3 install paho-mqtt


RUN wget https://github.com/matthewwall/weewx-mqtt/archive/master.zip -O /tmp/weewx-mqtt.zip && \
      cd /tmp && \
      /home/weewx/bin/wee_extension --install weewx-mqtt.zip

RUN wget -O /tmp/weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip && \
      cd /tmp && \
      /home/weewx/bin/wee_extension --install weewx-interceptor.zip


# Copy data for add-on
COPY run.sh /
RUN chmod 777 /run.sh

CMD [ "/run.sh" ]
