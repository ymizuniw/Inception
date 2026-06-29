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
│   └── db_root_password.txt
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
| `wp-db` | MariaDB data | `~/data/db` |
| `wp-files` | WordPress static files | `~/data/wordpress` |

Driver: `local` with `bind` option pointing to the host path above.

## Network

Single Docker network: `wp-network`

All three containers are attached to this network.

## Environment Variables

### `srcs/.env` (non-secret values)

- `DOMAIN_NAME` — server domain name mapped to local IP
- `MYSQL_USER` — database username
- Any other non-secret environment variables

### `secrets/` (sensitive values)

- `db_password.txt` — database user password
- `db_root_password.txt` — database root/admin password
- `credentials.txt` — other credentials

Secrets are passed via Docker secrets (file-based, not swarm mode).

## Networking Rules

- Only port **443** (HTTPS) is exposed to the outside.
- nginx handles TLS termination (TLS 1.2 or 1.3).
- nginx communicates with WordPress container internally.
- WordPress communicates with MariaDB internally.
