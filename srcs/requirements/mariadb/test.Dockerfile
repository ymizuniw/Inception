FROM debian:bookworm

RUN apt update && apt install -y mariadb-server mariadb-client

ENV MARIADB_DATABASE=test_db
ENV MARIADB_USER=user
ENV MARIADB_PASSWORD=user 
ENV MARIADB_ROOT_PASSWORD=root

EXPOSE 3306

