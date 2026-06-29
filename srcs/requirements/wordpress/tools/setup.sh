#!/bin/bash
DB_PASSWORD=$(cat /run/secrets/db_password.txt)
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
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}
require_once( ABSPATH . 'wp-settings.php' );
EOF
exec php-fpm -F
