# this is for virtual machine pruning the added packages and directories to initialize for server setting test.

sudo rm -rf /var/www/wordpress
# または WordPress を別ディレクトリに置いている場合はそのパスを指定
# sudo rm -rf /var/www/your-wordpress-dir
sudo systemctl stop mariadb
sudo apt purge -y mariadb-server mariadb-client mariadb-common mysql-common
sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql
sudo deluser mysql 2>/dev/null
sudo delgroup mysql 2>/dev/null

sudo systemctl stop nginx
sudo apt purge -y nginx nginx-common nginx-core

sudo apt purge curl gnupg2 ca-certificates lsb-release debian-archive-keyring
# chmod or chgrp to give appropriate permission
sudo rm -rf /etc/nginx /var/log/nginx /var/www/html

sudo apt purge -y php-common php8.2-common php8.2-fpm php-mysql php-cli curl

sudo apt autopurge -y
sudo apt autoclean
