FROM php:7-apache

MAINTAINER Daniel Rose <daniel.rose@fondofbags.com>

ENV COMPOSER_HOME /var/www/.composer
ENV PATH_TO_RELEASES /var/www/packagist/releases
ENV PATH_TO_CURRENT_RELEASE /var/www/packagist/releases/current

# install the php extensions
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
	    cron \
	    wget \
	    zip \
	    git \
	    supervisor \
	    libcurl4-gnutls-dev \
        libicu-dev \
        libmcrypt-dev; \
	rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install mysqli pdo_mysql mcrypt intl curl

# install composer
RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/1b137f8bf6db3e79a38a5bc45324414a6b1f9df2/web/installer -O - -q | php -- --install-dir=/usr/bin/ --quiet; \
    mkdir -p /var/www/.composer

# download packagist
RUN mkdir -p $PATH_TO_RELEASES/; \
    wget https://github.com/composer/packagist/archive/master.zip; \
    mv master.zip $PATH_TO_RELEASES/; \
    unzip $PATH_TO_RELEASES//master.zip -d $PATH_TO_RELEASES/; \
    mv $PATH_TO_RELEASES/packagist-master/ $PATH_TO_CURRENT_RELEASE/

# composer actions
RUN cd PATH_TO_CURRENT_RELEASE; \
    composer.phar global require hirak/prestissimo; \
    composer.phar install

RUN chown -R www-data:www-data /var/www

RUN a2enmod rewrite ssl

COPY supervisord.conf /etc/supervisor/supervisord.conf

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["/usr/bin/supervisord"]