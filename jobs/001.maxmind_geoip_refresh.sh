#!/bin/bash
BOT_STATUS = `sudo -u intelmq intelmqctl --bot status --id maxmind-geoip-expert 2>&1 | grep running`
BOT_RUNNING = "$?"

if [ "$BOT_RUNNING" -eq "0" ]; then
  sudo -u intelmq intelmqctl --bot stop --id maxmind-geoip-expert 2>&1
fi

wget -q http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz -O /tmp/GeoLite2-City.mmdb.gz && \
gunzip /tmp/GeoLite2-City.mmdb.gz && \
mv /tmp/GeoLite2-City.mmdb /opt/intelmq/var/lib/bots/maxmind_geoip/GeoLite2-City.mmdb && \
chown -R intelmq.intelmq /opt/intelmq/var/lib/bots/maxmind_geoip

if [ "$BOT_RUNNING" -eq "0" ]; then
  sudo -u intelmq intelmqctl --bot start --id maxmind-geoip-expert 2>&1
fi
