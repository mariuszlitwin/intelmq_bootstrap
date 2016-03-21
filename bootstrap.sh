#!/bin/bash
################################################################################
# Shellscript to automatically build IntelMQ with Manager
################################################################################
# Author / Maintainer
# Mariusz Litwin <mariusz.litwin@protonmail.com>
################## BEGIN INSTALLATION ##########################################
# Install IntelMQ with Manager as described on GitHub
# Ref: https://github.com/certtools/intelmq/blob/master/docs/User-Guide.md
# Ref: https://github.com/certtools/intelmq-manager/blob/master/docs/INSTALL.md
#
# Some additional secret sauce to make it all work
#
################################################################################
# Verify running as root:
if [ "$(id -u)" != "0" ]; then
    if [ $# -ne 0 ]; then
        echo "Failed running with sudo. Exiting." 1>&2
        exit 1
    fi
    echo "This script must be run as root. Trying to run with sudo."
    sudo bash "$0" --with-sudo
    exit 0
fi
# Verify if LC_ALL is set
if [ -n "$LC_ALL" ]; then
    echo "I additionally checked locale, looks fine"
else
    echo "LC_ALL locale is not set, shame on you"
    sleep 2
    echo "OK, I will set it to C..."
    export LC_ALL="C"
    sleep 2
fi
# Parse run arguments:
while [[ $# > 1 ]]
do
key="$1"

case $key in
    -h|--help)
    echo 'IntelMQ bootstraping script. I assume that you run this script on the'
    echo 'fresh installed system. It can mess with your Apache2, redis and ofcoz'
    echo 'IntelMQ installation so be careful.'
    echo 'When in doubt - read and change script code or contact me at'
    echo 'mariusz.litwin@protonmail.com'
    echo
    echo 'Thanks ;)'
    echo
    echo 'Basic usage:'
    echo '  bootstrap.sh [-a basic|google -d <example.com>]'
    echo
    echo '  -a - setup Apache2 auth_mod mod_auth_basic or mod_auth_openidc'
    echo '  -d - external domain which points to this server. If provided script'
    echo '       will run Lets Encrypt client and add renewal script to cron'
    shift
    exit 0
    ;;
    -a|--httpd-auth)
    HTTPD_AUTH="$2"
    shift
    ;;
    -d|--httpd-domain)
    HTTPD_DOMAIN="$2"
    shift
    ;;
    *)
            # unknown option
    ;;
esac
shift
done

######################### IntelMQ ##############################################
echo ' ┌▶ IntelMQ'
echo ' ├─▶ Install base apt packages'
    apt-get update -qq
    apt-get upgrade -y -qq
    apt-get install -y -qq build-essential \
                           libcurl4-gnutls-dev \
                           libffi-dev \
                           libgnutls-dev \
                           libssl-dev \
                           libpq-dev \
                           python-dev \
                           python \
                           python-pip \
                           git \
                           redis-server

echo ' ├─▶ Update PIP'
    wget -q "https://bootstrap.pypa.io/get-pip.py" -O "/tmp/get-pip.py"
    python2 /tmp/get-pip.py
echo ' ├─▶ Clone IntelMQ repo and reverse to proper commit'
    git clone https://github.com/mariuszlitwin/intelmq.git /tmp/intelmq
    cd /tmp/intelmq
    git reset --hard 5cc82fd613bd4dd37d67651d8ef7a89a9e07b9cc
echo ' ├─▶ Install basic pip modules'
    pip2 install -q --upgrade pyopenssl ndg-httpsclient pyasn1 urllib3[secure]
    pip2 install -q -r /tmp/intelmq/REQUIREMENTS
    pip2 install -q .
echo ' ├─▶ Install pip modules for bots'
echo ' ├──▶ Mail Collector'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/collectors/mail/REQUIREMENTS.txt
echo ' ├──▶ RT Collector'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/collectors/rt/REQUIREMENTS.txt
echo ' ├──▶ AlienVault OTX Collector'
    pip2 install -q git+git://github.com/AlienVault-Labs/OTX-Python-SDK
echo ' ├──▶ Blueliv Collector'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/collectors/blueliv/REQUIREMENTS.txt
echo ' ├──▶ n6stomp Collector'
    pip2 install -q stomp.py
echo ' ├──▶ XMPP Collector'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/collectors/xmpp/REQUIREMENTS.txt
echo ' ├──▶ Abusix Expert'
    pip2 install -q -U git+git://github.com/mariuszlitwin/querycontacts
echo ' ├──▶ ASN_Lookup Expert'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/experts/asn_lookup/REQUIREMENTS.txt
    mkdir /opt/intelmq/var/lib/bots/asn_lookup/
    cd /tmp/
    pyasn_util_download.py --latest
    mv /tmp/rib.*.bz2 /tmp/rib.bz2
    pyasn_util_convert.py --single rib.bz2 ipasn.dat
    mv /tmp/ipasn.dat /opt/intelmq/var/lib/bots/asn_lookup/ipasn.dat
    chown -R intelmq.intelmq /opt/intelmq/var/lib/bots/asn_lookup
echo ' ├──▶ MaxMind GeoIP Expert'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/experts/maxmind_geoip/REQUIREMENTS.txt
    mkdir -p /opt/intelmq/var/lib/bots/maxmind_geoip
    wget -q http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz -O /tmp/GeoLite2-City.mmdb.gz
    gunzip /tmp/GeoLite2-City.mmdb.gz
    mv /tmp/GeoLite2-City.mmdb /opt/intelmq/var/lib/bots/maxmind_geoip/GeoLite2-City.mmdb
    chown -R intelmq.intelmq /opt/intelmq/var/lib/bots/maxmind_geoip
echo ' ├──▶ Tor_Nodes Expert'
    mkdir -p /opt/intelmq/var/lib/bots/tor_nodes
    wget -q https://internet2.us/static/latest.bz2 -O /tmp/latest.bz2
    bzip2 -d /tmp/latest.bz2
    mv /tmp/latest /opt/intelmq/var/lib/bots/tor_nodes/tor_nodes.dat
echo ' ├──▶ BigQuery Output'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/outputs/bigquery/REQUIREMENTS
echo ' ├──▶ ElasticSearch Output'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/outputs/elasticsearch/REQUIREMENTS
echo ' ├──▶ MongoDB Output'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/outputs/mongodb/REQUIREMENTS.txt
echo ' ├──▶ PostgreSQL Output'
    pip2 install -q -r /tmp/intelmq/intelmq/bots/outputs/postgresql/REQUIREMENTS.txt
echo ' ├─▶ Install IntelMQ'
    cd /tmp/intelmq
    python2 setup.py install
echo ' ├─▶ Base config'
    useradd -d /opt/intelmq -U -s /bin/bash intelmq
    echo 'export PATH="$PATH:$HOME/bin"' >> /opt/intelmq/.profile
echo ' ├─▶ Move default config to /opt/intelmq, fixes'
    mkdir -p /opt/intelmq/var/log
    cp /tmp/intelmq/intelmq/conf/* /opt/intelmq/etc/
    cp /tmp/intelmq/intelmq/bots/BOTS /opt/intelmq/etc/
    chmod -R 0770 /opt/intelmq
    chown -R intelmq.intelmq /opt/intelmq
echo ' ├─▶ Disabling transparent huge memory pages'
    /sbin/sysctl vm.overcommit_memory=1
    echo never > /sys/kernel/mm/transparent_hugepage/enabled  
echo ' ├─▶ Add init script for redis'
    service redis-server enable
    service redis-server start
echo ' └─▶ Add IntelMQ bot DB renewal script to cron.d (as intelmq)'
    mkdir -p /opt/intelmq_bootstrap
    wget -q https://raw.githubusercontent.com/mariuszlitwin/intelmq_bootstrap/master/jobs/000.asn_lookup_refresh.sh -O /opt/intelmq_bootstrap/000.asn_lookup_refresh.sh
    wget -q https://raw.githubusercontent.com/mariuszlitwin/intelmq_bootstrap/master/jobs/001.maxmind_geoip_refresh.sh -O /opt/intelmq_bootsrap/001.maxmind_geoip_refresh.sh
    wget -q https://raw.githubusercontent.com/mariuszlitwin/intelmq_bootstrap/master/jobs/002.tor_nodes_refresh.sh -O /opt/intelmq_bootsrap/002.tor_nodes_refresh.sh
    chown -R intelmq.intelmq /opt/intelmq_bootsrap
    chmod -R u+x /opt/intelmq_bootsrap 
    echo '# /etc/cron.d/intelmqdbs: crontab entries for the IntelMQ DBs renewal script
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 12 * * *  intelmq   /opt/intelmq_bootsrap/000.asn_lookup_refresh.sh >> /opt/intelmq/var/log/asn-lookup-expert-refresh.log
0 12 * * *  intelmq   /opt/intelmq_bootsrap/001.maxmind_geoip_refresh.sh >> /opt/intelmq/var/log/maxmind-geoip-expert-refresh.log
0 12 * * *  intelmq   /opt/intelmq_bootsrap/002.tor_nodes_refresh.sh >> /opt/intelmq/var/log/tor-nodes-expert-refresh.log' > /etc/cron.d/intelmqdbs

echo
##################### IntelMQ Manager ##########################################
echo ' ┌▶ IntelMQ Manager'
echo ' ├─▶ Download and install IntelMQ Manager'
    apt-get -qq -y install apache2 php5 libapache2-mod-php5
    git clone https://github.com/certtools/intelmq-manager.git /tmp/intelmq-manager
    cp -R /tmp/intelmq-manager/intelmq-manager/* /var/www/html/
    chown -R www-data.www-data /var/www/html/
    usermod -a -G intelmq www-data
    echo "www-data ALL=(intelmq) NOPASSWD: /usr/local/bin/intelmqctl" >> /etc/sudoers  
echo ' └─▶ # Add init script for apache2'
    service apache2 enable
    service apache2 start

echo
##################### Apache2 Auth #############################################
if [ -n "$HTTPD_AUTH" ]; then
    ##################### Apache2 Auth (Basic) #################################
    # Code below configure IntelMQ Manager to use mod_auth_basic as described here:
    # Ref: https://github.com/certtools/intelmq-manager/blob/master/docs/INSTALL.md#basic-authentication-optional
    # After this you need to modify htpasswd to use better login
    if [ $HTTPD_AUTH -eq "basic" ]; then
        echo ' ┌▶ Auth module: mod_auth_basic'
        echo ' ├─▶ Install necessary APT packages'
        apt-get -q install apache2-utils
        echo ' ├─▶ Create /etc/.htpasswd (login as admin with password below)'
        htpasswd -c /etc/.htpasswd admin
        echo ' ├─▶ Overwrite /etc/apache2/sites-available/000-default.conf'
        wget -q https://raw.githubusercontent.com/mariuszlitwin/intelmq_bootstrap/master/config/000-default.conf -O /etc/apache2/sites-available/000-default.conf
        echo ' └─▶ Restart apache2'
        service apache2 restart
    fi
    ##################### Apache2 Auth (Google OAuth2) #########################
    # Code below configure IntelMQ Manager to use mod_auth_openidc 
    # (Google OAuth2) as described here:
    # Ref: https://github.com/pingidentity/mod_auth_openidc
    if [ $HTTPD_AUTH -eq "google" ]; then
        echo ' ─▶ Under development. Sorry'
        #echo ' ┌──▶ Auth module: libapache2-mod-auth-openidc-1.8.8-1'
        #echo ' ├─▶ Download and install mod-auth-openidc deb package'
        #wget -q https://github.com/pingidentity/mod_auth_openidc/releases/download/v1.8.8/libapache2-mod-auth-openidc_1.8.8-1.bpo70.1_amd64.deb -O /tmp/libapache2-mod-auth-openidc_1.8.8-1.bpo70.1_amd64.deb
        #dpkg -i /tmp/libapache2-mod-auth-openidc_1.4_amd64.deb
    fi
fi
echo
##################### Let's Encrypt ############################################
# Code below configure Let's Encrypt as described in:
# Ref: https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-14-04
if [ -n "$HTTPD_DOMAIN" ]; then
    echo ' ┌▶ Lets Encrypt!'
    echo ' ├─▶ Clone Lets Encrypt repo'
    git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
    echo ' ├─▶ Run Lets Encrypt'
    /opt/letsencrypt/letsencrypt-auto --apache -d ${HTTPD_DOMAIN}
    echo ' ├─▶ Add Lets Encrypt renewal script to cron.d (as root)'
    # TODO: find more suitable user for this cronjob
    echo '# /etc/cron.d/letsencrypt: crontab entries for the Lets Encrypt renewal script
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

30 2 * * 1  root   /opt/letsencrypt/letsencrypt-auto renew >> /var/log/le-renew.log' > /etc/cron.d/letsencrypt
fi


