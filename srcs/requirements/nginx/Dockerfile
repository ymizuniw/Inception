FROM debian:bookworm
COPY tools/* /usr/local/bin
COPY conf/nginx.conf /etc/nginx/nginx.conf

RUN chmod +x /usr/local/bin/*
RUN "/usr/local/bin/install_nginx.sh"

EXPOSE 443
CMD ["nginx"]
