*This project has been created as part of the 42 curriculum by ymizuniw.*

# Developer Documentation

For the project overview and design rationale, see [`README.md`](README.md). This file covers
setting the project up from a clean checkout, building/running it, day-to-day container/volume
commands, and where data actually lives.

## 1. Prerequisites

- A VM (per subject requirements), or a Linux host with Docker Engine + Docker Compose v2
- `openssl` (generates the self-signed TLS cert; present by default on Debian/macOS)
- `sudo` access (needed for `/etc/hosts` and for `make fclean`, which removes container-owned files)

## 2. Configuration files (must be created locally, never committed)

`.gitignore` blocks `secrets/`, `*.env` (and this repo's own private working notes,
`PROGRESS.md`/`REPORT_*.md`) — none of these exist after a fresh `git clone`. Both `srcs/.env` and
`secrets/*` must be created once, by hand, before the first `make`.

### 2a. `srcs/.env`

Create `srcs/.env` (relative to repo root) with these keys — see
[README's Environment Variables table](README.md#environment-variables) for what each one does:

```sh
cat > srcs/.env <<'EOF'
DOMAIN_NAME=ymizuniw.42.fr
DB_USER=wp_user
WP_HOME=https://ymizuniw.42.fr
WP_ADMIN=lead_dev
WP_ADMIN_EMAIL=admin@ymizuniw.42.fr
WP_USER=second_user
WP_USER_EMAIL=user@ymizuniw.42.fr
EOF
```

Replace the example values with your own. The one hard rule from the subject: `WP_ADMIN` must
**not** contain `admin`/`Admin`/`administrator`/`Administrator` as a substring (`admin`, `Admin123`,
`administrator`, etc. are all disallowed) — `lead_dev` above is just an example that satisfies it.

### 2b. `secrets/`

`srcs/docker-compose.yml`'s top-level `secrets:` block mounts six files from `../secrets/` (i.e.
repo-root `secrets/`) into the containers. All six must exist before `docker compose up`/`build` —
Compose fails immediately with a missing-file error otherwise:

```sh
mkdir -p secrets
openssl rand -base64 24 > secrets/db_password.txt
openssl rand -base64 24 > secrets/db_root_password.txt
openssl rand -base64 24 > secrets/wp_admin_password.txt
openssl rand -base64 24 > secrets/wp_user_password.txt
```

> `db_root_password.txt` is required to exist because it's mounted into the `mariadb` container,
> but at the time of writing the MariaDB entrypoint doesn't yet apply it to the root account
> (root stays on `unix_socket` auth, local-only). Create the file anyway; it's a placeholder for
> that not-yet-wired-up hardening step.

For the TLS certificate/key pair, run the existing helper from repo root:

```sh
bash srcs/requirements/nginx/tools/gen_cert.sh
```

This generates a self-signed cert (`CN=localhost`, RSA 2048, 365 days) and writes
`secrets/server.crt` / `secrets/server.key`. Regenerate it any time the year-long expiry is hit, or
if you want a `CN` matching your actual domain instead of `localhost` (the browser will still warn
either way, since it's self-signed — see [`USER_DOC.md`](USER_DOC.md)).

### 2c. Domain name

The subject requires `<login>.42.fr` to resolve to the VM's own IP. On the VM:

```sh
echo "127.0.0.1 ymizuniw.42.fr" | sudo tee -a /etc/hosts
```

If you're browsing from *outside* the VM (e.g. host-machine browser hitting a VM on a bridged/NAT
network), use the VM's actual IP instead of `127.0.0.1`, and add the `/etc/hosts` entry on whichever
machine's browser you're using. Whatever you choose here must match `DOMAIN_NAME` in `srcs/.env`
(and therefore what ends up in `nginx.conf`'s `server_name`, and in `WP_HOME`).

## 3. Build & launch

Everything goes through the root `Makefile`, which wraps
`docker compose -f srcs/docker-compose.yml` so relative paths inside the compose file (build
contexts, `../secrets/*` references) resolve correctly regardless of your current directory within
the repo:

```sh
make            # == make up: create $HOME/data/{db,wordpress}, then docker compose up --build -d
```

| Target | Effect |
|---|---|
| `make` / `make up` | Ensure `$HOME/data/{db,wordpress}` exist, then `docker compose up --build -d` |
| `make build` | Build images only, don't start containers |
| `make down` | Stop and remove containers (data in `$HOME/data` survives) |
| `make stop` / `make start` | Stop/start existing containers without recreating them |
| `make re` | `down` then `up --build` — rebuild without touching persisted data |
| `make logs` | `docker compose logs -f` (all services) |
| `make ps` | `docker compose ps` |
| `make clean` | `down` + remove images/anonymous volumes/orphan containers |
| `make fclean` | `clean` + `sudo rm -rf $HOME/data` — **destructive**, wipes the WordPress site and database entirely. Only run this deliberately. |

First build takes a while (apt installs, wp-cli download, cert-signing-key fetch for nginx). On
first `up`, the WordPress entrypoint also runs `wp core install` and creates both DB accounts —
watch `make logs` if you want to see that happen.

## 4. Managing containers & volumes

```sh
# container status
docker compose -f srcs/docker-compose.yml ps          # or: make ps

# logs, one service or all
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f      # or: make logs

# shell into a running container
docker compose -f srcs/docker-compose.yml exec wordpress bash
docker compose -f srcs/docker-compose.yml exec mariadb bash

# named volumes
docker volume ls
docker volume inspect wp_data
docker volume inspect wp_www
```

## 5. Where data persists

Both named volumes are backed by host paths under `$HOME/data` (a Docker named volume using a
`bind`-type `driver_opts`, not a plain compose bind mount — see README's
[Docker Volumes vs Bind Mounts](README.md#docker-volumes-vs-bind-mounts) for why that distinction
matters):

| Volume | Host path | Mounted into |
|---|---|---|
| `wp_data` | `$HOME/data/db` | `mariadb`'s `/var/lib/mysql` |
| `wp_www` | `$HOME/data/wordpress` | `wordpress`'s and `nginx`'s `/var/www/wordpress` |

This data outlives `docker compose down` / `make down` and container restarts — MariaDB's
entrypoint only runs `mariadb-install-db` if `/var/lib/mysql/mysql` doesn't already exist, and
WordPress's entrypoint only runs `wp core download`/`wp core install` if the corresponding files
aren't already present, so re-running `make up` after a `make down` reuses the existing site and
database rather than recreating them. Only `make fclean` (or manually removing `$HOME/data`) resets
this state.
