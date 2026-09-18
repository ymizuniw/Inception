*This project has been created as part of the 42 curriculum by ymizuniw.*

# Inception

## Description

Inception is a system administration project: build a small, self-hosted web stack — NGINX,
WordPress with PHP-FPM, and MariaDB — entirely with Docker, inside a virtual machine, using
hand-written Dockerfiles (no pulling pre-built images from Docker Hub) and Docker Compose to wire
the three services together. The goal isn't WordPress itself; it's the infrastructure around it:
one service per container, TLS termination at the edge, persistent named volumes, secrets kept out
of both the image and the environment, and containers that self-heal on crash.

## Services

| Service | Description |
|---|---|
| **nginx** | Sole entrypoint. TLS 1.2/1.3 only, port 443 only. Reverse-proxies PHP requests to WordPress over the internal network. |
| **wordpress** | WordPress + PHP-FPM only (no web server in this container). Provisioned at container *startup*, not at image build time, so it can reach MariaDB and read Docker secrets. |
| **mariadb** | The WordPress database, in its own container. |

## Instructions

### Prerequisites

- A VM (per subject requirements) or Linux host with Docker Engine + Docker Compose v2
- `openssl` (for the self-signed TLS cert)

### First-time setup

Two things must exist locally before anything will build — neither is committed to git
(`.gitignore`: `secrets/`, `*.env`). Full step-by-step instructions, including exact filenames and
variable names, are in **[`DEV_DOC.md`](DEV_DOC.md)**:

1. Create `srcs/.env` with the non-secret configuration (domain name, account names/emails).
2. Create `secrets/*.txt` (passwords) and `secrets/server.crt`/`server.key` (TLS cert).
3. Point `<login>.42.fr` at the VM's IP (`/etc/hosts`).

### Build & run

```sh
make          # creates $HOME/data/{db,wordpress}, then docker compose up --build -d
```

See **[`DEV_DOC.md`](DEV_DOC.md)** for the rest of the Makefile targets (`down`, `re`, `logs`,
`clean`, `fclean`, ...) and **[`USER_DOC.md`](USER_DOC.md)** for how to use the running site once
it's up.

## Directory Structure

```
.
├── Makefile
├── secrets/                          # gitignored — created locally, see DEV_DOC.md
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   ├── wp_user_password.txt
│   ├── server.crt
│   └── server.key
└── srcs/
    ├── .env                         # gitignored — created locally, see DEV_DOC.md
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/my.cnf
        │   └── tools/
        │       ├── docker-entrypoint.sh
        │       └── install_mariadb.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf.template
        │   └── tools/
        │       ├── docker-entrypoint.sh    # envsubst $DOMAIN_NAME, then exec nginx
        │       ├── gen_cert.sh             # generates secrets/server.crt + server.key
        │       └── install_nginx.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/www.conf
            └── tools/
                ├── docker-entrypoint.sh    # wp-cli setup + DB wait, then exec php-fpm
                └── install_php_fpm.sh
```

## Volumes

Two named volumes. Bind mounts are **not** used for these.

| Volume | Purpose | Host path | Mounted in |
|---|---|---|---|
| `wp_data` | MariaDB data files | `$HOME/data/db` | `mariadb` (`/var/lib/mysql`) |
| `wp_www` | WordPress code + uploads | `$HOME/data/wordpress` | `wordpress` and `nginx` (`/var/www/wordpress`) |

Both are declared as Docker named volumes (`driver: local`) using a `bind`-type `driver_opts` to
pin their storage under `$HOME/data` — see [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
below for why this differs from a plain compose bind mount.

## Network

Single Docker bridge network: `wp-network`. All three containers attach to it and reach each other
by service name (`mariadb`, `wordpress`, `nginx`) via Docker's embedded DNS. Only `nginx` publishes
a port to the host (`443:443`); `mariadb` and `wordpress` are reachable only from inside the network.

## Environment Variables

### `srcs/.env` (non-secret)

| Variable | Used by | Meaning |
|---|---|---|
| `DOMAIN_NAME` | nginx | Server domain, e.g. `ymizuniw.42.fr` — substituted into `nginx.conf` at container start |
| `DB_USER` | mariadb, wordpress | WordPress's MariaDB account name |
| `WP_HOME` | wordpress | Site URL passed to `wp core install --url`, e.g. `https://ymizuniw.42.fr` |
| `WP_ADMIN` | wordpress | WordPress admin username. Per subject rules, must **not** contain `admin`/`Admin`/`administrator`/`Administrator` |
| `WP_ADMIN_EMAIL` | wordpress | Admin account email |
| `WP_USER` | wordpress | Second, non-admin WordPress account (author role) |
| `WP_USER_EMAIL` | wordpress | That account's email |

### `secrets/` (sensitive — Docker secrets, file-based)

| File | Consumed by | Contains |
|---|---|---|
| `db_password.txt` | mariadb, wordpress | `DB_USER`'s database password |
| `db_root_password.txt` | mariadb (mounted; see [DEV_DOC.md](DEV_DOC.md) for current status) | MariaDB root-equivalent password |
| `wp_admin_password.txt` | wordpress | WordPress admin account password |
| `wp_user_password.txt` | wordpress | Second WordPress account's password |
| `server.crt` / `server.key` | nginx | Self-signed TLS certificate/key pair |

Secrets are mounted into containers as files under `/run/secrets/`, read by each entrypoint script
at startup — never passed as environment variables. See exact creation commands in
[`DEV_DOC.md`](DEV_DOC.md).

## Design Choices

### Virtual Machines vs Docker

A VM runs its own kernel and OS on top of a hypervisor (Type 2, e.g. VirtualBox, UTM). The
hypervisor allocates CPU, memory, and storage at setup time. Those resources are held by the VM
whether it uses them or not.

Docker shares the Linux kernel of the host machine. Containers do not boot their own OS. Instead,
each container gets a minimal Linux base image and is isolated using namespaces (PID, network,
mount, IPC, user, UTS) and cgroups. Cgroups allocate resources at container start and release them
when the container stops.

The result: containers start in seconds, use only the resources they need at runtime, and require
no ISO download or OS setup.

The trade-off: containers share the host kernel, so isolation is at the OS level. VMs are isolated
at the hardware level via the hypervisor. For this project, OS-level isolation is sufficient — the
subject additionally requires running the whole thing *inside* a VM anyway, layering both.

### Secrets vs Environment Variables

Values passed via `environment:` in `docker-compose.yml` (including anything sourced from `.env`)
end up as plain process environment variables inside the container. Any code execution inside that
container — for example through a WordPress plugin vulnerability or a malicious file upload — can
read them back with `printenv`, `getenv()`, or `/proc/self/environ`. Since WordPress needs the
database password to connect, a compromised WordPress process could leak the MariaDB password this
way, giving an attacker access to the whole database, not just its own account, and enabling
credential reuse attacks elsewhere.

This is why passwords (`db_password.txt`, `db_root_password.txt`, `wp_admin_password.txt`,
`wp_user_password.txt`) are kept out of `.env` and mounted as files under `secrets/` instead.
Docker secrets are exposed to the container as files (typically under `/run/secrets/`), not as
environment variables, so they aren't dumped by a simple `printenv` or process-inspection call.
Each entrypoint script reads the secret file at startup rather than an env var.

Only `DOMAIN_NAME`, account names (`DB_USER`, `WP_ADMIN`, `WP_USER`), emails
(`WP_ADMIN_EMAIL`, `WP_USER_EMAIL`), and the site URL (`WP_HOME`) — none of them sensitive on their
own — live in `.env`.

### Docker Network vs Host Network

Host network mode drops a container straight onto the host's network stack: no isolation, no
container-specific DNS name, and if a container is compromised, every interface and port on the
host is directly reachable.

This project instead creates a dedicated bridge network (`wp-network`) for the three containers.
Each container gets its own network namespace, and can reach the others by service name (e.g.
`wordpress`, `mariadb`) instead of an IP address, since Docker provides embedded DNS resolution
within the network. A compromised container is confined to that namespace — only explicitly exposed
ports are visible outside it — instead of exposing the entire host network stack.

### Docker Volumes vs Bind Mounts

A named volume is a name and a storage path owned and managed by Docker (under its own storage
driver), independent of any specific host directory layout. A bind mount instead shares an existing
directory on the host machine directly, in real time.

Bind mounts tie the container to the host's filesystem structure, making the setup non-portable to
other machines. They also increase the security surface: since the container has direct access to a
host directory rather than a Docker-managed, separated volume, a compromised container process can
read or write host files outside its own isolation boundary. This is why this project uses named
volumes (`wp_data`, `wp_www`) instead of a plain compose bind mount — even though, underneath,
their `driver_opts` still point at a host path (`$HOME/data/...`), because the subject also
requires that exact host location. The difference is that Docker still owns and tracks them as
named volumes (`docker volume ls`/`inspect` see them), rather than the container having an
unmediated bind into an arbitrary host path.

## Resources

- 42 subject: *Inception* — the project brief this README implements (internal 42 curriculum document, no public URL)
- [NGINX documentation](https://nginx.org/en/docs/) — config syntax, `ssl_protocols`, `fastcgi_pass`
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/) — `secrets:`, `volumes:`, `driver_opts`
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/) — file-based secret mounting model
- [WP-CLI](https://wp-cli.org/) — `wp core install`, `wp config create`, `wp user create`
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/) — `mariadb-install-db`, user/privilege grants
- [GNU gettext — `envsubst`](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html) — template substitution used by the nginx entrypoint
- [`nginx/docker-nginx`](https://github.com/nginx/docker-nginx) — official image's `envsubst`-on-templates pattern, used as the model for this project's own nginx entrypoint
- [nginx Trac #1785](https://trac.nginx.org/nginx/ticket/1785) — confirms nginx core has no native env-var interpolation in config files, which is why the entrypoint-side `envsubst` step exists at all

### AI usage

Claude Code (Anthropic) was used throughout development for: diagnosing and fixing the nginx
TLS/`server_name` configuration and the `$DOMAIN_NAME`-substitution mechanism; diagnosing and fixing
a WordPress provisioning bug where database setup was running at Docker *build* time (when secrets
and inter-container networking aren't available yet) instead of at container *start*; fixing several
shell-script bugs (apt package-list ordering, a missing `-y`, a wrong secret filename, an ambiguous
DB-readiness poll); writing the root `Makefile`; and drafting this documentation set (`README.md`,
`USER_DOC.md`, `DEV_DOC.md`). All AI-suggested changes were reviewed before being kept.
