#!/bin/bash

NEW_CONFIG=0
UPDATED_CONFIG=0
NEW_HOSTNAME=0
EXISTING_NAT=0

if [ ! -d /config/jitsi ]; then
	NEW_CONFIG=1
fi

if [ ! -z "$HOSTNAME" ]; then
	OLD_HOSTNAME=$(debconf-get-selections | grep 'jicofo.*jvb-hostname' | awk '{print $NF}')
	if [ "$OLD_HOSTNAME" != "$HOSTNAME" ]; then
		NEW_HOSTNAME=1
	fi
fi

if [ "$NEW_CONFIG" -eq 1 ]; then
	cp -rp /etc/jitsi/ /config/
else
	cp -rp /config/* /etc/
fi

if [ ! -z "$(cat /etc/jitsi/videobridge/sip-communicator.properties | grep NAT_HARVESTER_PUBLIC_ADDRESS)" ]; then
	EXISTING_NAT=1
fi

if [ "$NEW_HOSTNAME" -eq 1 ]; then
	echo "jicofo jitsi-videobridge/jvb-hostname string $HOSTNAME" | debconf-set-selections
	rm /etc/jitsi/videobridge/sip-communicator.properties
	rm /etc/jitsi/meet/*-config.js
	dpkg-reconfigure jicofo
	dpkg-reconfigure jitsi-meet-web-config
	dpkg-reconfigure jitsi-meet-prosody
	dpkg-reconfigure jitsi-videobridge
	UPDATED_CONFIG=1
fi

if [ ! -z "$HOSTNAME" ] && [ "$NAT" -eq 1 ] && [ "$EXISTING_NAT" -eq 0 ]; then
	echo "org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=$HOSTNAME" >> /etc/jitsi/videobridge/sip-communicator.properties
	echo "org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)" >> /etc/jitsi/videobridge/sip-communicator.properties
	UPDATED_CONFIG=1
fi

if [ "$NEW_HOSTNAME" -eq 1 ] && [ "$NAT" -eq 1 ] && [ "$EXISTING_NAT" -eq 1 ]; then
	sed -i "s/NAT_HARVESTER_PUBLIC_ADDRESS=.*/NAT_HARVESTER_PUBLICADDRESS=$HOSTNAME/" /etc/jitsi/videobridge/sip-communicator.properties
	UPDATED_CONFIG=1
fi

if [ "$NAT" -eq 0 ] && [ "$EXISTING_NAT" -eq 1 ]; then
	sed '/^org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=/d' /etc/jitsi/videobridge/sip-communicator.properties
	sed '/^org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=/d' /etc/jitsi/videobridge/sip-communicator.properties
	UPDATED_CONFIG=1
fi

if [ "$UPDATED_CONFIG" -eq 1 ]; then
	cp -rp /etc/jitsi/ /config/
fi

if [ ! -f /config/interface_config.js ]; then
	cp -rp /usr/share/jitsi-meet/interface_config.js /config/interface_config.js
else
	cp -rp /config/interface_config.js /usr/share/jitsi-meet/interface_config.js
fi

service prosody restart
service jitsi-videobridge restart
service jicofo restart
service nginx restart

tail -f /var/log/jitsi/jvb.log