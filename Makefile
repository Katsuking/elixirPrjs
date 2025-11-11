.PHONY: dev

DB := 'postgres'
PHOENIX_API := 'first_phoenix_api'

# 開発サーバー立ち上げ
dev:
	docker compose up -d
	cd ./${PHOENIX_API} && mix phx.server
	@echo "${DB} running..."

