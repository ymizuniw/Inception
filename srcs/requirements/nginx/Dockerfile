FROM debian:bookworm
COPY tools/* /usr/local/bin
COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template

RUN chmod +x /usr/local/bin/*
RUN "/usr/local/bin/install_nginx.sh"

EXPOSE 443
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
