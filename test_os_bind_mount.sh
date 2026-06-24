docker run -d -it --name test_os -v /var/run/docker.sock:/var/run/docker.sock --mount type=bind,source="$(pwd)",target=/inception alpine_1
