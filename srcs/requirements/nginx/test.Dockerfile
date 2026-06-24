# from debian:bookworm base, install nginx and openssl.
# generate a self-signed TLS cert with openssl.
# write nginx.conf : listen on 443, serve static files, proxy PHP to WordPress.
# EXPOSE 443 and run "nginx -g "daemon off;""

FROM alpine:3.23

RUN apk update && apk add --no-cache nginx

EXPOSE 80 443
# TODO: switch to 443 with TLS once certs are added

CMD ["nginx", "-g", "daemon off;"]

