# The structure and functionalities of docker-compose.yml

## 1.nginx
- build with Dockerfile in requirements/nginx
- the named volume "wordpress_website_files" is mounted at /var/www/html in the container
- the file requirements/nginx/conf/nginx.conf is bind mounted at /etc/nginx/nginx.conf in the container
- the port 443(SSL) is opend for the access from the hsot port 443
- the docker network name is "wp_network"

## 2.mariadb
- build with Dockerfile in requrements/mariadb
- the named volume "wordpress_data" is mounted at /var/lib/mysql in the container
- the docker network name is "wp_network"
### environment
- the name of the DB is "wordpress"
- the user name is ymizuniw
- the secret file path that contains the root password of the DB is /run/secrets/db_root_password.txt
- the secret file path that contains the user password of the DB is /run/secrets/db_password.txt
### secrets
- the secret names are db_root_password and db_password

## 3.wordpress
- build with Dockerfile in requirements/wordpress
- the named volume "wordpress_website_files" is mounted at /var/www/html in the container (that is shared with nginx container)
- wordpress depends on mariadb (nginx intermidiates, but not depends on or depended on by wordpress or mariadb)
- the docker network name "wp_network"

## secrets definition
- the secret label "db_root_password" is the file located at ../secrets/db_root_password.txt on the host
- the secret label "db_password" is the file located at ../secrets/db_password.txt on the host

## volumes definition
- the named volume "wordpress_website_files" is a local driver created at /home/ymizuniw/data/www
- the named volume "wordpress_data" is a local driver created at /home/ymizuniw/data/db

## network definition
- the docker network "wp_network" is defined

