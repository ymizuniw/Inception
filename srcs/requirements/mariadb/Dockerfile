FROM debian:bookworm
COPY conf/my.cnf /etc/mysql/my.cnf
COPY tools/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*
RUN "/usr/local/bin/install_mariadb.sh"
RUN mkdir /run/mysqld && chown mysql:mysql /run/mysqld
RUN rm -fr /var/lib/mysql
EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
