#!/bin/bash
BOT_STATUS = `sudo -u intelmq intelmqctl --bot status --id asn-lookup-expert 2>&1 | grep running`
BOT_RUNNING = "$?"

if [ "$BOT_RUNNING" -eq "0" ]; then
  sudo -u intelmq intelmqctl --bot stop --id asn-lookup-expert 2>&1
fi

cd /tmp/
pyasn_util_download.py --latest && \
mv /tmp/rib.*.bz2 /tmp/rib.bz2 && \
pyasn_util_convert.py --single rib.bz2 ipasn.dat && \
mv /tmp/ipasn.dat /opt/intelmq/var/lib/bots/asn_lookup/ipasn.dat
chown -R intelmq.intelmq /opt/intelmq/var/lib/bots/asn_lookup

if [ "$BOT_RUNNING" -eq "0" ]; then
  sudo -u intelmq intelmqctl --bot start --id asn-lookup-expert 2>&1
fi
