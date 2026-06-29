FROM debian:bookworm
RUN apt update && apt install -y php-fpm php-mysql && rm -fr /var/lib/apt/lists/*
RUN curl -fsSL https://wordpress.org/latest.tar.gz -o wordpress.tar && tar -xzf wordpress.tar
RUN mkdir -p /var/www/wordpress && mv wordpress/* /var/www/wordpress
COPY tools/setup.sh /usr/local/bin/setup.sh
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/setup.sh"]
