*This project has been created as part of the 42 curriculum by ymizuniw.*

# User Documentation

This file is for anyone who just wants to run and use the site, without needing to touch the
Dockerfiles or scripts. For build/setup details aimed at developers, see [`DEV_DOC.md`](DEV_DOC.md).

## What services does the stack provide?

Three containers, each running one thing, connected on a private Docker network:

| Container | What it does |
|---|---|
| `nginx` | The only thing reachable from outside — serves the site over HTTPS (port 443, TLS 1.2/1.3 only) and forwards PHP requests to WordPress internally |
| `wordpress_php_fpm` | Runs WordPress itself (PHP-FPM) |
| `mariadb` | The database WordPress stores its content in |

You never talk to `wordpress_php_fpm` or `mariadb` directly — everything goes through `nginx`.

## Starting and stopping the project

From the repository root:

```sh
make          # start (first run also builds the images — can take a few minutes)
make down     # stop and remove the containers
```

If this is the very first run on a fresh checkout, some one-time setup (passwords, the domain
name) has to exist first — see [`DEV_DOC.md`](DEV_DOC.md#2-configuration-files-must-be-created-locally-never-committed).
If that setup is already done, `make`/`make down` is all you need day to day. `make re` rebuilds
without losing your data; `make stop`/`make start` pause/resume without rebuilding.

## Accessing the website and the admin panel

- Website: `https://<login>.42.fr` — for example `https://ymizuniw.42.fr`
- Admin panel: `https://<login>.42.fr/wp-admin`

The domain has to already resolve to the machine running the containers (a one-time `/etc/hosts`
step — see `DEV_DOC.md`). The TLS certificate is self-signed, so your browser **will** show a
"connection is not private" warning the first time — that's expected for a local/VM setup, not a
sign anything is broken. Proceed past the warning (in Chrome: "Advanced" → "Proceed to ... (unsafe)").

## Finding and managing credentials

No password is stored in any file tracked by git. They live as plain files under `secrets/` on the
host machine (created once during setup, see `DEV_DOC.md`) and are handed to each container as a
Docker secret, never as a visible environment variable. To look one up:

```sh
cat secrets/wp_admin_password.txt    # WordPress admin account password
cat secrets/wp_user_password.txt     # second WordPress (author) account password
cat secrets/db_password.txt          # database password (only needed for DB troubleshooting)
```

The corresponding **usernames** (not passwords) are set in `srcs/.env` as `WP_ADMIN` and `WP_USER`.
There are always exactly two WordPress accounts: one administrator and one regular (author) user.

To change a password: stop the containers, overwrite the relevant file in `secrets/` with a new
value, and start again — WordPress won't overwrite an already-installed site's accounts on restart,
so also update the password from inside `wp-admin` (Users → your profile) if you want the running
site's login to match immediately, rather than only the next fresh install.

## Checking that everything is running correctly

```sh
make ps
```

All three containers (`nginx`, `wordpress_php_fpm`, `mariadb`) should show a status of `Up`/
`running`. If one is missing or shows `Restarting`, check its logs:

```sh
make logs                 # all services
# or, to follow just one:
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

If everything is `Up` but the site itself doesn't load, confirm the domain actually resolves
(`ping <login>.42.fr` should return the VM's IP) before assuming a container problem.
