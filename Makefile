.PHONY: up down clean fclean

up:
	cd srcs && docker compose up -d
down:
	cd srcs && docker compose down
clean:
	cd srcs && docker compose down -v
fclean: clean
	docker system prune -af
	rm -fr ${HOME}/data/db/* ${HOME}/data/wordpress/*

