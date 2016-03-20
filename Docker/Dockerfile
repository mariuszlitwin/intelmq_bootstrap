############################################################
# Dockerfile to build IntelMQ@phusion/baseimage
# Based on phusion/baseimage:0.9.18
############################################################

# Set the base image to Baseimage
FROM phusion/baseimage:0.9.18

# File Author / Maintainer
MAINTAINER Mariusz Litwin <mariusz.litwin@protonmail.com>

ENV DEBIAN_FRONTEND noninteractive

################## BEGIN INSTALLATION ######################
# Install IntelMQ with Manager as described on GitHub
# Ref: https://github.com/certtools/intelmq/blob/master/docs/User-Guide.md
#      https://github.com/certtools/intelmq-manager/blob/master/docs/INSTALL.md
# Some additional secret sauce to make it all work
######################### IntelMQ ##########################
RUN echo ' ├──▶ # Base config' && \
    mkdir -p /etc/my_init.d && \
    mkdir -p /opt/intelmq && \
    useradd -d /opt/intelmq -U -s /bin/bash intelmq && \
    echo 'export PATH="$PATH:$HOME/bin"' >> /opt/intelmq/.profile && \
    echo 'export INTELMQ_PYTHON=/usr/bin/python3' >> /opt/intelmq/.profile && \

echo ' ├──▶ # Install base apt packages' && \
    apt-get update -qq && \
    apt-get upgrade -y -qq && \
    apt-get install -y -qq build-essential \
                           libcurl4-gnutls-dev \
                           libffi-dev \
                           libgnutls-dev \
                           libssl-dev \
                           libpq-dev \
                           python-dev \
                           python3 \
                           python3-pip \
                           git \
                           wget \
                           redis-server && \

echo ' ├──▶ # Update PIP' && \
    wget -q "https://bootstrap.pypa.io/get-pip.py" -O "/tmp/get-pip.py" && \
    python3 /tmp/get-pip.py && \

echo ' ├──▶ # Clone IntelMQ repo and reverse to proper commit' && \
    git clone https://github.com/mariuszlitwin/intelmq.git /tmp/intelmq && \
    cd /tmp/intelmq && \
    git reset --hard 5cc82fd613bd4dd37d67651d8ef7a89a9e07b9cc && \

echo ' ├──▶ # Install basic pip modules' && \
    pip3 install -q --upgrade pyopenssl ndg-httpsclient pyasn1 && \
    pip3 install -q -r /tmp/intelmq/REQUIREMENTS && \
    pip3 install -q /tmp/intelmq && \

echo ' ├──▶ # Mail Collector' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/collectors/mail/REQUIREMENTS.txt && \

echo ' ├──▶ # RT Collector' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/collectors/rt/REQUIREMENTS.txt && \

echo ' ├──▶ # AlienVault OTX Collector' && \
    pip3 install -q git+git://github.com/AlienVault-Labs/OTX-Python-SDK && \

echo ' ├──▶ # Blueliv Collector' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/collectors/blueliv/REQUIREMENTS.txt && \

echo ' ├──▶ # n6stomp Collector' && \
    pip3 install -q stomp.py && \

echo ' ├──▶ # XMPP Collector' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/collectors/xmpp/REQUIREMENTS.txt && \

echo ' ├──▶ # Abusix Expert' && \
    pip3 install -q -U git+git://github.com/mariuszlitwin/querycontacts && \

echo ' ├──▶ # ASN_Lookup Expert' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/experts/asn_lookup/REQUIREMENTS.txt && \
    mkdir /opt/intelmq/var/lib/bots/asn_lookup/ && \
    cd /tmp/ && \
    pyasn_util_download.py --latest && \
    mv /tmp/rib.*.bz2 /tmp/rib.bz2 && \
    pyasn_util_convert.py --single rib.bz2 ipasn.dat && \
    mv /tmp/ipasn.dat /opt/intelmq/var/lib/bots/asn_lookup/ipasn.dat && \
    chown -R intelmq.intelmq /opt/intelmq/var/lib/bots/asn_lookup && \

echo ' ├──▶ # MaxMind GeoIP Expert' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/experts/maxmind_geoip/REQUIREMENTS.txt && \
    mkdir -p /opt/intelmq/var/lib/bots/maxmind_geoip && \
    wget -q http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz -O /tmp/GeoLite2-City.mmdb.gz && \
    gunzip /tmp/GeoLite2-City.mmdb.gz && \
    mv /tmp/GeoLite2-City.mmdb /opt/intelmq/var/lib/bots/maxmind_geoip/GeoLite2-City.mmdb && \
    chown -R intelmq.intelmq /opt/intelmq/var/lib/bots/maxmind_geoip && \

echo ' ├──▶ # Tor_Nodes Expert' && \
    mkdir -p /opt/intelmq/var/lib/bots/tor_nodes && \
    wget -q https://internet2.us/static/latest.bz2 -O /tmp/latest.bz2 && \
    bzip2 -d /tmp/latest.bz2 && \
    mv /tmp/latest /opt/intelmq/var/lib/bots/tor_nodes/tor_nodes.dat && \

echo ' ├──▶ # BigQuery Output' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/outputs/bigquery/REQUIREMENTS && \

echo ' ├──▶ # ElasticSearch Output' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/outputs/elasticsearch/REQUIREMENTS && \

echo ' ├──▶ # MongoDB Output' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/outputs/mongodb/REQUIREMENTS.txt && \

echo ' ├──▶ # PostgreSQL Output' && \
    pip3 install -q -r /tmp/intelmq/intelmq/bots/outputs/postgresql/REQUIREMENTS.txt && \

echo ' ├──▶ # Install IntelMQ' && \
    cd /tmp/intelmq && \
    python3 setup.py install && \

echo ' ├──▶ # Move default config to /opt/intelmq, fixes' && \
    mkdir -p /opt/intelmq/var/log && \
    mkdir -p /opt/intelmq/etc && \
    cp /tmp/intelmq/intelmq/conf/* /opt/intelmq/etc/ && \
    cp /tmp/intelmq/intelmq/bots/BOTS /opt/intelmq/etc/ && \
    chmod -R 0770 /opt/intelmq && \
    chown -R intelmq.intelmq /opt/intelmq && \
    
echo ' └──▶ # Add init script for redis' && \
    echo '#!/bin/sh \
          /sbin/setuser redis /usr/bin/redis-server /etc/redis/redis.conf' > /etc/my_init.d/010.redis && \
    chmod +x /etc/my_init.d/010.redis

##################### IntelMQ Manager ######################

ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_LOG_DIR=/var/log/apache2

RUN echo ' ├──▶ # Install IntelMQ Manager' && \
    apt-get -qq install apache2 php5 libapache2-mod-php5 && \
    git clone https://github.com/certtools/intelmq-manager.git /tmp/intelmq-manager && \
    cp -R /tmp/intelmq-manager/intelmq-manager/* /var/www/html/ && \
    chown -R www-data.www-data /var/www/html/ && \
    usermod -a -G intelmq www-data && \
    echo "www-data ALL=(intelmq) NOPASSWD: /usr/local/bin/intelmqctl" >> /etc/sudoers && \

echo ' ├──▶ # Fix for Python3' && \
    sed -i 's|#!/usr/bin/env python|#!/usr/bin/env python3.4|g' /usr/local/bin/intelmqctl && \
    sed -i "s|('INTELMQ_PYTHON', 'python')|('INTELMQ_PYTHON', 'python3.4')|g" /usr/local/bin/intelmqctl && \
    
echo ' ├──▶ # Change sudo to setuser in config.php' && \
    sed -i 's|sudo -u intelmq /usr/local/bin/intelmqctl %s|setuser intelmq /usr/local/bin/intelmqctl %s|g' /var/www/html/php/config.php && \
    
echo ' └──▶ # Add init script for apache2' && \
    echo '#!/bin/sh \
          /usr/sbin/apache2' > /etc/my_init.d/011.apache && \
    chmod +x /etc/my_init.d/011.apache

##################### INSTALLATION END #####################

VOLUME ["/data", "/opt/intelmq/etc"]

CMD ["/sbin/my_init"]

# Expose the default port
EXPOSE 80
EXPOSE 443
