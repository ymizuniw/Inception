FROM debian:bookworm

RUN apt-get update && apt-get install -y zip unzip wget
RUN wget -P /home/ymizuniw/data/www https://ja.wordpress.org/latest-ja.zip && unzip /home/ymizuniw/data/www/wordpress
RUN chown -R /var/www/html
EXPOSE 80 443
CMD ["/usr/sbin/php-fpm8.3", "-F"]
