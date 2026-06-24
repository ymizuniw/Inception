docker stop test-mariadb-container
docker rm test-mariadb-container
docker run -d --network test-network -v /home/ymizuniw/test_data/db:/var/lib/mysql --name test-mariadb-container test-mariadb
