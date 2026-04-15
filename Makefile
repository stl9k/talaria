.PHONY: help init config deploy certs status logs reload restart down clean

help:
	@echo "Available commands:"
	@echo "  make init    - Create .env from example"
	@echo "  make config  - Generate configs from templates"
	@echo "  make deploy  - Deploy all services"
	@echo "  make certs   - Obtain SSL certificates"
	@echo "  make status  - Show containers status"
	@echo "  make logs    - View all service logs"
	@echo "  make reload  - Reload nginx configuration"
	@echo "  make restart - Restart all services"
	@echo "  make down    - Stop all services"
	@echo "  make clean   - Full cleanup (removes data)"

init:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env file, please edit it!"; \
	else \
		echo "ℹ️  .env already exists"; \
	fi

config:
	@echo "🔧 Generating configs from templates..."
	@mkdir -p nginx/stream.conf.d nginx/ssl
	@mkdir -p 3x-ui/db 3x-ui/cert
	@mkdir -p telemt/config certbot/conf certbot/www
	@mkdir -p matrix/data element
	@chmod 777 telemt/config
	@rm -rf matrix/homeserver.yaml element/config.json
	@. ./.env && \
	sed "s|\$${DOMAIN}|$${DOMAIN}|g; s|\$${XUI_PATH}|$${XUI_PATH}|g" nginx/stream.conf.d/map.conf.template > nginx/stream.conf.d/map.conf && \
	sed "s|\$${IP_3XUI}|$${IP_3XUI}|g" nginx/stream.conf.d/upstreams.conf.template > nginx/stream.conf.d/upstreams.conf && \
	sed "s|\$${TELEMT_PORT}|$${TELEMT_PORT}|g; s|\$${TELEMT_SECRET}|$${TELEMT_SECRET}|g; s|\$${DOMAIN}|$${DOMAIN}|g; s|\$${TELEMT_AD_TAG}|$${TELEMT_AD_TAG}|g" telemt/config/telemt.toml.template > telemt/config/telemt.toml && \
	sed "s|\$${DOMAIN}|$${DOMAIN}|g; s|\$${MATRIX_PORT}|$${MATRIX_PORT}|g; s|\$${MATRIX_REGISTRATION_SECRET}|$${MATRIX_REGISTRATION_SECRET}|g; s|\$${IP_MATRIX}|$${IP_MATRIX}|g" matrix/homeserver.yaml.template > matrix/homeserver.yaml && \
	sed "s|\$${DOMAIN}|$${DOMAIN}|g" element/config.json.template > element/config.json
	@chmod 666 telemt/config/telemt.toml
	@echo "✅ Configs generated!"

deploy:
	@chmod +x scripts/*.sh 2>/dev/null || true
	@make config
	@echo "🚀 Starting containers..."
	@docker compose up -d
	@echo "⏳ Waiting for startup..."
	@sleep 5
	@make status
	@echo ""
	@echo "✅ Deployment complete!"
	@echo ""
	@. ./.env && echo "📊 3X-UI Panel: https://$${DOMAIN}/$${XUI_PATH}/"
	@. ./.env && echo "   Login: $${XUI_USERNAME}"
	@. ./.env && echo "   Password: $${XUI_PASSWORD}"
	@echo ""
	@. ./.env && echo "💬 Matrix/Element: https://$${DOMAIN}/"
	@echo ""
	@. ./.env && echo "🔐 MTProto Proxy: $${DOMAIN}:443"
	@. ./.env && echo "   Secret: $${TELEMT_SECRET}"

certs:
	@chmod +x scripts/*.sh 2>/dev/null || true
	@./scripts/init-letsencrypt.sh

status:
	@docker compose ps

logs:
	@docker compose logs -f --tail=50

reload:
	@docker exec nginx-router nginx -s reload
	@echo "✅ Nginx reloaded"

restart:
	@docker compose restart
	@echo "✅ Services restarted"

down:
	@docker compose down

clean:
	@docker compose down -v
	@rm -f nginx/stream.conf.d/*.conf
	@rm -f telemt/config/telemt.toml
	@rm -rf matrix/homeserver.yaml element/config.json
	@rm -rf 3x-ui/db/*
	@rm -rf certbot/conf/*
	@rm -rf matrix/data/*
	@echo "✅ Cleaned up!"