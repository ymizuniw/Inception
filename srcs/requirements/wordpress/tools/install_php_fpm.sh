#!/bin/bash
set -e

apt update && apt install -y php8.2-fpm php-mysql php-cli php-zip mariadb-client curl && rm -fr /var/lib/apt

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
# quick verification using GPG:
# curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.asc
# curl -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/wp-cli.pgp | gpg --import
# gpg --verify wp-cli.phar.asc wp-cli.phar
# php wp-cli.phar --info

chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# wp --info
