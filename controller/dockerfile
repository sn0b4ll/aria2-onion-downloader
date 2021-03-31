FROM alpine:latest

LABEL maintainer="sn0b4ll"

RUN apk add --update --no-cache bash nginx

# RUN wget https://github.com/mayswind/AriaNg-DailyBuild/archive/master.zip

CMD ["nginx", "-c", "/conf/nginx.conf", "-g", "daemon off;"]

