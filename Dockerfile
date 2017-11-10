FROM php:7-apache

MAINTAINER Daniel Rose <daniel.rose@fondofbags.com>

ENV COMPOSER_HOME /var/www/.composer

# install the php extensions
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
	    cron \
	    wget \
	    zip \
	    git \
	    libcurl4-gnutls-dev \
        libicu-dev \
        libmcrypt-dev; \
	rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install mysqli pdo_mysql mcrypt intl curl

# install composer
RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/1b137f8bf6db3e79a38a5bc45324414a6b1f9df2/web/installer -O - -q | php -- --install-dir=/usr/bin/ --quiet; \
    mkdir -p /var/www/.composer

# download packagist
RUN mkdir -p /var/www/packagist/releases/; \
    wget https://github.com/composer/packagist/archive/master.zip; \
    mv master.zip /var/www/packagist/releases/; \
    unzip /var/www/packagist/releases/master.zip -d /var/www/packagist/releases/; \
    mv /var/www/packagist/releases/packagist-master/ /var/www/packagist/releases/current

RUN chown -R www-data:www-data /var/www

RUN a2enmod rewrite ssl

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["apache2-foreground"]