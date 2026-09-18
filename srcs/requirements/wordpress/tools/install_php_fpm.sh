#!/bin/bash
set -euo pipefail

# mariadb-client provides mysqlcheck/mysql/mysqldump, which wp-cli's `wp db *`
# subcommands shell out to directly (they don't go through PHP's mysqli).
apt update && apt install -y php8.2-fpm php-mysql php-cli mariadb-client curl && rm -fr /var/lib/apt/lists/*

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
