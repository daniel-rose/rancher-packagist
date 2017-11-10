#!/bin/sh
set -e

PATH_TO_PACKAGIST="/var/www/packagist/releases/current/"
PATH_TO_SHARED_FILES="/var/www/packagist/shared/"

cd ${PATH_TO_PACKAGIST}

if [ ! -f "${PATH_TO_PACKAGIST}app/config/parameters.yml" ] && [ -f "${PATH_TO_SHARED_FILES}parameters.yml" ]; then
    ln -s ${PATH_TO_SHARED_FILES}parameters.yml ${PATH_TO_PACKAGIST}app/config/parameters.yml
fi

if [ -d "${PATH_TO_PACKAGIST}web" ] && [ ! -L "/var/www/html" ]; then
    composer.phar install

    php app/console doctrine:schema:create --no-debug --env=prod
    php app/console assets:install web --no-debug --env=prod

    rm -Rf /var/www/html
    ln -s ${PATH_TO_PACKAGIST}web /var/www/html
fi

php app/console cache:clear --no-debug --env=prod

php app/console packagist:update --no-debug --env=prod
php app/console packagist:dump --no-debug --env=prod
php app/console packagist:index --no-debug --env=prod

php app/console cache:warmup --env=prod

chown www-data:www-data * -R

if [ ! -f "/etc/cron.d/packagist" ]; then
    echo "* * * * * www-data php ${PATH_TO_PACKAGIST}app/console packagist:update --no-debug --env=prod" > /etc/cron.d/packagist
    echo "* * * * * www-data php ${PATH_TO_PACKAGIST}app/console packagist:dump --no-debug --env=prod" >> /etc/cron.d/packagist
    echo "* * * * * www-data php ${PATH_TO_PACKAGIST}app/console packagist:index --no-debug --env=prod" >> /etc/cron.d/packagist
fi

cron

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- apache2-foreground "$@"
fi

exec "$@"