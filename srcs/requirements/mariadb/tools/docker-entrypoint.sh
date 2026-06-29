#!/bin/bash

if [ -d /var/lib/mysql/mysql ]; then
  exec mariadbd --user=mysql
fi

mariadb-install-db --datadir=/var/lib/mysql --user=mysql
mariadbd --user=mysql &
MARIADB_PID=$!
ADMIN_PASSWORD=$(cat /run/secrets/db_root_password.txt)
DB_PASSWORD=$(cat /run/secrets/db_password.txt)

for i in {30..0}; do
  if mariadb -uroot -h localhost <<-EOF
	SELECT 1;
	EOF
    then
      break
  fi
  sleep 1
done

if [ $i -eq 0 ]; then
  exit 1
fi

mariadb -uroot -h localhost <<-EOF
  CREATE USER '${ADMIN_NAME}'@'localhost' IDENTIFIED BY '${ADMIN_PASSWORD}';
  GRANT ALL PRIVILEGES ON *.* TO '${ADMIN_NAME}'@'localhost';
  CREATE USER '${USER_NAME}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
  CREATE DATABASE wordpress;
  GRANT ALL PRIVILEGES ON wordpress.* TO '${USER_NAME}'@'%';
  FLUSH PRIVILEGES;
EOF

kill $MARIADB_PID
wait $MARIADB_PID
exec mariadbd --user=mysql
