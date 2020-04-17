#!/bin/bash

NEW_CONFIG=0

if [ ! -f /etc/jitsi/videobridge/config ]; then
	NEW_CONFIG=1
fi

if [ "$NEW_CONFIG" -eq 1 ]; then
	# set hostname
	echo "jitsi-meet-web-config jitsi-videobridge/jvb-hostname string $HOSTNAME" | debconf-set-selections

	# regenerate config files for hostname and secrets
	dpkg-reconfigure jitsi-meet-web-config
	dpkg-reconfigure jitsi-videobridge2
	dpkg-reconfigure jicofo
	dpkg-reconfigure jitsi-meet-prosody

	# add regex for authorized source
	echo "org.jitsi.videobridge.AUTHORIZED_SOURCE_REGEXP=focus@auth.$HOSTNAME/.*" >> /etc/jitsi/videobridge/sip-communicator.properties

	# set nat
	if [ "$NAT" -eq 1 ]; then
		sed -i "s/org.ice4j.ice.harvest.STUN_MAPPING_HARVESTER_ADDRESSES/# org.ice4j.ice.harvest.STUN_MAPPING_HARVESTER_ADDRESSES/" /etc/jitsi/videobridge/sip-communicator.properties
		echo "org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=$HOSTNAME" >> /etc/jitsi/videobridge/sip-communicator.properties
		echo "org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)" >> /etc/jitsi/videobridge/sip-communicator.properties
	fi
fi

# copy interface config
if [ ! -f /config/interface_config.js ]; then
	cp -rp /usr/share/jitsi-meet/interface_config.js /config/interface_config.js
else
	cp -rp /config/interface_config.js /usr/share/jitsi-meet/interface_config.js
fi

# restart services
service prosody restart
service jitsi-videobridge2 restart
service jicofo restart
service nginx restart

# show log
tail -f /var/log/jitsi/jvb.log
