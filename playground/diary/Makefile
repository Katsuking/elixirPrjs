# 引数を受けれるようにする (空でも可 
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)

.PHONY: up
up:
	docker compose --env-file ../../.env up -d

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

# --- Production Environment Command Targets ---

# Production Compose Command Base
PROD_COMPOSE := docker compose --env-file prod/.env.prod -f prod/docker-compose.prod.yml

.PHONY: prod-build
prod-build:
	$(PROD_COMPOSE) build

.PHONY: prod-up
prod-up:
	$(PROD_COMPOSE) up -d

.PHONY: prod-down
prod-down:
	$(PROD_COMPOSE) down

.PHONY: prod-exec
prod-exec:
	$(PROD_COMPOSE) exec web $(RUN_ARGS)

.PHONY: prod-migrate
prod-migrate:
	$(PROD_COMPOSE) run --rm web /app/bin/migrate

.PHONY: prod-test-s3
prod-test-s3:
	$(PROD_COMPOSE) exec web /app/bin/diary eval "$$(cat app/test_s3_upload.exs)"

.PHONY: prod-logs
prod-logs:
	docker compose --env-file prod/.env.prod -f prod/docker-compose.prod.yml logs -f

# Deploy to production server using rsync with automatic .gitignore filtering
.PHONY: deploy
deploy:
	rsync -avz --delete \
		--filter=':- app/.gitignore' \
		--exclude='*.md' \
		--exclude='.geminiignore' \
		--exclude='app/_build/' \
		--exclude='app/deps/' \
		--exclude='app/.elixir_ls/' \
		--exclude='app/assets/node_modules/' \
		--exclude='app/timer_live_output.html' \
		--exclude='.git/' \
		--exclude='.envrc' \
		--exclude='livebook_data/' \
		--exclude='prod/ssl/' \
		--exclude='prod/.env.prod' \
		./ conoha:/var/www/diary
