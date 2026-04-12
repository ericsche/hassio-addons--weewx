ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:9.3.0
FROM $BUILD_FROM

ENV LANG=fr_FR.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-pip python3-venv build-essential libpython3-dev \
        curl unzip nginx locales \
    && sed -i '/fr_FR.UTF-8/s/^# //' /etc/locale.gen \
    && locale-gen fr_FR.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/weewx-venv
ENV PATH="/opt/weewx-venv/bin:$PATH"
ENV PYTHONPATH="/root/weewx-data/bin"

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
        wheel configobj libpcap pyserial pyephem six weewx

# ---------------------------------------------------------------------------
# Build-time setup: create station, install extensions, place driver files
# (syslog warnings during weectl are non-fatal — no /dev/log in build env)
# ---------------------------------------------------------------------------

# 1. Create default WeeWX station (provides bin/user/, skins/, config template)
RUN weectl station create \
        --driver=weewx.drivers.simulator \
        --latitude=0 --longitude=0 \
        --altitude=0,meter \
        --location="Home" --units=metricwx \
        --no-prompt 2>&1 \
    && test -f /root/weewx-data/weewx.conf

# 2. Install neowx-material skin (seehase fork — actively maintained, 11 languages)
RUN weectl extension install \
        https://github.com/seehase/neowx-material/archive/refs/heads/master.zip \
        --yes 2>&1 \
    && test -d /root/weewx-data/skins/neowx-material

# 3. Install ecowittcustom driver via official zip package
RUN curl -fsSL -o /tmp/weewx-ecowittcustom.zip \
        "https://github.com/WernerKr/Ecowitt-or-DAVIS-stations-and-Season-skin/raw/refs/heads/main/weewx-ecowittcustom.zip" \
    && weectl extension install /tmp/weewx-ecowittcustom.zip --yes 2>&1 \
    && rm -f /tmp/weewx-ecowittcustom.zip \
    && test -s /root/weewx-data/bin/user/ecowittcustom.py

# 4. Fix logging: use console handler instead of syslog (no /dev/log in container)
COPY logging-patch.py /opt/logging-patch.py
COPY report-patch.py /opt/report-patch.py
RUN python3 /opt/logging-patch.py /root/weewx-data/weewx.conf

COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /
RUN chmod 755 /run.sh

CMD [ "/run.sh" ]
