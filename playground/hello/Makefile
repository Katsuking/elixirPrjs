COMPOSE_FILE := ../../docker-compose.yaml

.PHONY: dev docker migrate

docker:
	docker compose -f ${COMPOSE_FILE} up -d

dev: docker
	mix phx.server

migrate: docker
	mix ecto.migrate


