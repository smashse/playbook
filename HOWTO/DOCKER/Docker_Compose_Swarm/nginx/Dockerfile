FROM ubuntu:latest

LABEL author="Admin"

RUN apt-get update \
    && apt-get install -y nginx \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt-get/lists/* /tmp/* /var/tmp/* \
    && echo "server { \
            listen 80 default_server; \
            listen [::]:80 default_server; \
            root /var/www/html; \
            index index.html index.htm index.nginx-debian.html; \
            server_name _; \
            location / { \
                    proxy_pass http://nginx; \
            } \
    } \
    upstream nginx { \
    server 172.18.0.91:8000; \
    server 172.18.0.92:8000; \
    server 172.18.0.93:8000; \
    }" > /etc/nginx/sites-available/nginx \
    && ln -sf /etc/nginx/sites-available/nginx /etc/nginx/sites-enabled/nginx \
    && rm -rf /etc/nginx/sites-enabled/default \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx"]
