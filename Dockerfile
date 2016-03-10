# Build 2016-03-03
FROM ubuntu:xenial
MAINTAINER Yves Hoppe <yves@compojoom.com>

# Set correct environment variables.
ENV HOME /root

# update the package sources
RUN apt-get update

# we use the enviroment variable to stop debconf from asking questions..
RUN DEBIAN_FRONTEND='noninteractive' apt-get install -y mysql-server apache2 php5 php5-cli php5-mysql php-pear mysql-client php5-xdebug php5-dev php5-curl curl php5-mcrypt pear-channels wget unzip git fluxbox firefox openjdk-7-jre xvfb \
	dbus libasound2 libqt4-dbus libqt4-network libqtcore4 libqtgui4 libpython2.7 libqt4-xml libaudio2 fontconfig  nano

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

# php.ini Apache
ADD config/php.ini-apache /etc/php5/apache2/php.ini
ADD config/php.ini-apache /etc/php5/cli/php.ini

# install service files for runit
ADD config/mysqld.service /etc/service/mysqld/run
ADD config/apache2.service /etc/service/apache2/run

RUN chmod a+x /etc/service/mysqld/run
RUN chmod a+x /etc/service/apache2/run

# clean up tmp files (we don't need them for the image)
RUN rm -rf /tmp/* /var/tmp/*

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=bin --filename=composer
RUN composer self-update

# For caching, not so many pulls every composer install / update
RUN composer global require codeception/codeception:dev-master
RUN composer global require codegyre/robo:dev-master
RUN composer global require joomla-projects/robo:dev-master
RUN composer global require joomla-projects/selenium-server-standalone:dev-master
RUN composer global require fzaninotto/faker:^1.5
RUN composer global require squizlabs/php_codesniffer=1.5.6

# Use baseimage-docker's init system.
CMD /bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"

