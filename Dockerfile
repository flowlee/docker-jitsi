FROM debian:latest
MAINTAINER Florian Strasser <flowlee@gmx.net>
ENV DEBIAN_FRONTEND noninteractive

ENV NAT 1
ENV HOSTNAME meet.example.com

RUN apt-get update && \
	apt-get install -y wget gnupg2 debconf-utils

# set values for noninteractive install
RUN echo "jitsi-meet-web-config jitsi-meet/cert-choice select Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)" | debconf-set-selections
RUN echo "jitsi-meet-web-config jitsi-videobridge/jvb-hostname string $HOSTNAME" | debconf-set-selections

# install jitsi
RUN echo 'deb http://download.jitsi.org unstable/' >> /etc/apt/sources.list && \
	wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add - && \
	apt-get update && \
	apt-get -y --no-install-recommends install jitsi-meet && \
	apt-get clean

# delete secrets from debconf
RUN echo RESET jicofo/jicofosecret | debconf-communicate jitsi-meet-prosody && \
	echo RESET jitsi-videobridge/jvbsecret | debconf-communicate jitsi-meet-prosody && \
	echo RESET jitsi-meet-prosody/turn-secret | debconf-communicate jitsi-meet-prosody && \
	echo RESET jicofo/jicofo-authpassword | debconf-communicate jitsi-meet-prosody

# delete config files
RUN rm /etc/jitsi/videobridge/config && \
	rm /etc/jitsi/videobridge/sip-communicator.properties && \
	rm /etc/jitsi/jicofo/config && \
	rm /etc/jitsi/jicofo/sip-communicator.properties && \
	rm /etc/jitsi/meet/*-config.js && \
	rm -rf /var/lib/prosody/*

# prepare log file
RUN touch /var/log/jitsi/jvb.log && \
	chown jvb:jitsi /var/log/jitsi/jvb.log

# ports to forward: 443 5280 10000
EXPOSE 80 443 4443 5280 5347
EXPOSE 10000/udp

# volume
VOLUME /config

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD /run.sh
