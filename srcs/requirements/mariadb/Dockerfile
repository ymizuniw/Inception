FROM debian:bookworm
RUN apt update && apt install mariadb-server mariadb-client -y && rm -rf /var/lib/apt/lists/*
COPY conf/my.cnf /etc/mysql/my.cnf
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN mkdir /run/mysqld && chown mysql:mysql /run/mysqld
RUN rm -fr /var/lib/mysql
EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
