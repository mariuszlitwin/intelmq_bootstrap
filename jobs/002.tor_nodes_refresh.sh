#!/bin/bash
BOT_STATUS = `sudo -u intelmq intelmqctl --bot status --id tor-nodes-expert 2>&1 | grep running`
BOT_RUNNING = "$?"

if [ "$BOT_RUNNING" -eq "0" ]; then
  sudo -u intelmq intelmqctl --bot stop --id tor-nodes-expert 2>&1
fi

wget -q https://internet2.us/static/latest.bz2 -O /tmp/latest.bz2 && \
bzip2 -d /tmp/latest.bz2 && \
mv /tmp/latest /opt/intelmq/var/lib/bots/tor_nodes/tor_nodes.dat

if [ "$BOT_RUNNING" -eq "0" ]; then
  sudo -u intelmq intelmqctl --bot start --id tor-nodes-expert 2>&1
fi
