ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# prereq for Docker and install
RUN apt-get update
RUN apt-get install -y wget sudo gpg \
         supervisor tzdata jq

RUN sudo apt-get install -y python3-configobj python3-cheetah python3-pil python3-usb python3-setuptools python3-pip 

# Add Weewx repo for intall
RUN wget -qO - https://weewx.com/keys.html | sudo gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg
RUN wget -qO - https://weewx.com/apt/weewx-python3.list | sudo tee /etc/apt/sources.list.d/weewx.list
RUN sudo apt-get update

# Install Weewx
RUN sudo apt-get install -y weewx

# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
