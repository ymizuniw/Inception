#!/bin/bash
set -euo pipefail

: "${DB_USER:?DB_USER is not set}"
: "${WP_HOME:?WP_HOME is not set}"
: "${WP_ADMIN:?WP_ADMIN is not set}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is not set}"
: "${WP_USER:?WP_USER is not set}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is not set}"

cd /var/www/wordpress

if [ ! -f wp-load.php ]; then
  wp core download --allow-root
fi

if [ ! -f wp-config.php ]; then
  wp config create \
    --dbname=wordpress \
    --dbuser="$DB_USER" \
    --dbpass="$(cat /run/secrets/db_password.txt)" \
    --dbhost=mariadb \
    --skip-check \
    --allow-root
fi

# polling for mariadb connection
db_ready=
for i in {30..0}; do
  if wp db check --allow-root; then
    db_ready=1
    break
  fi
  sleep 1
done

if [ -z "$db_ready" ]; then
  echo "MariaDB connection failed!" >&2
  exit 1
fi

if ! wp core is-installed --allow-root; then
  wp core install \
    --url="$WP_HOME" \
    --title="Inception" \
    --admin_user="$WP_ADMIN" \
    --admin_password="$(cat /run/secrets/wp_admin_password.txt)" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root

  wp user create "$WP_USER" "$WP_USER_EMAIL" \
    --role=author \
    --user_pass="$(cat /run/secrets/wp_user_password.txt)" \
    --allow-root
fi

exec php-fpm8.2 -F
