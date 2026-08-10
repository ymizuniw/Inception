#!/bin/bash
# execute with source not to make a child process
# set -eou pipefail

REQUIRED_VARS=("DOMAIN_NAME" "WP_HOME" "WP_SITEURL" \
"DB_NAME" "DB_USER" "DB_ADMIN" "DB_HOST" "DB_CHARSET" \
"WP_ADMIN" "WP_ADMIN_EMAIL" "WP_USER" "WP_USER_EMAIL")

ERROR=0
for v in "${REQUIRED_VARS[@]}"; do
    if [ -n "${!v+x}" ]; then
        echo "${v}:${!v}"
    else
        echo "${v}:undefined"
        ERROR=1
        break
    fi
done

if [ $ERROR -eq 0 ]; then
    echo "[ok]"
else
    echo "[ko]"
fi
