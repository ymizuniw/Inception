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
