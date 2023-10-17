ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk update

RUN apk add --no-cache --update \
      curl freetype libjpeg libstdc++ openssh openssl python3 py3-cheetah \
      py3-configobj py3-mysqlclient py3-pillow py3-requests py3-six py3-usb \
      rsync rsyslog tzdata

RUN  apk add --no-cache --virtual .fetch-deps \
      file freetype-dev g++ gawk gcc git jpeg-dev libpng-dev make musl-dev \
      py3-pip py3-wheel python3-dev zlib-dev  


RUN pip3 install pyserial Cheetah3 mysqlclient pillow PyUSB requests six

RUN curl -sLo /tmp/weewx.tgz http://weewx.com/downloads/released_versions/weewx-4.10.1.tar.gz -O  && \
      cd /tmp && \
      tar zxvf /tmp/weewx.tgz && \
      cd weewx-* ; ./setup.py build ; ./setup.py install --no-prompt

RUN curl -sLo /tmp/mqtt.tgz https://github.com/eclipse/paho.mqtt.python/archive/v1.6.1.tar.gz  && \
      cd /tmp && \
      tar zxvf /tmp/mqtt.tgz && \
      cd paho.mqtt.python-* ; sudo python3 setup.py build ; sudo python3 setup.py install

RUN curl -sLo /tmp/weewx-mqtt.zip https://github.com/matthewwall/weewx-mqtt/archive/master.zip  && \
      cd /tmp && \
      /home/weewx/bin/wee_extension --install weewx-mqtt.zip

RUN curl -sLo /tmp/weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip && \
      cd /tmp && \
      /home/weewx/bin/wee_extension --install weewx-interceptor.zip


# Copy data for add-on
COPY run.sh /
RUN chmod 777 /run.sh

ENTRYPOINT  [ "/run.sh" ]
