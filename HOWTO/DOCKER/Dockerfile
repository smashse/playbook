FROM ubuntu:18.04

MAINTAINER Admin

RUN apt update \
    && apt install -y nginx \
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx"]
