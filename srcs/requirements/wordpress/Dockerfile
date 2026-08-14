FROM debian:bookworm
COPY tools/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*
RUN /usr/local/bin/install_composer.sh && /usr/local/bin/install_php_fpm.sh
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]


