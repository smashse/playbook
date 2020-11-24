FROM ubuntu:20.04

LABEL author="Admin"

RUN apt-get update \
    && apt-get -y install nginx \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt-get/lists/* /tmp/* /var/tmp/* \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx"]
