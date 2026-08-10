#!/bin/bash
set -e

# Run all install/setup scripts in order.
# Assumes every script is located in the same directory as this one.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

bash ./install_mariadb.sh
bash ./install_php_fpm.sh
bash ./install_nginx.sh
bash ./gen_cert.sh

# docker-entrypoint.sh creates the DB/user, then execs mariadbd in the
# foreground, so it must run in the background to let the rest continue.
bash ./docker-entrypoint.sh &

bash ./wp_create_conf.sh
bash ./wp_setup_db.sh
