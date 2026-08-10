#!/bin/bash
set -e

/usr/local/bin/wp_create_conf.sh
/usr/local/bin/wp_setup_db.sh

# php-fpm writes its pid under /run/php, which is not created automatically
mkdir -p /run/php

exec /usr/sbin/php-fpm8.2 -F
