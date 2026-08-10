#!/bin/bash

REQUIRED_FILES=("/run/secrets/db_password.txt" "/run/secrets/db_root_password.txt" \
"/run/secrets/wp_admin_password.txt" "/run/secrets/wp_password.txt")

ERROR=0
for f in "${REQUIRED_FILES[@]}"; do
    if [ -s "$f" ]; then
        echo "[ok] ${f}"
    else
        echo "[ok] ${f}"
        ERROR=1
        break
    fi
done

if [ $ERROR -eq 1 ]; then
    echo "[ko]"
    exit 1
else
    echo "[ok]"
fi
