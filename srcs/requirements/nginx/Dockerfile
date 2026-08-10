FROM debian:bookworm
COPY tools/ /usr/local/bin/

RUN chmod +x /usr/local/bin/*
RUN "/usr/local/bin/install_nginx.sh"

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443
CMD ["nginx"]

