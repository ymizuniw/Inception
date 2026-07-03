FROM debian:bookworm

RUN apt update && apt install -y mariadb-server mariadb-client && rm -rf /var/lib/apt/lists/*

COPY conf/my.cnf /etc/mysql/my.cnf
COPY tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN mkdir /run/mysqld && chown mysql:mysql /run/mysqld
RUN rm -rf /var/lib/mysql

ENV ADMIN_NAME=ymizuniw
ENV DB_USER=user1

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
