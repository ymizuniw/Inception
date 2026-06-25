# Docker CLI Usage

## Build to Run
1. `docker build -t container_image_name .`
2. `docker run --name exec_image_name -dp 8080:80 container_image_name`

## Create a named volume and run a container with it
1. `docker volume create vol_name`
2. `docker run --name exec_image_name -dp 8080:80 -v vol_name:/vol_path_in_container container_image_name`


# Nginx Note
1. Define a document root for each server context.
2. Use root directive in location context only for the service out of the common document root area.


# Docker Compose Volume Design

## ボリューム定義
`volumes:` セクションで以下の2つをローカルドライバーで定義し、ホストの `/home/login/data` 以下に実体を作成する。

```yaml
volumes:
  wordpress-db:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/mariadb

  wordpress-www:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/wordpress
```

## 各サービスへのマウント
- **mariadb** → `wordpress-db` をマウント（データベースファイルを永続化）
- **wordpress** → `wordpress-www` をマウント（WordPress本体のファイルをインストール）
- **nginx** → `wordpress-www` をマウント（wordpressが書き込んだファイルをそのまま配信）

`wordpress-www` は wordpress と nginx の**共有ボリューム**。wordpress が書き込み、nginx が読み取る。

## アーキテクチャの意図
ホスト側のローカルボリュームに WordPress の全情報（DBデータ・コンテンツファイル）を永続化し、
nginx を経由したサーバー・クライアント構造を構成する。コンテナが再起動されてもデータが失われない。


# WordPress + Nginx + MariaDB トラブルシューティング

## 問題1: nginx が 80 番ポートを Listen していない
**原因**: `nginx.conf` に `listen 80;` の記述がない。  
**対処**: `server {}` ブロック内に `listen 80;` を追加する。

## 問題2: `http://ip-address` でアクセスすると Bad Gateway
**原因**: nginx が PHP リクエストを PHP-FPM に正しく転送できていない。

**対処1**: `nginx.conf` の `~ \.php {}` ブロックに以下を追加。
```nginx
fastcgi_pass 127.0.0.1:9000;
```

**対処2**: PHP-FPM が UNIX ソケットで Listen している場合は TCP に切り替える。  
`www.conf` を編集:
```ini
; listen = /run/php8.2-fpm.sock   ← コメントアウトして無効化
listen = 127.0.0.1:9000
```

## 問題3: WordPress 用データベースが存在しない
**手順**:
1. MariaDB をインストールする。
2. root 権限で `wordpress` データベースを作成し、ユーザーとパスワードを設定する。
   ```sql
   CREATE DATABASE wordpress;
   CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'password';
   GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
   FLUSH PRIVILEGES;
   ```
3. `wp-config.php` の DB 接続情報を編集する。
   ```php
   define('DB_NAME',     'wordpress');
   define('DB_USER',     'wpuser');
   define('DB_PASSWORD', 'password');
   define('DB_HOST',     '127.0.0.1');
   ```


## Tacks for mariadb docker compose configuration
- docker compose の設定で/var/lib/mysqlのデータを/home/ymizuniw/data/にマウントする。
- 初期状態ではdocker compose を利用したデータベース設定をする必要があるので、既存のentrypoint.sh を流用・一部改変して環境変数から動的に値を取得し初期データベースを作成する。名前付きボリュームであるmariadb_data:/var/lib/mysqlなどを参照して初期化するか否かを判定するロジックが必要。
- confはCOPYでイメージに焼く。

