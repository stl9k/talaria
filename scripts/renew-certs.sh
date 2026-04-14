#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

source .env

echo "🔄 Renewing Let's Encrypt certificates..."

# Copy renewed certificates to services
cp certbot/conf/live/${DOMAIN}/fullchain.pem 3x-ui/cert/
cp certbot/conf/live/${DOMAIN}/privkey.pem 3x-ui/cert/

# Reload nginx
docker exec nginx-router nginx -s reload

# Restart services that use certificates
docker restart 3x-ui telemt

echo "✅ Certificates renewed and services reloaded!"