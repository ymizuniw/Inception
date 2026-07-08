#!/bin/bash

if [ -d /var/lib/mysql/mysql ]; then
  exec mariadbd --user=mysql
fi

mariadb-install-db --datadir=/var/lib/mysql --user=mysql
mariadbd --user=mysql &
MARIADB_PID=$!

DB_USER=${DB_USER}
DB_PASSWORD=$(cat /run/secrets/db_password.txt)

# polling for mariadb connection
for i in {30..0}; do
  if mariadb <<-EOF
	SELECT 1;
	EOF
    then
      break
  fi
  sleep 1
done

# if the "i" in the pooling count is 0, then all the request failed.
if [ $i -eq 0 ]; then
    echo "MariaDB connection failed!" >&2
    exit 1
fi

mariadb <<-EOF
  CREATE DATABASE wordpress;
  CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
  GRANT ALL PRIVILEGES ON wordpress.* TO '${DB_USER}'@'%';
  FLUSH PRIVILEGES;
EOF

# terminate the mariadb process started for the setup above, and wait for the PID is terminated.
kill $MARIADB_PID
wait $MARIADB_PID

# exec mariadb daemon with executing user mysql(default)
exec mariadbd --user=mysql
