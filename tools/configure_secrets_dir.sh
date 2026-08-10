#!/bin/bash

# this is for virtual machine pruning the added packages and directories to initialize for server setting test.

SECRET_DIR="/run/secrets"
SECRET_FILES=("db_passoword.txt" "db_root_password.txt" "wp_admin_password.txt" "wp_password.txt")

sudo mkdir -p "${SECRET_DIR}"
for f in "${SECRET_FILES[@]}"; do
    sudo touch "${SECRET_DIR}/$f"
done
