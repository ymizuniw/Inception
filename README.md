# Inception

## Project Overview

Docker-based infrastructure with three isolated containers, each running on its own Debian Bookworm (or Alpine 3.23 stable) image.

## Services

| Service | Description |
|---|---|
| **nginx** | Reverse proxy. TLS 1.2 or 1.3 only. Port 443 exclusively. |
| **WordPress + PHP-FPM** | WordPress served via PHP-FPM. Same container image. |
| **MariaDB** | Database backend. Two accounts: admin and user. |

## Directory Structure

```
.
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── wordpress/
            ├── .dockerignore
            ├── Dockerfile
            ├── conf/
            └── tools/
```

## Volumes

Two named volumes. Bind mounts are **not** allowed for these.

| Volume | Purpose | Host path |
|---|---|---|
| `wp_data` | MariaDB data | `~/data/db` |
| `wp_www` | WordPress static files | `~/data/wordpress` |

Driver: `local` with `bind` option pointing to the host path above.

## Network

Single Docker network: `wp-network`

All three containers are attached to this network.

## Environment Variables

### `srcs/.env` (non-secret values)

- `DOMAIN_NAME` — server domain name mapped to local IP
- `DB_USER` — WordPress database user, also used as the WordPress DB account name in MariaDB
- `DB_ADMIN_NAME` — MariaDB root-equivalent admin account (local-only)
- `WP_ADMIN_NAME` — WordPress admin account created via `wp-cli`. Per subject rules, the name must not contain "admin", "Admin", "administrator", etc.
- `WP_ADMIN_EMAIL` — WordPress admin account email
- `WP_USER_NAME`, `WP_USER_EMAIL` — second, non-admin WordPress account created via `wp-cli`
- Any other non-secret environment variables

### `secrets/` (sensitive values)

- `db_password.txt` — database user password
- `db_root_password.txt` — database root/admin password
- `wp_admin_password.txt` — WordPress admin account password
- `wp_user_password.txt` — WordPress regular user account password
- `credentials.txt` — other credentials

Secrets are passed via Docker secrets (file-based, not swarm mode).

Password files are not committed with real values in this write-up; each is generated locally with a strong random string, e.g.:

```sh
openssl rand -base64 24 > secrets/wp_admin_password.txt
```

Same approach for `db_password.txt`, `db_root_password.txt`, and `wp_user_password.txt`.

## Networking Rules

- Only port **443** (HTTPS) is exposed to the outside.
- nginx handles TLS termination (TLS 1.2 or 1.3).
- nginx communicates with WordPress container internally.
- WordPress communicates with MariaDB internally.

## Design Choices

### Virtual Machines vs Docker

A VM runs its own kernel and OS on top of a hypervisor (Type 2, e.g. VirtualBox, UTM). The hypervisor allocates CPU, memory, and storage at setup time. Those resources are held by the VM whether it uses them or not.

Docker shares the Linux kernel of the host machine. Containers do not boot their own OS. Instead, each container gets a minimal Linux base image and is isolated using namespaces (PID, network, mount, IPC, user, UTS) and cgroups. Cgroups allocate resources at container start and release them when the container stops.

The result: containers start in seconds, use only the resources they need at runtime, and require no ISO download or OS setup.

The trade-off: containers share the host kernel, so isolation is at the OS level. VMs are isolated at the hardware level via the hypervisor. For this project, OS-level isolation is sufficient.

### Docker Network vs Host Network

Host network mode drops a container straight onto the host's network stack: no isolation, no container-specific DNS name, and if a container is compromised, every interface and port on the host is directly reachable.

This project instead creates a dedicated bridge network (`wp-network`) for the three containers. Each container gets its own network namespace, and can reach the others by service name (e.g. `wordpress`, `mariadb`) instead of an IP address, since Docker provides embedded DNS resolution within the network. A compromised container is confined to that namespace — only explicitly exposed ports are visible outside it — instead of exposing the entire host network stack.

### Docker Volumes vs Bind Mounts

A named volume is a name and a storage path owned and managed by Docker (under its own storage driver), independent of any specific host directory layout. A bind mount instead shares an existing directory on the host machine directly, in real time.

Bind mounts tie the container to the host's filesystem structure, making the setup non-portable to other machines. They also increase the security surface: since the container has direct access to a host directory rather than a Docker-managed, separated volume, a compromised container process can read or write host files outside its own isolation boundary. This is why this project uses named volumes (`wp_data`, `wp_www`) instead of bind mounts.

## Security Considerations

### Environment variables vs Docker secrets

Values passed via `environment:` in `docker-compose.yml` (including those sourced from `.env`) end up as plain process environment variables inside the container. Any code execution inside that container — for example through a WordPress plugin vulnerability or a malicious file upload — can read them back with `printenv`, `getenv()`, or `/proc/self/environ`. Since WordPress needs the database password to connect, a compromised WordPress process could leak the MariaDB password this way, giving an attacker access to the whole database, not just their own account, and enabling credential reuse attacks elsewhere.

This is why passwords (`db_password.txt`, `db_root_password.txt`, `wp_admin_password.txt`, `wp_user_password.txt`, `credentials.txt`) are kept out of `.env` and mounted as files under `secrets/` instead. Docker secrets are exposed to the container as files (typically under `/run/secrets/`), not as environment variables, so they aren't dumped by a simple `printenv` or process-inspection call. The application is expected to read the secret file at startup rather than an env var.

Only `DOMAIN_NAME`, `DB_USER`, account names (`DB_ADMIN_NAME`, `WP_ADMIN_NAME`, `WP_USER_NAME`), emails (`WP_ADMIN_EMAIL`, `WP_USER_EMAIL`), and other non-sensitive values live in `.env`.
