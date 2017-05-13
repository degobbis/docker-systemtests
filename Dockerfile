# Build 2017-05-013
FROM ubuntu:latest
MAINTAINER Guido De Gobbis <guido@degobbis.de>

# Set correct environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE.UTF-8
ENV LC_ALL de_DE.UTF-8

# ADD config/locale /etc/default/locale

# update the package sources
RUN apt-get update; apt-get upgrade -y; apt-get install -y locales software-properties-common python-software-properties language-pack-de

# Configure timezone and locale
RUN echo "Europe/Berlin" > /etc/timezone

# Configure repository for php 5.6
RUN add-apt-repository ppa:ondrej/php

RUN apt-get update

# we use the enviroment variable to stop debconf from asking questions..
RUN apt-get install -y apache2 php5.6 php5.6-mcrypt php5.6-mbstring php5.6-curl php5.6-cli \
	php5.6-mysql php5.6-gd php5.6-intl php5.6-xsl php5.6-zip libapache2-mod-php5.6 \
	php-pear libpng12-dev libjpeg-dev php5.6-xdebug php5.6-dev \
	mysql-client curl pear-channels wget unzip git vim nano nullmailer

# package install is finished, clean up
RUN apt-get clean # && rm -rf /var/lib/apt/lists/*

RUN apt-get update; apt-get upgrade -y

# Apache conf
ADD config/apache2.conf /etc/apache2/apache2.conf

# Create testing directory
RUN mkdir -p /srv/http/vhosts

# Update apache envvars
ADD config/envvars /etc/apache2/envvars

# Apache site conf
ADD config/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# php.ini Apache
ADD config/php.ini-apache /etc/php/5.6/apache2/php.ini
ADD config/php.ini-apache /etc/php/5.6/cli/php.ini

# install service files for runit
# Comment out if not use remotly mysql-server on host
#ADD config/mysqld.service /etc/service/mysqld/run
#RUN chmod a+x /etc/service/mysqld/run

ADD config/apache2.service /etc/service/apache2/run
RUN chmod a+x /etc/service/apache2/run

# clean up tmp files (we don't need them for the image)
RUN rm -rf /tmp/* /var/tmp/*

# Add user to same as host
RUN useradd -m -u 1000 guido

# configure nullmail
RUN echo -n 'docker.gott smtp' > /etc/nullmailer/remotes

# Set helpful aliases
RUN alias l='ls -lah'
RUN alias la='ls -lAh'
RUN alias ll='ls -lh'

# Composer
RUN curl https://getcomposer.org/installer | php -- --install-dir=bin --filename=composer
RUN composer self-update

# WP-CLI
RUN curl -o /bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x /bin/wp

# CMS-Scanner
#RUN curl -o /bin/cmsscanner http://cms-garden.github.io/cmsscanner/downloads/cmsscanner-0.5.0.phar
ADD config/cmsscanner /bin/cmsscanner
RUN chmod +x /bin/cmsscanner

# Use baseimage-docker's init system.
CMD /bin/bash -c "source /etc/apache2/envvars && service nullmailer restart && exec /usr/sbin/apache2 -DFOREGROUND"
