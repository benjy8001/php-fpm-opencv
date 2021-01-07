######################
##### Base stage #####
######################

# Base image with alias
FROM php:8-fpm-alpine as base

ENV APCU_VERSION 5.1.19
ENV TZ=Europe/Paris

RUN apk add --no-cache \
        ca-certificates \
        icu-libs \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        tzdata \
        imagemagick-dev \
        libtool  \
        libxml2-dev \
        ghostscript  \
        imagemagick  \
        zlib-dev \
        libzip-dev && \
    apk add --no-cache --virtual .tools  \
        git \
        unzip \
         && \
    apk add --no-cache --virtual .build-deps  \
        $PHPIZE_DEPS \
        icu-dev \
         && \
    apk update --repository http://dl-cdn.alpinelinux.org/alpine/edge/community && \
    apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community php8-dev && \
    docker-php-ext-install intl \
    	zip && \
    pecl install apcu-${APCU_VERSION} && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    docker-php-ext-enable apcu && \
    docker-php-ext-enable opcache && \
    docker-php-ext-install mysqli pdo pdo_mysql && \
    docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-install gd && \
    docker-php-ext-install soap && \
    pecl install xdebug && \
    docker-php-ext-enable xdebug && \
    cd /opt && \
    git clone https://github.com/Imagick/imagick && \
    cd imagick && \
    phpize && ./configure && \
    make && \
    make install && \
    cd ..  && \
    apk del .build-deps icu-dev $PHPIZE_DEPS zlib-dev  && \
    apk add gosu --update --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted && \
    addgroup bar && \
    adduser -D -h /home -s /bin/sh -G bar foo


######################
##### Opencv stage #####
######################

# Opencv image with alias
FROM base as opencv

ENV OPENCV_VERSION 4.5.0

RUN apk add --no-cache --virtual .build-deps \
    curl-dev zlib-dev openssl-dev build-base cmake linux-headers git autoconf

# Dl opencv
RUN cd /opt && \
    wget https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
    unzip ${OPENCV_VERSION}.zip && \
    rm ${OPENCV_VERSION}.zip && \
    wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    unzip ${OPENCV_VERSION}.zip && \
    rm ${OPENCV_VERSION}.zip

RUN export PKG_CONFIG=/usr/bin/pkg-config && export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib64/pkgconfig/ && export LD_LIBRARY_PATH="/usr/local/lib64/" && \
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


######################
##### PHP Opencv stage #####
######################

# PHP Opencv image with alias
FROM opencv as phpopencv

RUN apk update --repository http://dl-cdn.alpinelinux.org/alpine/edge/community && \
  apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community php8-dev && \
	export PKG_CONFIG=/usr/bin/pkg-config && export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib64/pkgconfig/ && export LD_LIBRARY_PATH="/usr/local/lib64/" && \
    cd /opt && \
    git clone https://github.com/php-opencv/php-opencv.git && \
    cd php-opencv && \
    phpize && \
    ./configure --with-php-config=/usr/bin/php-config8 && \
    make && make install && \
    cd ../ && \
    rm -R php-opencv && \
    apk del php8-dev
    #&& make test


######################
##### Release stage #####
######################
# Release image with alias
FROM base as release

LABEL org.label-schema.name="opencv" \
      org.label-schema.description="Small OpenCV (Open Source Computer Vision Library) Docker Image for PHP 7.2 Alpine Linux" \
      org.label-schema.url="" \
      org.label-schema.usage="" \
      org.label-schema.vcs-url="" \
      org.label-schema.vendor="Business&Decision" \
      org.label-schema.version="4.4.1" \
      maintainer="Business&Decision"

RUN mkdir -p /usr/local/bin/ && \
	mkdir -p /usr/local/lib64/ && \
	mkdir -p /usr/share/OpenCV/ && \
	mkdir -p /usr/local/share/opencv4/ && \
    echo "extension=/usr/lib/php8/modules/opencv.so" > /usr/local/etc/php/conf.d/opencv.ini && \
    echo "extension=/usr/lib/php8/modules/opencv.so" > /etc/php8/conf.d/opencv.ini

COPY --from=phpopencv /usr/lib/php8/modules/opencv.so /usr/lib/php8/modules/opencv.so
COPY --from=phpopencv /usr/local/bin/* /usr/local/bin/
COPY --from=phpopencv /usr/local/lib64/* /usr/local/lib64/
COPY --from=phpopencv /usr/local/share/opencv4/* /usr/local/share/opencv4/

RUN ln -s /usr/local/share/opencv4/* /usr/share/OpenCV/

WORKDIR /srv
