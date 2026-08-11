#!/bin/bash

set -e

mkdir -p /var/www/wordpress
cd /var/www/wordpress

if [ ! -f wp-load.php ]; then
	wp core download --path=/var/www/wordpress --allow-root
fi
