docker network create test-network
docker stop test-mariadb
docker rm test-mariadb
docker build -t test-mariadb -f test.Dockerfile .

