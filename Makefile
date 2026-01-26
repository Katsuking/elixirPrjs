.PHONY: dev

DB := 'postgres'
PHOENIX_API := 'aaaaa'

# 開発サーバー立ち上げ
dev:
	docker compose up -d
	cd ./${PHOENIX_API} && mix phx.server
	@echo "${DB} running..."

