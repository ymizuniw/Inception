1. install and init mariadb
2. install and init wordpress
3. install and init nginx 


- the program version setting is very important
- Notice: two nginx configuration exists: conf.d/ and sites-enabled/
- use nginx -t
- the wordpress configuration is in /var/www/wordpress in this project.
- if failed at wp_setup1.sh and wp_setup2.sh, rm -fr the directory and try again after applying the fix.
- set the .env variables and secrets/files appropriately.

## authority base security
- USER user:group should be set in Dockerfile of each service
- modify the initialize scripts to be compatible with the user setting.

## shell script security
- set -eou pipefail
- introduce environment existance check at the start of Docker entrypoint
- apt autoremove --purge deletes the installed files not only the program.
- env file should have export or shell script should include set -a, source .env set +a

- exec script with sudo results in environement variable reset!

<!-- ymizuniw@192.168.64.10:/home/ymizuniw/tools -->

<!-- alpine:3.23 alpine_1:latest debian:bookworm debian_bookworm:latest docker:latest   hello-world:latest mariadb:11  nginx_test:latest srcs-mariadb:latest  srcs-nginx:latest srcs-wordpress:latest test-mariadb:latest test-nginx:latest wp_test:latest  -->


- the user name 'www-data' is configured by the host OS
- www-data: Some web servers run as www-data. Web content should not be owned by this user, or a compromised web server would be able to rewrite a web site. Data written out by
web servers, including log files, will be owned by www-data.
- https://wiki.debian.org/SystemGroups

- the name of entrypoint.sh in wordpress/tools/, should be docker-entrypoint.sh to be as same notation as mariadb 's.

- the php-fpm configuration file path is written in the php-fpm.conf 's bottom line.


- restart: unless-stopped -> on-failure

- 