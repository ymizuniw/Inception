FROM debian:bookworm
RUN apt update && apt install -y php-fpm php-mysql php-cli curl && rm -fr /var/lib/apt/lists/*
RUN curl -fsSL https://wordpress.org/latest.tar.gz -o wordpress.tar && tar -xzf wordpress.tar
RUN mkdir -p /var/www/wordpress && mv wordpress/* /var/www/wordpress && rm wordpress.tar
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /usr/local/bin/wp
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/setup.sh"]
