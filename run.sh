#!/bin/bash

# regenerate secrets, set hostname

echo RESET jicofo/jicofosecret | debconf-communicate jitsi-meet-prosody
echo RESET jitsi-videobridge/jvbsecret | debconf-communicate jitsi-meet-prosody
echo RESET jitsi-meet-prosody/turn-secret | debconf-communicate jitsi-meet-prosody
echo RESET jicofo/jicofo-authpassword | debconf-communicate jitsi-meet-prosody

echo "jitsi-meet-web-config jitsi-videobridge/jvb-hostname string $HOSTNAME" | debconf-set-selections

rm /etc/jitsi/videobridge/config
rm /etc/jitsi/videobridge/sip-communicator.properties
rm /etc/jitsi/jicofo/config
rm /etc/jitsi/jicofo/sip-communicator.properties
rm /etc/jitsi/meet/*-config.js
rm -rf /var/lib/prosody/*

dpkg-reconfigure jitsi-meet-web-config
dpkg-reconfigure jitsi-videobridge2
dpkg-reconfigure jicofo
dpkg-reconfigure jitsi-meet-prosody

echo "org.jitsi.videobridge.AUTHORIZED_SOURCE_REGEXP=focus@auth.$HOSTNAME/.*" >> /etc/jitsi/videobridge/sip-communicator.properties

if [ "$NAT" -eq 1 ]; then
	sed -i "s/org.ice4j.ice.harvest.STUN_MAPPING_HARVESTER_ADDRESSES/# org.ice4j.ice.harvest.STUN_MAPPING_HARVESTER_ADDRESSES/" /etc/jitsi/videobridge/sip-communicator.properties
	echo "org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=$HOSTNAME" >> /etc/jitsi/videobridge/sip-communicator.properties
	echo "org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)" >> /etc/jitsi/videobridge/sip-communicator.properties
fi

if [ ! -f /config/interface_config.js ]; then
	cp -rp /usr/share/jitsi-meet/interface_config.js /config/interface_config.js
else
	cp -rp /config/interface_config.js /usr/share/jitsi-meet/interface_config.js
fi

service prosody restart
service jitsi-videobridge2 restart
service jicofo restart
service nginx restart

tail -f /var/log/jitsi/jvb.log
