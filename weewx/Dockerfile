ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y wget gnupg python3-pip python3-venv build-essential libpython3-dev

RUN wget -qO - https://weewx.com/keys.html | gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg

RUN echo "deb [arch=all] https://weewx.com/apt/python3 buster main" | tee /etc/apt/sources.list.d/weewx.list


RUN python3 -m venv ~/weewx-venv
ENV source ~/weewx-venv/bin/activate
RUN pip install wheel
RUN pip install configobj

RUN pip install libpcap

RUN pip install pyserial

RUN python3 -m pip install weewx

# Ensure wheel is installed




RUN weectl extension install https://github.com/matthewwall/weewx-interceptor/archive/master.zip

# Copy data for add-on
COPY run.sh /
RUN chmod 777 /run.sh

CMD [ "/run.sh" ]
