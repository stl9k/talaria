#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

source .env

echo "🔐 Initializing Let's Encrypt certificates..."
echo "   Domain: ${DOMAIN}"
echo "   Email: ${LETSENCRYPT_EMAIL}"

# Generate configs
echo "📝 Generating configs..."
make config

# Start nginx for ACME challenge
echo "🚀 Starting nginx for ACME challenge..."
docker compose up -d --no-deps nginx
sleep 5

# Request certificates with timeout
echo "📜 Requesting certificates from Let's Encrypt..."
timeout 120 docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email ${LETSENCRYPT_EMAIL} \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d ${DOMAIN} \
    --non-interactive

if [ $? -eq 0 ]; then
    echo "🔗 Creating symlinks..."
    ln -sf ../certbot/conf/live/${DOMAIN} nginx/ssl/live
    
    echo "📋 Copying certificates for services..."
    cp certbot/conf/live/${DOMAIN}/fullchain.pem 3x-ui/cert/
    cp certbot/conf/live/${DOMAIN}/privkey.pem 3x-ui/cert/
    
    echo ""
    echo "✅ Certificates installed successfully!"
    echo "   Main domain: https://${DOMAIN}"
    echo "   3X-UI panel: https://${DOMAIN}/${XUI_PATH}/"
else
    echo "❌ Certificate request failed or timed out"
    exit 1
fi