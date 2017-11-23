#!/bin/bash
set -e

PATH_TO_CURRENT_RELEASE="/var/www/packagist/releases/current/"
PATH_TO_SHARED_FILES="/var/www/packagist/shared/"

function run_as() {
  if [[ $EUID -eq 0 ]]; then
    su - www-data -s /bin/bash -c "$1"
  else
    bash -c "$1"
  fi
}

if [ -n "${SSH_PUBLIC_KEY}" ] && [ -n "${SSH_PRIVATE_KEY}" ]; then
    mkdir /var/www/.ssh/
    echo ${SSH_PUBLIC_KEY} > /var/www/.ssh/id_rsa.pub
    echo ${SSH_PRIVATE_KEY} > /var/www/.ssh/id_rsa
    chown www-data:www-data /var/www/.ssh/ -R
    chmod 0644 /var/www/.ssh/id_rsa.pub
    chmod 0600 /var/www/.ssh/id_rsa
fi

# link config
if [ ! -f "${PATH_TO_CURRENT_RELEASE}app/config/parameters.yml" ] && [ -f "${PATH_TO_SHARED_FILES}parameters.yml" ]; then
    ln -s ${PATH_TO_SHARED_FILES}parameters.yml ${PATH_TO_CURRENT_RELEASE}app/config/parameters.yml
fi

# create symlink
if [ -d "${PATH_TO_CURRENT_RELEASE}web" ] && [ ! -L "/var/www/html" ]; then
    rm -Rf /var/www/html
    ln -s ${PATH_TO_CURRENT_RELEASE}web /var/www/html
fi

# install packagist
if [ -f "${PATH_TO_SHARED_FILES}packagist.lock" ]; then
    run_as "php app/console doctrine:schema:create --no-debug --env=prod"
    run_as "php app/console assets:install web --no-debug --env=prod"
    run_as "touch ${PATH_TO_SHARED_FILES}packagist.lock"
fi

run_as "php app/console cache:clear --no-debug --env=prod"

run_as "php app/console packagist:update --no-debug --env=prod"
run_as "php app/console packagist:dump --no-debug --env=prod"
run_as "php app/console packagist:index --no-debug --env=prod"

run_as "php app/console cache:warmup --env=prod"

chown www-data:www-data ${PATH_TO_CURRENT_RELEASE} -R

if [ ! -f "/etc/cron.d/packagist" ]; then
    echo "* * * * * www-data php ${PATH_TO_CURRENT_RELEASE}app/console packagist:update --no-debug --env=prod" > /etc/cron.d/packagist
    echo "* * * * * www-data php ${PATH_TO_CURRENT_RELEASE}app/console packagist:dump --no-debug --env=prod" >> /etc/cron.d/packagist
    echo "* * * * * www-data php ${PATH_TO_CURRENT_RELEASE}app/console packagist:index --no-debug --env=prod" >> /etc/cron.d/packagist
fi

exec "$@"