#!/bin/bash
set -euo pipefail

apt update && apt install mariadb-server mariadb-client -y && rm -rf /var/lib/apt/lists/*