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

.PHONY: prod-build
prod-build:
	docker compose --env-file prod/.env.prod -f prod/docker-compose.prod.yml build

.PHONY: prod-up
prod-up:
	docker compose --env-file prod/.env.prod -f prod/docker-compose.prod.yml up -d

.PHONY: prod-down
prod-down:
	docker compose --env-file prod/.env.prod -f prod/docker-compose.prod.yml down

.PHONY: prod-migrate
prod-migrate:
	docker compose --env-file prod/.env.prod -f prod/docker-compose.prod.yml exec web /app/bin/migrate

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
		./ conoha:/var/www/diary
