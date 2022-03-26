# ---------------------------------------------- Build Time Arguments --------------------------------------------------
ARG PHP_VERSION="7.4"
ARG ALPINE_VERSION="3.14"
ARG APCU_VERSION="5.1.17"
ARG APCU_BC_VERSION="1.0.5"
ARG TZ="Europe/Paris"
ARG LANG="fr_fr.UTF-8"
ARG LANGUAGE="fr_fr.UTF-8"
ARG LC_ALL="fr_fr.UTF-8"
ARG OPENCV_VERSION="4.5.0"
ARG OPENJDK_VERSION="18"
ARG IMAGEMAGICK_VERSION="6.9.12-20"
ARG PHP_IMAGICK_VERSION="3.4.4"
ARG ELASTIC_APM_AGENT_VERSION="1.3"


FROM openjdk:${OPENJDK_VERSION}-alpine${ALPINE_VERSION} as java

# ======================================================================================================================
#                                                   --- Base ---
# ---------------  This stage install needed extenstions, plugins and add all needed configurations  -------------------
# ======================================================================================================================
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} as base

LABEL org.label-schema.name="opencv" \
      org.label-schema.description="Small OpenCV (Open Source Computer Vision Library) Docker Image for PHP 7.2 Alpine Linux" \
      org.label-schema.url="" \
      org.label-schema.usage="" \
      org.label-schema.vcs-url="" \
      org.label-schema.vendor="benjy8001" \
      org.label-schema.version="4.5.0" \
      maintainer="benjy8001"

ARG APCU_VERSION
ARG APCU_BC_VERSION
ARG IMAGEMAGICK_VERSION
ARG PHP_IMAGICK_VERSION
ARG TZ
ARG LANG
ARG LANGUAGE
ARG LC_ALL
ARG ELASTIC_APM_AGENT_VERSION

ENV LANG=$LANG
ENV LANGUAGE=$LANGUAGE
ENV LC_ALL=$LC_ALL
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl
ENV ELASTIC_APM_AGENT_VERSION=$ELASTIC_APM_AGENT_VERSION

RUN apk add --no-cache \
        ca-certificates \
        icu-libs \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        tzdata \
        libtool  \
        libxml2-dev \
        ghostscript \
        libgomp \
        zlib-dev \
        libzip-dev \
        libintl && \
    apk add --no-cache --virtual .tools  \
        git \
        unzip \
         && \
    apk add --no-cache --virtual .build-deps  \
        $PHPIZE_DEPS \
        php7-dev \
        icu-dev \
        musl-dev \
        gettext-dev \
        cmake \
        make \
        gcc \
         && \
    wget "https://github.com/elastic/apm-agent-php/releases/download/v${ELASTIC_APM_AGENT_VERSION}/apm-agent-php_${ELASTIC_APM_AGENT_VERSION}_all.apk" && \
            apk add --allow-untrusted "apm-agent-php_${ELASTIC_APM_AGENT_VERSION}_all.apk" && \
            rm "apm-agent-php_${ELASTIC_APM_AGENT_VERSION}_all.apk" && \
    wget https://download.imagemagick.org/ImageMagick/download/releases/ImageMagick-${IMAGEMAGICK_VERSION}.tar.xz -O /tmp/ImageMagick-${IMAGEMAGICK_VERSION}.tar.xz && \
    tar -xJf /tmp/ImageMagick-${IMAGEMAGICK_VERSION}.tar.xz -C /tmp/ && \
    rm /tmp/ImageMagick-${IMAGEMAGICK_VERSION}.tar.xz && \
    (cd /tmp/ImageMagick-${IMAGEMAGICK_VERSION} && ./configure --with-modules && make && make install) && \
    ldconfig /usr/local/lib && \
    rm -R /tmp/ImageMagick-${IMAGEMAGICK_VERSION} && \
    docker-php-ext-install intl \
    	zip && \
    wget "https://pecl.php.net/get/apcu-${APCU_VERSION}.tgz" -O /tmp/apcu.tar.gz && \
    mkdir -p /usr/src/php/ext/apcu && \
    tar xf /tmp/apcu.tar.gz -C /usr/src/php/ext/apcu --strip-components=1 && \
    docker-php-ext-configure apcu && \
    docker-php-ext-install -j"$(nproc)" apcu && \
    rm /tmp/apcu.tar.gz && \
    wget "https://pecl.php.net/get/apcu_bc-${APCU_BC_VERSION}.tgz" -O /tmp/apcu_bc.tar.gz && \
    mkdir -p /usr/src/php/ext/apcu-bc && \
    tar xf /tmp/apcu_bc.tar.gz -C /usr/src/php/ext/apcu-bc --strip-components=1 && \
    docker-php-ext-configure apcu-bc && \
    docker-php-ext-install -j"$(nproc)" apcu-bc && \
    rm /tmp/apcu_bc.tar.gz && \
    rm /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini && \
    echo extension=apcu.so > /usr/local/etc/php/conf.d/20-php-ext-apcu.ini && \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone && \
    docker-php-ext-enable opcache && \
    docker-php-ext-install mysqli pdo pdo_mysql && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install gd && \
    docker-php-ext-install soap && \
    docker-php-ext-install calendar && \
    docker-php-ext-install bcmath && \
    docker-php-ext-install sockets && \
    pecl install imagick-${PHP_IMAGICK_VERSION}  && \
    docker-php-ext-enable imagick && \
    wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip && \
    unzip musl-locales-master.zip && \
    cd musl-locales-master && \
    cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install && \
    cd .. && rm -r musl-locales-master && rm musl-locales-master.zip && \
    apk del .build-deps icu-dev $PHPIZE_DEPS zlib-dev && \
    apk add gosu --update --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted && \
    addgroup bar && \
    adduser -D -h /home -s /bin/sh -G bar foo

# ======================================================================================================================
#                                               --- Opencv stage ---
# ----------------------------------  This stage will compile and install Opencv  --------------------------------------
# ======================================================================================================================
FROM base as opencv

RUN apk add --no-cache --virtual .build-deps \
    curl-dev zlib-dev openssl-dev build-base cmake linux-headers git autoconf

ARG OPENCV_VERSION

# Dl opencv
RUN cd /opt && \
    wget https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
    unzip ${OPENCV_VERSION}.zip && \
    rm ${OPENCV_VERSION}.zip && \
    wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    unzip ${OPENCV_VERSION}.zip && \
    rm ${OPENCV_VERSION}.zip && \
    export PKG_CONFIG=/usr/bin/pkg-config && export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib64/pkgconfig/ && export LD_LIBRARY_PATH="/usr/local/lib64/" && \
	cd /opt/opencv-${OPENCV_VERSION} && \
    mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_TBB=ON \
          -D WITH_V4L=ON \
          -D INSTALL_C_EXAMPLES=OFF \
          -D INSTALL_PYTHON_EXAMPLES=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D BUILD_EXAMPLES=OFF \
          -D BUILD_JAVA=OFF \
          -D BUILD_TESTS=OFF \
          -D WITH_QT=OFF \
          -D WITH_FFMPEG=NO \
          -D WITH_OPENGL=ON \
          -D BUILD_opencv_world=ON \
          -D OPENCV_PYTHON_SKIP_DETECTION=ON \
          -D OPENCV_GENERATE_PKGCONFIG=ON \
          -D OPENCV_PC_FILE_NAME=opencv4.pc \
          -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENCV_VERSION}/modules .. && \
    make -j2 && make install && \
    cd ../.. && \
    rm -R opencv-${OPENCV_VERSION} && \
    rm -R opencv_contrib-${OPENCV_VERSION}

# ======================================================================================================================
#                                              --- PHP Opencv stage ---
# ----------------------------  This stage will compile and install php-opencv library.  -------------------------------
# ======================================================================================================================
FROM opencv as phpopencv

RUN apk add --no-cache php7-dev && \
	export PKG_CONFIG=/usr/bin/pkg-config && export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib64/pkgconfig/ && export LD_LIBRARY_PATH="/usr/local/lib64/" && \
    cd /opt && \
    git clone https://github.com/php-opencv/php-opencv.git && \
    cd php-opencv && \
    git checkout php7.4 && \
    phpize && \
    ./configure --with-php-config=/usr/bin/php-config && \
    make && make test && make install && \
    cd ../ && \
    rm -R php-opencv && \
    apk del php7-dev


# ======================================================================================================================
# ===========================================  PRODUCTION FINAL STAGES  ================================================
#                                                   --- PROD ---
# ======================================================================================================================
# ------------------------------------------------------ FPM -----------------------------------------------------------
FROM base as fpm-prod

RUN mkdir -p /usr/local/bin/ && \
	mkdir -p /usr/local/lib64/ && \
	mkdir -p /usr/share/OpenCV/ && \
	mkdir -p /usr/local/share/opencv4/ && \
    echo "extension=/usr/lib/php7/modules/opencv.so" > /usr/local/etc/php/conf.d/opencv.ini

COPY --from=phpopencv /usr/lib/php7/modules/opencv.so /usr/lib/php7/modules/opencv.so
COPY --from=phpopencv /usr/local/bin/* /usr/local/bin/
COPY --from=phpopencv /usr/local/lib64/* /usr/local/lib64/
COPY --from=phpopencv /usr/local/share/opencv4/* /usr/local/share/opencv4/
COPY config/apc.ini config/conf_sample.ini config/opcache.ini-* /usr/local/etc/php/conf.d/
COPY config/pm.conf /usr/local/etc/php-fpm.d/
COPY entrypoint.sh /entrypoint

RUN sed -i 's@pm = dynamic@;pm = dynamic@g' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's@pm.max_children = 5@;pm.max_children = 5@g' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's@pm.max_children = 5@;pm.max_children = 5@g' /usr/local/etc/php-fpm.d/www.conf && \
    ln -s /usr/local/share/opencv4 /usr/share/OpenCV/haarcascades && \
    ln -s /bin/hostname /usr/bin/hostname && \
    chmod +x /entrypoint

WORKDIR /srv

ENTRYPOINT ["/entrypoint"]

# ======================================================================================================================
# ==========================================  DEVELOPMENT FINAL STAGES  ================================================
#                                                    --- DEV ---
# ======================================================================================================================

# ------------------------------------------------------ FPM -----------------------------------------------------------
FROM fpm-prod as fpm-dev

ENV PATH="/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin:${PATH}"

# Xdebug
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS	&& \
    pecl install xdebug && \
    docker-php-ext-enable xdebug && \
    apk del -f .build-deps

COPY config/xdebug.ini config/dev.ini /usr/local/etc/php/conf.d/
COPY --from=java /usr/lib/jvm/java-1.8-openjdk /usr/lib/jvm/java-1.8-openjdk

RUN ln -sf /usr/lib/jvm/java-1.8-openjdk/bin/java /usr/bin/

WORKDIR /srv

ENTRYPOINT ["/entrypoint"]