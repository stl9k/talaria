#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

source .env

echo "🔐 Initializing Let's Encrypt certificates..."
echo "   Domain: ${DOMAIN}"
echo "   Email: ${LETSENCRYPT_EMAIL}"

# Create required directories
mkdir -p certbot/conf certbot/www nginx/ssl

# Start nginx for ACME challenge
echo "🚀 Starting nginx for ACME challenge..."
docker compose up -d nginx
sleep 5

# Request certificates
echo "📜 Requesting certificates from Let's Encrypt..."
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email ${LETSENCRYPT_EMAIL} \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d ${DOMAIN}

# Create symlink for nginx
echo "🔗 Creating symlinks..."
ln -sf ../certbot/conf/live/${DOMAIN} nginx/ssl/live

# Copy certificates for 3X-UI and Telemt
echo "📋 Copying certificates for services..."
cp certbot/conf/live/${DOMAIN}/fullchain.pem 3x-ui/cert/
cp certbot/conf/live/${DOMAIN}/privkey.pem 3x-ui/cert/

# Restart services to apply certificates
echo "🔄 Restarting services..."
docker compose restart nginx xui telemt

echo ""
echo "✅ Certificates installed successfully!"
echo "   Main domain: https://${DOMAIN}"
echo "   3X-UI panel: https://${DOMAIN}/${XUI_PATH}/"