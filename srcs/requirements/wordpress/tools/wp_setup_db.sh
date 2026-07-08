#!/bin/bash
set -e

cd "/var/www/wordpress"

if [ ! -f wp-config.php ]; then
 wp config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$(cat /run/secrets/db_password.txt)" --allow-root --skip-check
fi

for i in {30..0}
do
  if ! wp db check --allow-root; then
    if [ "$i" -eq 0 ]; then
      exit 1;
    fi
    sleep 1
    continue
  fi
  break
done

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
    --user_pass="$(cat /run/secrets/wp_password.txt)" \
    --allow-root
fi
