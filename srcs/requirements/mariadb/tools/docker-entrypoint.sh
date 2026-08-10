#!/bin/bash
set -eo pipefail

if [ -d /var/lib/mysql/mysql ]; then
	exec mariadb --user=mysql
fi

mariadb-install-db --datadir=/var/lib/mysql --user=mysql
mariadbd --user=mysql &
MARIADB_PID=$!

DB_USER=${DB_USER}
DB_PASSWORD=$(cat /run/secrets/db_password.txt)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password.txt)

for i in {30..0}; do
	if mariadb << -EOF
		SELECT 1;
		EOF
	then
		break
	fi
	sleep 1
done

if [ $i -eq 0 ]; then
	echo "MariaDB connection failed!" >$2
	exit 1
fi

mariadb << -EOF
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

	
