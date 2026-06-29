FROM debian:bookworm
RUN apt update && apt install -y nginx curl && rm -fr /var/lib/apt/lists/*
COPY conf/nginx.test.conf /etc/nginx/nginx.conf
EXPOSE 443
CMD ["nginx"]
