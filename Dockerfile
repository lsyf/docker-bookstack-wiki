FROM harbor.cncico.com/mirror/library/alpine:3 as bookstack
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories; \
     apk update; \
     apk upgrade; \
     apk add --no-cache curl tar
COPY bookstack.tar.gz /
RUN set -x; \
    mkdir -p /bookstack \
    && tar xvf bookstack.tar.gz -C /bookstack \
    && rm bookstack.tar.gz

FROM harbor.cncico.com/proxy/library/php:8.1-apache-buster as final
RUN set -x; \
        rm -rf  /etc/apt/sources.list \
        && echo "deb http://mirrors.aliyun.com/debian/ buster main non-free contrib  \ndeb http://mirrors.aliyun.com/debian-security buster/updates main  \ndeb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib  \ndeb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib  \n" > /etc/apt/sources.list \
        && apt-get update -y \
        && apt-get install -y --no-install-recommends \
        git \
        zlib1g-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev  \
        libldap2-dev  \
        libtidy-dev  \
        libxml2-dev  \
        fontconfig  \
        fonts-freefont-ttf   \
        wget \
        tar \
        curl \
        libzip-dev \
        unzip
COPY wkhtmltox_0.12.6-1.buster_amd64.deb ./
RUN chmod a+x ./wkhtmltox_0.12.6-1.buster_amd64.deb \
    && apt-get install -y ./wkhtmltox_0.12.6-1.buster_amd64.deb \
    && rm ./wkhtmltox_0.12.6-1.buster_amd64.deb \
    && docker-php-ext-install -j$(nproc) dom pdo pdo_mysql zip tidy  \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

RUN a2enmod rewrite remoteip; \
    { \
    echo RemoteIPHeader X-Real-IP ; \
    echo RemoteIPTrustedProxy 10.0.0.0/8 ; \
    echo RemoteIPTrustedProxy 172.16.0.0/12 ; \
    echo RemoteIPTrustedProxy 192.168.0.0/16 ; \
    } > /etc/apache2/conf-available/remoteip.conf; \
    a2enconf remoteip

RUN set -ex; \
    sed -i "s/Listen 80/Listen 8080/" /etc/apache2/ports.conf; \
    sed -i "s/VirtualHost *:80/VirtualHost *:8080/" /etc/apache2/sites-available/*.conf

COPY bookstack.conf /etc/apache2/sites-available/000-default.conf

COPY --from=bookstack --chown=33:33 /bookstack/ /var/www/bookstack/

ARG COMPOSER_VERSION=2.1.12
RUN set -x; \
    cd /var/www/bookstack \
    && ls \
    && curl -sS https://getcomposer.org/installer | php -- --version=$COMPOSER_VERSION \
    && /var/www/bookstack/composer.phar install -v -d /var/www/bookstack/ \
    && rm -rf /var/www/bookstack/composer.phar /root/.composer \
    && chown -R www-data:www-data /var/www/bookstack

COPY php.ini /usr/local/etc/php/php.ini
COPY docker-entrypoint.sh /bin/docker-entrypoint.sh

WORKDIR /var/www/bookstack

# www-data
USER 33

VOLUME ["/var/www/bookstack/public/uploads","/var/www/bookstack/storage/uploads"]

ENV RUN_APACHE_USER=www-data \
    RUN_APACHE_GROUP=www-data

EXPOSE 8080

ENTRYPOINT ["/bin/docker-entrypoint.sh"]

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.license="MIT" \
      org.label-schema.name="bookstack" \
      org.label-schema.vendor="solidnerd" \
      org.label-schema.url="https://github.com/solidnerd/docker-bookstack/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/solidnerd/docker-bookstack.git" \
      org.label-schema.vcs-type="Git"
