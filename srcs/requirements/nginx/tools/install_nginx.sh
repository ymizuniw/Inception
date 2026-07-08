# https://nginx.org/en/linux_packages.html#Debian
set -euo pipefail

apt update && rm -fr /var/lib/apt/lists/*

apt install curl gnupg2 ca-certificates lsb-release debian-archive-keyring
# chmod or chgrp to give appropriate permission

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

# mkdir -p /home/ymizuniw/.gnupg
# verify the downloded files
gpg --homedir . --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

# ex output
# 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 as follows:
# pub   rsa2048 2011-08-19 [SC] [expires: 2027-05-24]
#       573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
# uid                      nginx signing key <signing-key@nginx.com>

# to make the apt stable. but this time the OS is bookworm, then leaving this setting as it is is ok.
# echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
# https://nginx.org/packages/debian `lsb_release -cs` nginx" \
#     | tee /etc/apt/sources.list.d/nginx.list

apt update
apt install nginx
