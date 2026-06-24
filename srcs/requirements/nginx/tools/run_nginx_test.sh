docker stop nginx_test_container
docker rm nginx_test_container
docker run --name nginx_test_container -v $(pwd)/conf/nginx.test.conf:/etc/nginx/nginx.conf -v $(pwd)/html:/usr/share/nginx/html:ro -dp 8080:80 nginx_test
