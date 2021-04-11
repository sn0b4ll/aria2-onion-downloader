# aria2-onion-downloader
## What is this for?
Ever tried to download for example leaks from the onion network which have multiple parts with multiple GBs for each file and it took days? Look no further and behold ;)

This repo contains an docker-compose-file which will spawn an aria2ng webinterface as well as an downloaer, which creates up to 99 tor-services and provides these via the ports 15001-15099. This means you can download each part via an own tor-service, with each parting having the full speed of the circuit!

## Usage
First, always change the RPCSECRET in `docker-compose.yml` and create the `data`-folder in `downloader`.

Afterwards you can run `docker-compose up`, which will start 2 containers, an controller and an downloader with ports bound to localhost. 13001 is the RPC-Port of the downloader, 9006 is the Web-UI. If you want to expose these ports to the internet, just change the port assignment in the `docker-compose.yml` but again, make sure you changed the secret first!

By default there will be 10 tor-services running the downloader, bound to 15001 to 15010. If you need more, you can simply adjust the TORSERVNUM in the `docker-compose.yml`.

When you open the Web-UI, you should adjust the RPC-Port to 13001 on localhost and afterwards you can add downloads. When you add an download, hit options, enable the checkbox left to `Http` and enter one of the tor-ports (again 15001 to 15010 by default) on `Proxy Server` (like localhost:15001) to start a download via that service. For better download rates of course it makes sense to load-balance between the services accordingly. 

Your downloads will be in `./downloader/data/`.

## Credits
This dockerfile really helped me in the creation of this solution:
https://github.com/abcminiuser/docker-aria2-with-webui


