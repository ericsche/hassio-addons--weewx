ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y wget gnupg python3-pip python3-venv build-essential libpython3-dev

RUN wget -qO - https://weewx.com/keys.html | gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg

RUN echo "deb [arch=all] https://weewx.com/apt/python3 buster main" | tee /etc/apt/sources.list.d/weewx.list

RUN apt-get update && apt-get install -y weewx

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Ensure wheel is installed
RUN pip install wheel

# Install python-cjson separately to identify issues
RUN pip install python-cjson

RUN pip install pyserial
RUN pip install "paho-mqtt<2.0.0"



RUN weectl extension install https://github.com/matthewwall/weewx-mqtt/archive/master.zip 

RUN weectl extension install https://github.com/matthewwall/weewx-interceptor/archive/master.zip

# Copy data for add-on
COPY run.sh /
RUN chmod 777 /run.sh

CMD [ "/run.sh" ]
