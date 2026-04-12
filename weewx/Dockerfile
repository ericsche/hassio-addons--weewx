ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:9.3.0
FROM $BUILD_FROM

ENV LANG=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-pip python3-venv build-essential libpython3-dev \
        curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/weewx-venv

ENV PATH="/opt/weewx-venv/bin:$PATH"

RUN /opt/weewx-venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/weewx-venv/bin/pip install --no-cache-dir \
        wheel configobj libpcap pyserial pyephem six weewx

# Copy data for add-on
COPY run.sh /
RUN chmod 755 /run.sh

CMD [ "/run.sh" ]
