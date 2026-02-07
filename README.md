
# aria2-onion-downloader
## What is this for?
Ever tried to download for example leaks from the onion network which have multiple parts with multiple GBs for each file and it took days? Look no further and behold ;)

This repo contains an docker-compose-file which will spawn an aria2ng webinterface as well as an downloaer, which creates up to 99 tor-services and allows to load-balance downloads between these via an local nginx instance. This means you can download at an really high speed, since Aria2 fragments the downloads by default to 10 connections, which get load-balanced to Tor-Services. This means you can reach up to 10th time the speed in an single download and an even higher speed when you download multiple parts in parallel!

![2021-04-12_Aria2](https://user-images.githubusercontent.com/1722036/114446811-f3760400-9bd1-11eb-9bef-7a17d077326b.PNG)

## Usage
First, always change the RPCSECRET in `docker-compose.yml` and enter your VPN details.

Afterwards you can run `docker-compose up`, which will start 3 containers, an controller, an downloader with ports bound to localhost and the VPN-Gateway. 6800 is the RPC-Port of the downloader, 8080 is the Web-UI. It is not recommended to expose these ports to the internet.

When you open the Web-UI via `http://localhost:8080`, you should first navigate to `AriaNg Settings`, afterwards click on the tab RPC and adjust the RPCSECRET to the one in the docker-compose-file. Afterwards you can add downloads. After adding if the downloads don't start at once, please give them some seconds to start :)

Your downloads will be in `./downloader/data/`.

## Why keep three containers
Yeah, the web-ui could be easily integrated into the downloader-instance. This way you would save some resources BUT in the layout it is right now, you could simply spawn multiple downloader simply by copying the corresponding lines in the docker-compose-file and adding them as RPCs in aria2, resulting in even higher download rates. If you want to integrate the web-ui in the downloader, simply copy the www-dir from the controller to downloader, add the folder in the docker-compose, and add the lines from the nginx.conf of the controller to the downloader.

## Without VPN
If you want your containers to NOT use a vpn, use the `docker-compose_no_vpn.yml` instead of the typical docker-compose file.

## Bulk Download
You can place `.txt`-files containing links in `controller/conf/`. These will be read _only_ on container startup and download the links in the text-file.

## Credits
- This dockerfile really helped me in the creation of this solution: https://github.com/abcminiuser/docker-aria2-with-webui
- [@unconfigured]( https://github.com/unconfigured ) for the load-balancing idea
- [@reece394](https://github.com/reece394) for many great additions
