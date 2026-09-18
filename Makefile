COMPOSE_FILE	= srcs/docker-compose.yml
COMPOSE			= docker compose -f $(COMPOSE_FILE)
DATA_DIR		= $(HOME)/data

.PHONY: all data up build down stop start re logs ps clean fclean

all: up

data:
	mkdir -p $(DATA_DIR)/db $(DATA_DIR)/wordpress

up: data
	$(COMPOSE) up --build -d

build: data
	$(COMPOSE) build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

re: down up

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean: down
	$(COMPOSE) down --rmi all --volumes --remove-orphans

fclean: clean
	sudo rm -rf $(DATA_DIR)
