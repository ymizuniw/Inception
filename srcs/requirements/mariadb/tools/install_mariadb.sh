#!/bin/bash
apt update && apt install -y mariadb-server mariadb-client && rm -fr /var/lib/apt/lists/*

