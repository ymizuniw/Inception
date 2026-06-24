docker stop nginx_test
docker rm nginx_test
docker build -t nginx_test -f test.Dockerfile
