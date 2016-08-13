# Build 2016-04-02
FROM ubuntu:trusty
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
RUN echo "Europe/Berlin" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata
# RUN locale
RUN add-apt-repository --yes ppa:ondrej/php5-5.6

RUN apt-get update

# we use the enviroment variable to stop debconf from asking questions..
RUN apt-get install -y apache2 php5 php5-cli php5-mysql php-pear libpng12-dev libjpeg-dev \
	mysql-client php5-xdebug php5-dev php5-curl curl php5-mcrypt pear-channels wget unzip git \
	vim nano php5-gd nullmailer

# package install is finished, clean up
RUN apt-get clean # && rm -rf /var/lib/apt/lists/*

# Apache conf
ADD config/apache2.conf /etc/apache2/apache2.conf

# Create testing directory
RUN mkdir -p /tests/www

# Update apache envvars
ADD config/envvars /etc/apache2/envvars

# Apache site conf
ADD config/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# php.ini Apache
ADD config/php.ini-apache /etc/php5/apache2/php.ini
ADD config/php.ini-apache /etc/php5/cli/php.ini

# install service files for runit
#ADD config/mysqld.service /etc/service/mysqld/run
ADD config/apache2.service /etc/service/apache2/run

#RUN chmod a+x /etc/service/mysqld/run
RUN chmod a+x /etc/service/apache2/run

# clean up tmp files (we don't need them for the image)
RUN rm -rf /tmp/* /var/tmp/*

# Add user
RUN useradd -m -u 1001 guido

# configure nullmail
RUN echo -n 'docker.gott smtp' > /etc/nullmailer/remotes

# Use baseimage-docker's init system.
CMD /bin/bash -c "source /etc/apache2/envvars && service nullmailer restart && exec /usr/sbin/apache2 -DFOREGROUND"
