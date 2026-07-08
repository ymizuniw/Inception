FROM debian:bookworm
COPY tools/ /usr/local/bin/
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
RUN chmod +x /usr/local/bin/*
RUN /usr/local/bin/install_php_fpm.sh \
    && /usr/local/bin/wp_create_conf.sh \
    && /usr/local/bin/wp_setup_db.sh
EXPOSE 9000
ENTRYPOINT ["/usr/sbin/php-fpm8.2", "-F"]
