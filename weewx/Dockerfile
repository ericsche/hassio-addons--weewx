ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y wget gnupg

RUN wget -qO - https://weewx.com/keys.html | gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg

RUN echo "deb [arch=all] https://weewx.com/apt/python3 buster main" | tee /etc/apt/sources.list.d/weewx.list

RUN apt-get update && apt-get install -y weewx

         
RUN pip3 install pyserial
RUN pip3 install paho-mqtt


RUN weectl extension install https://github.com/matthewwall/weewx-mqtt/archive/master.zip 

RUN weectl extension install https://github.com/matthewwall/weewx-interceptor/archive/master.zip
RUN weectl station reconfigure --no-prompt --driver=user.interceptor

# Copy data for add-on
COPY run.sh /
RUN chmod 777 /run.sh

CMD [ "/run.sh" ]
