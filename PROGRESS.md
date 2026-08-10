# Progress

## Services

| Service | Dockerfile | Config | Entrypoint | Tested |
|---|---|---|---|---|
| MariaDB | ✅ | ✅ | ✅ | ✅ |
| nginx | ⬜ | ⬜ | ⬜ | ⬜ |
| WordPress + PHP-FPM | ⬜ | ⬜ | ⬜ | ⬜ |

## Infrastructure

| Task | Status |
|---|---|
| docker-compose.yml | ⬜ |
| Volumes (wp_data, wp_www) | ⬜ |
| Network (wp-network) | ⬜ |
| Secrets (docker secrets) | ⬜ |
| srcs/.env | ⬜ |
| Makefile | ⬜ |
| Domain → local IP | ⬜ |
| Port 443 only | ⬜ |

## Notes

- MariaDB: `admin`@localhost, `user1`@% — wordpress DB作成済み
- `.env`に`ADMIN_NAME`/`USER_NAME`（mariadb entrypoint用）と`WP_ADMIN_NAME`/`WP_ADMIN_EMAIL`/`WP_USER_NAME`/`WP_USER_EMAIL`を追加済み。`WP_ADMIN_NAME`は42のルール上「admin」を含んではいけないので注意。
- `secrets/wp_admin_password.txt`, `secrets/wp_user_password.txt`を追加済み（db_password.txt等と同じ方式でdocker secretsとしてマウントする想定、まだdocker-compose.ymlには未反映）。
- TODO: `wordpress/tools/setup.sh`を更新して、wp-cliのインストール（Dockerfileにも追加が必要）と、wp-config.php生成後に`wp core install`（管理者ユーザー作成）+ `wp user create`（一般ユーザー作成、role=subscriber）を実行する処理を追加する必要がある。まだ未実装。
- wp-cliによる初期設定スクリプトを用意する。