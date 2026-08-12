# Build Guide — Inception from Scratch

Step-by-step instructions to build this project from an empty directory to a
working `make up`. Each step creates one file/decision and explains why it's
needed. Cross-reference `README.md` for the *design rationale* (volumes vs
bind mounts, secrets vs env, etc.) — this document is the *build order*.

Target: three Debian Bookworm–based containers (nginx, WordPress+PHP-FPM,
MariaDB), one bridge network, two named volumes, TLS-only on port 443,
passwords via Docker secrets (file-based, not swarm).

---

## 0. Prerequisites

- Docker Engine + Docker Compose v2 (`docker compose version`).
- A host/VM with a domain resolvable to `127.0.0.1` (The subject requires
  `<login>.42.fr`). Add it to `/etc/hosts` ([name resolution in nginx](https://trac.nginx.org/nginx/ticket/2625)):
  ```sh
  echo "127.0.0.1 ymizuniw.42.fr" | sudo tee -a /etc/hosts
  ```
- `openssl` available on the host (for TLS cert generation).

---

## 1. Directory skeleton

```sh
mkdir -p Inception/secrets
mkdir -p Inception/srcs/requirements/{mariadb,nginx,wordpress}/{conf,tools}
cd Inception
```

Resulting layout (matches `README.md`):

```
.
├── Makefile
├── secrets/
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/{Dockerfile,conf/,tools/}
        ├── nginx/{Dockerfile,conf/,tools/}
        └── wordpress/{Dockerfile,conf/,tools/}
```

## 2. `.gitignore`

Secrets and env files must never be committed.

```
secrets/
*.env
```

## 3. Non-secret environment: `srcs/.env`

```sh
DOMAIN_NAME=ymizuniw.42.fr
WP_HOME=https://ymizuniw.42.fr
WP_SITEURL=https://ymizuniw.42.fr
DB_NAME=wordpress
DB_USER=db_user1
DB_ADMIN=ymizuniw
DB_HOST=mariadb
DB_CHARSET=utf8

WP_ADMIN=ymizuniw
WP_ADMIN_EMAIL=manager@gmail.com
WP_USER=wp_user1
WP_USER_EMAIL=user@gmail.com
```
> [!Note]
> `WP_ADMIN` must **not** contain the substring "admin"/"Admin" — the
subject forbids it in the WordPress admin username. Adjust the value, keep
the variable name.


## 4. Secrets

> Docker Compose provides a way for you to use secrets without having to use environment variables to store information. If you’re injecting passwords and API keys as environment variables, you risk unintentional information exposure. Services can only access secrets when explicitly granted by a secrets attribute within the services top-level element.  
[Manage secrets securely in Docker Compose](https://docs.docker.com/compose/how-tos/use-secrets/)

- Generate random value for passwords by openssl utility ([OpenSSL Documentation -rand](https://docs.openssl.org/1.1.1/man1/rand/)).
```sh
openssl rand -base64 24 > secrets/db_password.txt
openssl rand -base64 24 > secrets/db_root_password.txt
openssl rand -base64 24 > secrets/wp_admin_password.txt
openssl rand -base64 24 > secrets/wp_user_password.txt
```

- TLS certificate/key (self-signed, matches `DOMAIN_NAME`):

```sh
openssl req -x509 -newkey rsa:2048 \
  -keyout secrets/server.key -out secrets/server.crt \
  -days 365 -nodes -subj "/CN=ymizuniw.42.fr"
```
  - req
  - -x509
  - -newkey
  - -keyout
  - -out
  - -days
  - -nodes
  - -subj  

([OpenSSL -req](https://docs.openssl.org/3.6/man1/openssl-req/#options))

## 5. MariaDB image

`srcs/requirements/mariadb/conf/my.cnf`:

```ini
[mariadb]
character-set-server = utf8mb4
collation-server     = utf8mb4_unicode_ci

bind-address = 0.0.0.0
```

> `bind-address = 0.0.0.0` many debian package will set to localhost(127.0.0.1), then the setting should be commented out or overwritten by 0.0.0.0 in mariadb conf.

`srcs/requirements/mariadb/tools/install_mariadb.sh`:

```sh
apt update && apt install mariadb-server mariadb-client -y && rm -rf /var/lib/apt/lists/*
```
> removing the apt cache by ```rm -fr /var/lib/apt/lists/*``` leads to shrink the image size though in Debian apt-get clean is automatically called ([Docker Docs Building best practices](https://docs.docker.com/build/building/best-practices/)).

`srcs/requirements/mariadb/tools/docker-entrypoint.sh`:

```sh
#!/bin/bash

if [ -d /var/lib/mysql/mysql ]; then
  exec mariadbd --user=mysql
fi

mariadb-install-db --datadir=/var/lib/mysql --user=mysql
mariadbd --user=mysql &
MARIADB_PID=$!

DB_USER=${DB_USER}
DB_PASSWORD=$(cat /run/secrets/db_password.txt)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password.txt)

# poll until mariadbd accepts connections
for i in {30..0}; do
  if mariadb <<-EOF
	SELECT 1;
	EOF
    then
      break
  fi
  sleep 1
done

if [ $i -eq 0 ]; then
    echo "MariaDB connection failed!" >&2
    exit 1
fi

mariadb <<-EOF
  CREATE DATABASE wordpress;
  CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
  GRANT ALL PRIVILEGES ON wordpress.* TO '${DB_USER}'@'%';
  DELETE FROM mysql.global_priv WHERE User='';
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
  FLUSH PRIVILEGES;
EOF

kill $MARIADB_PID
wait $MARIADB_PID

exec mariadbd --user=mysql
```

Key points:
- `-d /var/lib/mysql/mysql` check makes bootstrap run only once; on
  container restart with a populated volume, it skips straight to `exec
  mariadbd`().
- The bootstrap `mariadbd` is started in the background, killed after setup,
  then re-`exec`'d in the foreground so PID 1 is the real daemon (correct
  signal handling for `docker stop`).
- `${DB_USER}@'%'` (not `@'localhost'`) because WordPress connects over the
  network, not a Unix socket.

`srcs/requirements/mariadb/Dockerfile`:

```dockerfile
FROM debian:bookworm
COPY conf/my.cnf /etc/mysql/my.cnf
COPY tools/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*
RUN "/usr/local/bin/install_mariadb.sh"
RUN mkdir /run/mysqld && chown mysql:mysql /run/mysqld
RUN rm -fr /var/lib/mysql
EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
```

`rm -fr /var/lib/mysql` clears whatever the apt package pre-seeded, so the
named volume mounted at that path starts genuinely empty and the
first-boot branch in the entrypoint reliably triggers.

## 6. nginx image

`srcs/requirements/nginx/tools/install_nginx.sh` — installs nginx from the
official nginx.org apt repo (imports and verifies their signing key first,
per https://nginx.org/en/linux_packages.html#Debian) rather than the
Debian-bundled package.

`srcs/requirements/nginx/conf/nginx.conf`:

```nginx
daemon off;
events {}
http {
 server {
  listen 443 ssl;
  ssl_certificate /run/secrets/server.crt;
  ssl_certificate_key /run/secrets/server.key;
  ssl_protocols TLSv1.2 TLSv1.3;

  server_name ymizuniw.42.fr;

  root /var/www/wordpress;
  index index.php index.html;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    include fastcgi_params;
    fastcgi_pass wordpress_php_fpm:9000;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_index index.php;
  }
 }
}
```

- `daemon off;` keeps nginx in the foreground as PID 1.
- `ssl_protocols TLSv1.2 TLSv1.3;` — subject requirement, nothing older.
- `fastcgi_pass wordpress_php_fpm:9000` resolves via Docker's embedded DNS
  because `container_name: wordpress_php_fpm` in the compose file is also
  registered as a network alias on `wp_network`.
- No HTTP `server {}` block/redirect — only 443 is ever exposed
  (`ports: ["443:443"]` in compose), matching the "port 443 only" rule.

`srcs/requirements/nginx/Dockerfile`:

```dockerfile
FROM debian:bookworm
COPY tools/ /usr/local/bin/

RUN chmod +x /usr/local/bin/*
RUN "/usr/local/bin/install_nginx.sh"

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443
CMD ["nginx"]
```

`CMD` (not `ENTRYPOINT`) since nginx needs no pre-start setup script — the
cert/key arrive via Docker secrets at `/run/secrets/`, not baked into the
image.

## 7. WordPress + PHP-FPM image

`srcs/requirements/wordpress/tools/install_php_fpm.sh`:

```sh
#!/bin/bash
set -e

apt update && apt install -y php8.2-fpm php-mysql php-cli mariadb-client curl && rm -fr /var/lib/apt/lists/*

curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /usr/local/bin/wp
```

`wp-cli` drives WordPress setup (download, config, `core install`, user
creation) instead of hand-rolled PHP/SQL.

`srcs/requirements/wordpress/conf/www.conf` (PHP-FPM pool):

```ini
[www]
user = www-data
group = www-data

listen = 9000

pm = dynamic
pm.max_children = 5
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

`srcs/requirements/wordpress/tools/wp_create_conf.sh` — downloads WordPress
core into the volume at container start (not build time, since
`/var/www/wordpress` is a named volume and would shadow anything baked into
the image):

```sh
#!/bin/bash
set -e

mkdir -p /var/www/wordpress
cd /var/www/wordpress

if [ ! -f wp-load.php ]; then
  wp core download --path=/var/www/wordpress --allow-root
fi
```

`srcs/requirements/wordpress/tools/wp_setup_db.sh` — generates
`wp-config.php` from the DB secret, waits for MariaDB to accept
connections, then runs the one-time site install and creates both required
accounts:

```sh
#!/bin/bash
set -e

cd "/var/www/wordpress"

if [ ! -f wp-config.php ]; then
 wp config create  --dbhost="$DB_HOST" --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$(cat /run/secrets/db_password.txt)" --allow-root --skip-check
fi

for i in {30..0}
do
  if ! wp db check --allow-root; then
    if [ "$i" -eq 0 ]; then
      exit 1;
    fi
    sleep 1
    continue
  fi
  break
done

if ! wp core is-installed --allow-root; then
  wp core install \
    --url="$WP_HOME" \
    --title="Inception" \
    --admin_user="$WP_ADMIN" \
    --admin_password="$(cat /run/secrets/wp_admin_password.txt)" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root

  wp user create "$WP_USER" "$WP_USER_EMAIL" \
    --role=author \
    --user_pass="$(cat /run/secrets/wp_user_password.txt)" \
    --allow-root
fi
```

`srcs/requirements/wordpress/tools/entrypoint.sh` ties it together and
`exec`s PHP-FPM in the foreground as PID 1:

```sh
#!/bin/bash
set -e

/usr/local/bin/wp_create_conf.sh
/usr/local/bin/wp_setup_db.sh

mkdir -p /run/php

exec /usr/sbin/php-fpm8.2 -F
```

`srcs/requirements/wordpress/Dockerfile`:

```dockerfile
FROM debian:bookworm
COPY tools/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*
RUN /usr/local/bin/install_php_fpm.sh
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

## 8. Compose file: `srcs/docker-compose.yml`

Assemble all three services on one bridge network, two named volumes bound
to host paths under `~/data`, and the six file-based secrets:

```yaml
services:
  mariadb:
    build:
      context: requirements/mariadb
      dockerfile: Dockerfile
    image: mariadb
    container_name: mariadb
    env_file: .env
    secrets:
      - source: db_password
        target: db_password.txt
      - source: db_root_password
        target: db_root_password.txt
    volumes:
      - wp_data:/var/lib/mysql
    networks:
      - wp_network
    restart: unless-stopped

  wordpress:
    build:
      context: requirements/wordpress
      dockerfile: Dockerfile
    image: wordpress
    container_name: wordpress_php_fpm
    env_file: .env
    secrets:
      - source: db_password
        target: db_password.txt
      - source: wp_admin_password
        target: wp_admin_password.txt
      - source: wp_user_password
        target: wp_user_password.txt
    volumes:
      - wp_www:/var/www/wordpress
    networks:
      - wp_network
    depends_on:
      - mariadb
    restart: unless-stopped

  nginx:
    build:
      context: requirements/nginx
      dockerfile: Dockerfile
    image: nginx
    container_name: nginx
    env_file: .env
    secrets:
      - source: server_crt
        target: server.crt
      - source: server_key
        target: server.key
    volumes:
      - wp_www:/var/www/wordpress
    ports:
      - "443:443"
    networks:
      - wp_network
    depends_on:
      - wordpress
    restart: unless-stopped

volumes:
  wp_data:
    name : "wp_data"
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${HOME}/data/db
  wp_www:
    name : "wp_www"
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${HOME}/data/wordpress

networks:
  wp_network:
    driver: bridge

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
  wp_user_password:
    file: ../secrets/wp_user_password.txt
  server_crt:
    file: ../secrets/server.crt
  server_key:
    file: ../secrets/server.key
```

Notes:
- `depends_on` only orders container *start*, not readiness — that's why
  both `docker-entrypoint.sh` (MariaDB) and `wp_setup_db.sh` (WordPress)
  poll rather than assuming the dependency is ready.
- `driver_opts` with `type: none, o: bind` makes these Docker-managed named
  volumes backed by a specific host directory (`~/data/db`,
  `~/data/wordpress`) — satisfies "named volumes required" while still
  landing on a predictable host path for inspection/grading.
- Create the host directories before first `up`: `mkdir -p ~/data/db
  ~/data/wordpress`.

## 9. `Makefile`

```makefile
.PHONY: up down clean fclean

up:
	cd srcs && docker compose up -d

down:
	cd srcs && docker compose down

clean:
	cd srcs && docker compose down -v

fclean: clean
	docker system prune -af
	rm -rf ${HOME}/data/db/* ${HOME}/data/wordpress/*
```

## 10. First build and verification

```sh
mkdir -p ~/data/db ~/data/wordpress
make up
```

Check:

```sh
cd srcs && docker compose ps          # all three "Up"
docker compose logs mariadb            # DB bootstrap, no errors
docker compose logs wordpress_php_fpm  # wp core install succeeded
curl -vk https://ymizuniw.42.fr        # WordPress front page, valid TLS handshake
```

Then from a browser, visit `https://ymizuniw.42.fr` (self-signed cert
warning is expected) and confirm:
- The site loads the WordPress front end.
- `/wp-admin` logs in as `$WP_ADMIN` with `secrets/wp_admin_password.txt`.
- The second account (`$WP_USER`, author role) also logs in.

Teardown:

```sh
make down     # stop + remove containers/network, keep volumes
make clean    # also drop the named volumes
make fclean   # clean + prune all unused images + wipe host data dirs
```

## 11. Common pitfalls (from project notes)

- **Two nginx config locations exist upstream** (`conf.d/` and
  `sites-enabled/`) — this project overwrites `/etc/nginx/nginx.conf`
  directly, so don't leave stray default configs in either directory or
  nginx may load two conflicting `server` blocks. Run `nginx -t` inside the
  container if something looks wrong.
- If `wp_create_conf.sh`/`wp_setup_db.sh` fail partway (e.g. WordPress
  downloaded but DB never came up), the safest recovery is `rm -rf` the
  contents of the `wp_www` volume dir (`~/data/wordpress/*`) and rerun —
  both scripts are idempotent via their `-f wp-load.php` / `-f
  wp-config.php` checks, but a partially-downloaded core can leave them
  stuck.
- Package pinning matters: apt installs `mariadb-server`/`php8.2-fpm`
  unpinned from `debian:bookworm`, so a Dockerfile rebuilt months later may
  pull a newer point release. If a build suddenly breaks, check
  `apt-cache policy` for the package in question before debugging the
  scripts.
- `WP_ADMIN` in `.env` must never contain "admin" (case-insensitive,
  including as a substring) — `wp core install` will otherwise succeed but
  fail the subject's evaluation criteria.
- Scripts exec'd via `sudo` lose the current shell's exported environment —
  don't `sudo bash script.sh` when the script depends on `.env` values;
  source `.env` inside the script or before invoking as the target user.
