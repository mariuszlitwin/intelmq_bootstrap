#IntelMQ Bootstrap
______

After too many manual deployments of IntelMQ + IntelMQ Manager on various IaaS services I decided to wrap basic installation in some kind of script.

##Docker
I tried build Docker container around IntelMQ - results of my effort are in Docker directory. Using this Dockerfile is **STRONGLY DISCOURAGED**. I gave up creating it after finding up that it doesn't really fit in my development cycle.

Besides that it can be good base for someone actually trying to use IntelMQ in Docker. Feel free to fork this repo and fix Dockerfile. I will be more than happy to accept your pull request.

##bootstrap.sh
After my small *rendez vous* with Docker I stepped back to simple bash script. You can use it to setup IntelMQ with IntelMQ Manager on your machine. Keep in mind that script assumes that you are using freshly installed OS. It can mess up with your Apache2, redis or IntelMQ configuration.

Script capabilities are:
 - Installation of IntelMQ and IntelMQ Manager
 - Setting up some authentication on your IntelMQ Manager website (by -a, --httpd-auth switch)
 - Setting up Let's Encrypt certificate on your IntelMQ Manager website (by -d, --httpd-domain switch)
 - Setting up some cronjobs to refresh DBs for IntelMQ Experts (asn-lookup-expert, tor-nodes-expert, maxmind-geoip-expert)

Basic usage of script:
```bash
bootstrap.sh [-a basic|google] [-d <example.com>]```

I'm currently trying to fit Google OAuth2 in basic setup (-a google), but it's still WIP. At this moment this switch makes totally nothing. 
