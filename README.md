# aria2-onion-downloader
## What is this for?
Ever tried to download for example leaks from the onion network which have multiple parts with multiple GBs for each file and it took days? Look no further and behold ;)

This repo contains an docker-compose-file which will spawn an aria2ng webinterface as well as an downloaer, which creates up to 99 tor-services and allows to load-balance downloads between these via an local nginx instance. This means you can download at an really high speed, since Aria2 fragments the downloads by default to 10 connections, which get load-balanced to Tor-Services. This means you can reach up to 10th time the speed in an single download and an even higher speed when you download multiple parts in parallel!

## Usage
First, always change the RPCSECRET in `docker-compose.yml` and create the `data`-folder in `downloader`.

Afterwards you can run `docker-compose up`, which will start 2 containers, an controller and an downloader with ports bound to localhost. 13001 is the RPC-Port of the downloader, 9006 is the Web-UI. If you want to expose these ports to the internet, just change the port assignment in the `docker-compose.yml` but again, make sure you changed the secret first!

When you open the Web-UI, you should adjust the RPC-Port to 13001 on localhost, set the correct RPCSECRET and afterwards you can add downloads. When you add an download, hit options, enable the checkbox left to `Http` and enter `localhost:16001` (the port of the load-balancer) on `Proxy Server` to start a download via that service. For better download rates of course it makes sense to load-balance between the services accordingly.

Your downloads will be in `./downloader/data/`.

## Why keep two containers
Yeah, the web-ui could be easily integrated into the downloader-instance. This way you would save some resources BUT in the layout it is right now, you could simply spawn multiple downloader simply by copying the corresponding lines in the docker-compose-file, resulting in even higher download rates. If you want to integrate the web-ui in the downloader, simply copy the www-dir from the controller to downloader, add the folder in the docker-compose, and add the lines from the nginx.conf of the controller to the downloader.

## Credits
This dockerfile really helped me in the creation of this solution:
https://github.com/abcminiuser/docker-aria2-with-webui


