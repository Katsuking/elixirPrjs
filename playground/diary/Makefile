# 引数を受けれるようにする (空でも可 
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)

.PHONY: up
up:
	docker compose up -d

# Stop and remove containers, networks, and volumes
.PHONY: down
down:
	docker compose down

.PHONY: web
web:
	docker compose exec web $(RUN_ARGS)

.PHONY: locale
locale:
	docker compose exec web mix gettext.extract
	docker compose exec web mix gettext.merge priv/gettext
	docker compose exec web mix compile
