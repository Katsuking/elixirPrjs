.PHONY: dev

DB := 'postgres'

# 開発サーバー立ち上げ
dev:
	cd ../ && docker compose up -d
	@echo "${DB} running..."

