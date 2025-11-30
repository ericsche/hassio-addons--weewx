ARG BUILD_FROM=ghcr.io/hassio-addons/ubuntu-base/amd64:11.0.0
FROM $BUILD_FROM

ENV LANG=C.UTF-8

RUN apt-get update && apt-get install -y wget gnupg python3-pip python3-venv build-essential libpython3-dev

RUN wget -qO - https://weewx.com/keys.html | gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg

RUN echo "deb [arch=all] https://weewx.com/apt/python3 buster main" | tee /etc/apt/sources.list.d/weewx.list


RUN python3 -m venv /opt/weewx-venv

ENV PATH="/opt/weewx-venv/bin:$PATH"
# Upgrade pip inside the venv
RUN /opt/weewx-venv/bin/pip install --upgrade pip

# Install wheel and configobj inside the venv
RUN /opt/weewx-venv/bin/pip install wheel configobj

RUN /opt/weewx-venv/bin/pip install libpcap

RUN /opt/weewx-venv/bin/pip install pyserial

RUN /opt/weewx-venv/bin/pip install weewx

# Copy data for add-on
COPY run.sh /
RUN chmod 777 /run.sh

CMD [ "/run.sh" ]
