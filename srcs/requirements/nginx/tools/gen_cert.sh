#!/bin/bash
openssl req -x509 -newkey rsa:2048 -keyout secrets/server.key -out secrets/server.crt -days 365 -nodes -subj "/CN=localhost"
