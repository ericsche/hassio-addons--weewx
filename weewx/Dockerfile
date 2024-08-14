ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y wget gnupg python3-pip python3-venv python3-serial 

RUN wget -qO - https://weewx.com/keys.html | gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg

RUN echo "deb [arch=all] https://weewx.com/apt/python3 buster main" | tee /etc/apt/sources.list.d/weewx.list

RUN apt-get update && apt-get install -y weewx

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"


RUN pip install paho-mqtt==1.6.1


RUN weectl extension install https://github.com/matthewwall/weewx-mqtt/archive/master.zip 

RUN weectl extension install https://github.com/matthewwall/weewx-interceptor/archive/master.zip

# Copy data for add-on
COPY run.sh /
RUN chmod 777 /run.sh

CMD [ "/run.sh" ]
