FROM httpd:2.4.46-alpine as base

RUN set -x \
    && apk update && apk upgrade \
    && apk add --no-cache ca-certificates openssl apache2-proxy apache2-ssl

## ajout d'un petit peu de css sur l'auto index des logs :p
RUN wget -O /tmp/fancy.zip https://github.com/Vestride/fancy-index/archive/main.zip \
    && cd /tmp \
    && unzip fancy.zip \
    && rm fancy.zip \
    && mkdir -p /usr/share/httpd/icons \
    && mv fancy-index-main /usr/share/httpd/fancy-index

RUN mv /usr/share/httpd/fancy-index/icons/* /usr/share/httpd/icons/
RUN mv /usr/share/httpd/fancy-index/style.css /usr/share/httpd/fancy-index/script.js /usr/share/httpd/icons/ && \
    rm -Rf /usr/share/httpd/fancy-index

######################
##### Configuration stage #####
######################
# Configuration image with alias
FROM base as configuration

 # Enable some modules.
RUN sed -i 's@^#LoadModule deflate_module modules/mod_deflate.so@LoadModule deflate_module modules/mod_deflate.so@g' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's@^#LoadModule expires_module modules/mod_expires.so@LoadModule expires_module modules/mod_expires.so@g' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's@^#LoadModule rewrite_module modules/mod_rewrite.so@LoadModule rewrite_module modules/mod_rewrite.so@g' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's@^#LoadModule proxy_module modules/mod_proxy.so@LoadModule proxy_module modules/mod_proxy.so@g' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's@^#LoadModule ssl_module modules/mod_ssl.so@LoadModule ssl_module modules/mod_ssl.so@g' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's@^#LoadModule proxy_http_module modules/mod_proxy_http.so@LoadModule proxy_http_module modules/mod_proxy_http.so@g' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's@^#LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so@LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so@g' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's@^#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so@LoadModule socache_shmcb_module modules/mod_socache_shmcb.so@g' /usr/local/apache2/conf/httpd.conf && \
    echo 'IncludeOptional conf/conf.d/*.conf' >> /usr/local/apache2/conf/httpd.conf

######################
##### Release stage #####
######################
# Release image with alias
FROM base as release

LABEL org.label-schema.name="Httpd Service" \
      org.label-schema.description="Httpd Service Alpine Linux" \
      org.label-schema.url="" \
      org.label-schema.usage="" \
      org.label-schema.vcs-url="" \
      org.label-schema.vendor="benjy8001" \
      org.label-schema.version="2.4.46" \
      maintainer="benjy8001"

RUN mkdir /usr/local/apache2/conf/conf.d && \
    mkdir /usr/local/apache2/conf/vhost.d && \
    mkdir /usr/local/apache2/conf/ssl

COPY --from=configuration /usr/local/apache2/conf/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY conf.d /usr/local/apache2/conf/conf.d
COPY vhost.d /usr/local/apache2/conf/vhost.d

WORKDIR /srv