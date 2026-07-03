#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password.txt)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password.txt)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password.txt)

if [ ! -f /var/www/wordpress/wp-config.php ]; then
cat > /var/www/wordpress/wp-config.php << EOF
<?php
define( 'WP_HOME', '$WP_HOME');
define( 'WP_SITEURL', '$WP_SITEURL');
define( 'DB_NAME', '$DB_NAME');
define( 'DB_USER', '$DB_USER');
define( 'DB_PASSWORD', '$DB_PASSWORD' );
define( 'DB_HOST', '$DB_HOST' );
define( 'DB_CHARSET', '$DB_CHARSET' );
define( 'DB_COLLATE', '' );
define( 'WP_DEBUG', false );
\$table_prefix = 'wp_';
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}
require_once( ABSPATH . 'wp-settings.php' );
EOF
fi

chown -R www-data:www-data /var/www/wordpress

cd /var/www/wordpress

until (exec 3<>"/dev/tcp/$DB_HOST/3306") 2>/dev/null; do
  sleep 1
done

if ! wp core is-installed --allow-root; then
  wp core install \
    --url="$WP_HOME" \
    --title="Inception" \
    --admin_user="$ADMIN_NAME" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root

  wp user create "$WP_USER_NAME" "$WP_USER_EMAIL" \
    --role=author \
    --user_pass="$WP_USER_PASSWORD" \
    --allow-root
fi

exec php-fpm8.2 -F
