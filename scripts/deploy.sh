#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

source .env

echo "🚀 Deploying infrastructure..."
echo "   Domain: ${DOMAIN}"

# Generate configs
echo ""
echo "1️⃣ Generating configs from templates..."
mkdir -p nginx/stream.conf.d nginx/ssl
mkdir -p 3x-ui/db 3x-ui/cert
mkdir -p telemt/config certbot/conf certbot/www
mkdir -p matrix/data element
chmod 777 telemt/config

envsubst < nginx/stream.conf.d/map.conf.template > nginx/stream.conf.d/map.conf
envsubst < nginx/stream.conf.d/upstreams.conf.template > nginx/stream.conf.d/upstreams.conf
envsubst < telemt/config/telemt.toml.template > telemt/config/telemt.toml
chmod 666 telemt/config/telemt.toml

echo "   ✅ Configs generated"

# Start services
echo ""
echo "2️⃣ Starting containers..."
docker-compose up -d

# Wait for services
echo ""
echo "3️⃣ Waiting for services to start..."
sleep 5

# Check status
echo ""
echo "4️⃣ Service status:"
docker-compose ps

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ Deployment complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 3X-UI Panel: https://${DOMAIN}/xui/"
echo "   Login: ${XUI_USERNAME}"
echo "   Password: ${XUI_PASSWORD}"
echo ""
echo "💬 Matrix/Element: https://${DOMAIN}/"
echo ""
echo "🔐 MTProto Proxy: ${DOMAIN}:443"
echo "   Secret: ${TELEMT_SECRET}"
echo ""
echo "📝 Useful commands:"
echo "   make status  - Check container status"
echo "   make logs    - View logs"
echo "   make reload  - Reload nginx config"
echo "   make down    - Stop all services"
echo "════════════════════════════════════════════════════════════════"